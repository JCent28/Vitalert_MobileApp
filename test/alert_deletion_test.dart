import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/screens/alerts_screen.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alert Deletion - FirebaseRealtimeService & AppState', () {
    late FirebaseRealtimeService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FirebaseRealtimeService();
    });

    test('deleteAcknowledgedAlerts fetches alerts and patches nulls for only acknowledged alerts', () async {
      Map<String, dynamic>? patchedBody;
      String? patchedPath;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path == '/alerts.json' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'alert_1': {
                'patient_id': 'p1',
                'status': 'Active',
                'severity': 'Critical',
                'message': 'Critical SpO2',
              },
              'alert_2': {
                'patient_id': 'p1',
                'status': 'Acknowledged',
                'severity': 'Warning',
                'message': 'Elevated HR',
              },
              'alert_3': {
                'patient_id': 'p2',
                'status': 'Acknowledged',
                'severity': 'Critical',
                'message': 'Desaturation',
              },
            }),
            200,
          );
        }

        if (path == '/alerts.json' && method == 'PATCH') {
          patchedPath = path;
          patchedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(patchedBody), 200);
        }

        return http.Response('{}', 200);
      });

      final success = await service.deleteAcknowledgedAlerts(client: mockClient);

      expect(success, isTrue);
      expect(patchedPath, equals('/alerts.json'));
      expect(patchedBody, isNotNull);

      // Only acknowledged alerts (alert_2 and alert_3) are deleted
      expect(patchedBody!.containsKey('alert_2'), isTrue);
      expect(patchedBody!['alert_2'], isNull);
      expect(patchedBody!.containsKey('alert_3'), isTrue);
      expect(patchedBody!['alert_3'], isNull);

      // Active alert (alert_1) is NOT deleted
      expect(patchedBody!.containsKey('alert_1'), isFalse);
    });

    test('deleteAcknowledgedAlerts with clearEntireTable=true sends DELETE request to /alerts.json', () async {
      String? deletedPath;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/alerts.json' && request.method == 'DELETE') {
          deletedPath = request.url.path;
          return http.Response('null', 200);
        }
        return http.Response('{}', 200);
      });

      final success = await service.deleteAcknowledgedAlerts(
        clearEntireTable: true,
        client: mockClient,
      );

      expect(success, isTrue);
      expect(deletedPath, equals('/alerts.json'));
    });

    test('deleteAcknowledgedAlerts returns true when no acknowledged alerts exist', () async {
      bool patchCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/alerts.json' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'alert_1': {
                'patient_id': 'p1',
                'status': 'Active',
                'severity': 'Critical',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/alerts.json' && request.method == 'PATCH') {
          patchCalled = true;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 200);
      });

      final success = await service.deleteAcknowledgedAlerts(client: mockClient);

      expect(success, isTrue);
      expect(patchCalled, isFalse);
    });

    test('AppState.deleteAcknowledgedAlerts removes acknowledged alerts optimistically and rolls back on failure', () async {
      final appState = AppState();

      // Seed alerts into AppState
      final activeAlert = AlertItem(
        id: 'a1',
        patientId: 'p1',
        patientName: 'John',
        chairLocation: '1',
        wardArea: 'Station 1',
        severity: AlertSeverity.critical,
        title: 'Critical',
        message: 'High HR',
        timeString: '10:00',
        isAcknowledged: false,
      );
      final ackAlert = AlertItem(
        id: 'a2',
        patientId: 'p1',
        patientName: 'John',
        chairLocation: '1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'Warning',
        message: 'Low SpO2',
        timeString: '09:30',
        isAcknowledged: true,
      );

      appState.alerts.clear();
      appState.alerts.addAll([activeAlert, ackAlert]);

      expect(appState.acknowledgedAlerts.length, equals(1));
      expect(appState.activeAlerts.length, equals(1));

      // Test Failure with Rollback
      final failClient = MockClient((request) async {
        if (request.url.path == '/alerts.json' && request.method == 'GET') {
          return http.Response('{"a2": {"status": "Acknowledged"}}', 200);
        }
        if (request.url.path == '/alerts.json' && request.method == 'PATCH') {
          return http.Response('Error', 500);
        }
        return http.Response('{}', 200);
      });

      final failResult = await appState.deleteAcknowledgedAlerts(client: failClient);
      expect(failResult, isFalse);
      // Rollback verified: acknowledged alert is restored
      expect(appState.acknowledgedAlerts.length, equals(1));
      expect(appState.lastAlertError, isNotNull);

      // Test Success
      final successClient = MockClient((request) async {
        if (request.url.path == '/alerts.json' && request.method == 'GET') {
          return http.Response('{"a2": {"status": "Acknowledged"}}', 200);
        }
        if (request.url.path == '/alerts.json' && request.method == 'PATCH') {
          return http.Response('{"a2": null}', 200);
        }
        return http.Response('{}', 200);
      });

      final successResult = await appState.deleteAcknowledgedAlerts(client: successClient);
      expect(successResult, isTrue);
      // Acknowledged alert is permanently cleared from state
      expect(appState.acknowledgedAlerts.isEmpty, isTrue);
      // Active alert is still present
      expect(appState.activeAlerts.length, equals(1));

      appState.dispose();
    });
  });

  group('AlertsScreen UI - Delete Acknowledged Button Widget Tests', () {
    testWidgets('renders Delete Acknowledged button on Acknowledged tab and triggers dialog', (tester) async {
      final appState = AppState();
      final ackAlert = AlertItem(
        id: 'ack_1',
        patientId: 'p1',
        patientName: 'Jane Doe',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'Warning',
        message: 'SpO2 low',
        timeString: '11:00',
        isAcknowledged: true,
      );

      appState.alerts.clear();
      appState.alerts.add(ackAlert);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertsScreen(
              state: appState,
              onPatientSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "Delete Acknowledged" button
      final deleteBtn = find.byKey(const Key('delete_all_acknowledged_btn'));
      expect(deleteBtn, findsOneWidget);
      expect(find.text('Delete Acknowledged'), findsOneWidget);

      // Tap the delete button to open the confirmation dialog
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Delete Acknowledged?'), findsOneWidget);
      expect(find.text('Delete All'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Delete Acknowledged?'), findsNothing);
      expect(appState.acknowledgedAlerts.length, equals(1));

      appState.dispose();
    });
  });
}

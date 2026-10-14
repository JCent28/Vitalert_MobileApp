import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/models/patient.dart';
import 'package:vitalert/models/user_model.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M8 (P1) Alert Acknowledgement - History Sync, Staff ID & Role Check', () {
    late FirebaseRealtimeService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FirebaseRealtimeService();
    });

    test('acknowledgeAlert patches both alerts/{id} and history/{patient}/{session}/alerts/{id} with acknowledged_by_id', () async {
      Map<String, dynamic>? alertPatched;
      Map<String, dynamic>? historyAlertPatched;
      String? alertPatchPath;
      String? historyPatchPath;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path.startsWith('/alerts/') && path.endsWith('/alert_101.json') && method == 'PATCH') {
          alertPatchPath = path;
          alertPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(alertPatched), 200);
        }

        if (path.startsWith('/history/') && path.contains('/alerts/alert_101.json') && method == 'PATCH') {
          historyPatchPath = path;
          historyAlertPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(historyAlertPatched), 200);
        }

        return http.Response('{}', 200);
      });

      final result = await service.acknowledgeAlert(
        alertId: 'alert_101',
        nurseName: 'Rosa M.',
        nurseId: 'EMP-001',
        userRole: 'Staff Nurse',
        patientId: 'patient_1',
        session: '2',
        time: '14:32',
        note: 'Patient stabilized',
        client: mockClient,
      );

      expect(result, isTrue);

      // 1. Verify alerts/{id} patch
      expect(alertPatchPath, equals('/alerts/alert_101.json'));
      expect(alertPatched, isNotNull);
      expect(alertPatched!['status'], equals('Acknowledged'));
      expect(alertPatched!['acknowledged_by'], equals('Rosa M.'));
      expect(alertPatched!['acknowledged_by_id'], equals('EMP-001'));
      expect(alertPatched!['acknowledged_at'], equals('14:32'));
      expect(alertPatched!['note'], equals('Patient stabilized'));

      // 2. Verify history/{patient}/{session}/alerts/{id} patch
      expect(historyPatchPath, equals('/history/patient_1/session_2/alerts/alert_101.json'));
      expect(historyAlertPatched, isNotNull);
      expect(historyAlertPatched!['status'], equals('Acknowledged'));
      expect(historyAlertPatched!['acknowledged_by'], equals('Rosa M.'));
      expect(historyAlertPatched!['acknowledged_by_id'], equals('EMP-001'));
      expect(historyAlertPatched!['acknowledged_at'], equals('14:32'));
      expect(historyAlertPatched!['note'], equals('Patient stabilized'));
    });

    test('acknowledgeAlert blocks Admin role from acknowledging alerts', () async {
      bool anyPatchMade = false;

      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH') {
          anyPatchMade = true;
        }
        return http.Response('{}', 200);
      });

      final result = await service.acknowledgeAlert(
        alertId: 'alert_102',
        nurseName: 'Admin User',
        nurseId: 'ADM-999',
        userRole: 'Admin',
        patientId: 'patient_1',
        session: '1',
        time: '15:00',
        client: mockClient,
      );

      expect(result, isFalse);
      expect(anyPatchMade, isFalse);
      expect(service.lastAlertError, contains('Admin accounts cannot acknowledge'));
    });

    test('acknowledgeAlert resolves patientId and session from alert and patient nodes if omitted', () async {
      Map<String, dynamic>? alertPatched;
      Map<String, dynamic>? historyAlertPatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path == '/alerts/alert_auto.json' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'patient_id': 'patient_auto_42',
              'message': 'High HR',
              'severity': 'Critical',
              'status': 'Active',
            }),
            200,
          );
        }

        if (path == '/patients/patient_auto_42.json' && method == 'GET') {
          return http.Response(
            jsonEncode({
              'name': 'Auto Patient',
              'session': '3',
            }),
            200,
          );
        }

        if (path == '/alerts/alert_auto.json' && method == 'PATCH') {
          alertPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(request.body, 200);
        }

        if (path.startsWith('/history/') && path.contains('/alerts/alert_auto.json') && method == 'PATCH') {
          historyAlertPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(historyAlertPatched), 200);
        }

        return http.Response('{}', 200);
      });

      final result = await service.acknowledgeAlert(
        alertId: 'alert_auto',
        nurseName: 'Clark Kent',
        nurseId: 'HN-00312',
        userRole: 'Head Nurse',
        client: mockClient,
      );

      expect(result, isTrue);
      expect(alertPatched, isNotNull);
      expect(historyAlertPatched, isNotNull);
      expect(historyAlertPatched!['status'], equals('Acknowledged'));
      expect(historyAlertPatched!['acknowledged_by_id'], equals('HN-00312'));
    });

    test('AppState.acknowledgeAlert enforces role check and rejects Admin user', () async {
      final appState = AppState();

      // Configure Admin user in app state
      appState.setCurrentUserForTesting(UserModel(
        staffId: 'ADM-01',
        name: 'Super Admin',
        role: 'Admin',
        status: 'Active',
      ));

      // Add active alert
      final alert = AlertItem(
        id: 'alert_admin_test',
        patientId: 'patient_1',
        patientName: 'Test Patient',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'WARNING',
        message: 'Heart rate elevated',
        timeString: '10:00',
      );
      appState.alerts.add(alert);

      // Verify UserModel.canAcknowledgeAlerts
      expect(appState.currentUser!.isAdmin, isTrue);
      expect(appState.currentUser!.canAcknowledgeAlerts, isFalse);

      final mockClient = MockClient((request) async => http.Response('{}', 200));

      // Attempt acknowledge as Admin via AppState
      final appBlocked = await appState.acknowledgeAlert(
        'alert_admin_test',
        client: mockClient,
      );

      expect(appBlocked, isFalse);
      expect(appState.lastAlertError, contains('Admin accounts cannot acknowledge'));
      expect(appState.alerts.first.isAcknowledged, isFalse);

      // Also test with custom admin role directly on service
      final serviceBlocked = await service.acknowledgeAlert(
        alertId: 'alert_admin_test',
        nurseName: 'Super Admin',
        nurseId: 'ADM-01',
        userRole: 'Admin',
        client: mockClient,
      );

      expect(serviceBlocked, isFalse);
      expect(service.lastAlertError, contains('Admin accounts cannot acknowledge'));
    });

    test('AppState.acknowledgeAlert updates local AlertItem with nurse name, time, and staffId', () async {
      final appState = AppState();
      appState.setCurrentUserForTesting(UserModel(
        staffId: 'SN-042',
        name: 'Rosa M.',
        role: 'Staff Nurse',
        status: 'Active',
      ));

      final mockClient = MockClient((request) async => http.Response('{}', 200));

      final alert = AlertItem(
        id: 'alert_nurse_test',
        patientId: 'patient_1',
        patientName: 'Test Patient',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'WARNING',
        message: 'Heart rate elevated',
        timeString: '10:00',
      );
      appState.alerts.add(alert);

      const patient = Patient(
        id: 'patient_1',
        name: 'Test Patient',
        mrn: 'MRN001',
        initials: 'TP',
        chair: 'Chair 1',
        department: 'Nephrology',
        session: 'Session 2',
        deviceId: 'dev_1',
        date: '2026-10-13',
        startTime: '08:00',
        primaryNurse: 'Rosa M.',
        duration: '2h',
        sessionStatus: 'Ongoing',
        status: AlertSeverity.info,
        currentHr: 75,
        currentSpO2: 98,
        hrHistory: [],
        spO2History: [],
        recentReadings: [],
        alertEvents: [],
      );
      appState.patients.add(patient);

      final success = await appState.acknowledgeAlert(
        'alert_nurse_test',
        note: 'Checked vitals',
        client: mockClient,
      );

      expect(success, isTrue);
      final ackAlert = appState.alerts.firstWhere((a) => a.id == 'alert_nurse_test');
      expect(ackAlert.isAcknowledged, isTrue);
      expect(ackAlert.acknowledgedBy, equals('Rosa M.'));
      expect(ackAlert.acknowledgedById, equals('SN-042'));
      expect(ackAlert.note, equals('Checked vitals'));
    });
  });
}

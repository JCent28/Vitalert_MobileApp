import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/models/patient.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M7 (P1) Session End - final_vitals, device clearing, and zeroing device values', () {
    late FirebaseRealtimeService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FirebaseRealtimeService();
    });

    test('endSession writes final_vitals, clears patient device to N/A, and zeroes device BPM and SpO2', () async {
      Map<String, dynamic>? patientPatched;
      Map<String, dynamic>? devicePatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        // 1. Patient GET
        if (path.endsWith('/patients/patient_101.json') && method == 'GET') {
          return http.Response(
            jsonEncode({
              'name': 'John Doe',
              'chair': 'Chair 1',
              'status': 'Ongoing',
              'device': 'dev_alpha',
              'bpm': 75,
              'spo2': 98,
            }),
            200,
          );
        }

        // 2. Device GET (live telemetry before ending session)
        if (path.endsWith('/devices/dev_alpha.json') && method == 'GET') {
          return http.Response(
            jsonEncode({
              'device_id': 'dev_alpha',
              'status': 'IN_USE',
              'bpm': 78,
              'spo2': 99,
              'last_updated': '2026-10-13 14:00:00',
            }),
            200,
          );
        }

        // 3. Patient PATCH
        if (path.endsWith('/patients/patient_101.json') && method == 'PATCH') {
          patientPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(patientPatched), 200);
        }

        // 4. Device PATCH
        if (path.endsWith('/devices/dev_alpha.json') && method == 'PATCH') {
          devicePatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(devicePatched), 200);
        }

        return http.Response('{}', 200);
      });

      final result = await service.endSession(
        patientId: 'patient_101',
        deviceId: 'dev_alpha',
        client: mockClient,
      );

      expect(result, isTrue);

      // Verify Patient PATCH
      expect(patientPatched, isNotNull);
      expect(patientPatched!['status'], equals('Completed'));
      expect(patientPatched!['device'], equals('N/A'));
      expect(patientPatched!['last_updated'], isNotEmpty);

      // Verify final_vitals structure and evaluated clinical status
      expect(patientPatched!['final_vitals'], isA<Map<String, dynamic>>());
      final finalVitals = patientPatched!['final_vitals'] as Map<String, dynamic>;
      expect(finalVitals['bpm'], equals(78));
      expect(finalVitals['spo2'], equals(99));
      expect(finalVitals['status'], equals('Normal'));
      expect(finalVitals['last_updated'], isNotEmpty);

      // Verify Device PATCH (status AVAILABLE, BPM zeroed, SpO2 zeroed)
      expect(devicePatched, isNotNull);
      expect(devicePatched!['status'], equals('AVAILABLE'));
      expect(devicePatched!['bpm'], equals(0));
      expect(devicePatched!['spo2'], equals(0));
      expect(devicePatched!['last_updated'], isNotEmpty);
    });

    test('endSession evaluates Critical status in final_vitals for severe vital signs', () async {
      Map<String, dynamic>? patientPatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path.endsWith('/patients/patient_crit.json') && method == 'GET') {
          return http.Response(
            jsonEncode({
              'name': 'Critical Patient',
              'chair': 'Chair 3',
              'status': 'Ongoing',
              'device': 'dev_crit',
              'bpm': 130,
              'spo2': 85,
            }),
            200,
          );
        }

        if (path.endsWith('/devices/dev_crit.json') && method == 'GET') {
          return http.Response(
            jsonEncode({
              'device_id': 'dev_crit',
              'status': 'IN_USE',
              'bpm': 135,
              'spo2': 84,
            }),
            200,
          );
        }

        if (path.endsWith('/patients/patient_crit.json') && method == 'PATCH') {
          patientPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(patientPatched), 200);
        }

        if (path.endsWith('/devices/dev_crit.json') && method == 'PATCH') {
          return http.Response('{}', 200);
        }

        return http.Response('{}', 200);
      });

      final result = await service.endSession(
        patientId: 'patient_crit',
        deviceId: 'dev_crit',
        client: mockClient,
      );

      expect(result, isTrue);
      expect(patientPatched, isNotNull);
      final finalVitals = patientPatched!['final_vitals'] as Map<String, dynamic>;
      expect(finalVitals['bpm'], equals(135));
      expect(finalVitals['spo2'], equals(84));
      expect(finalVitals['status'], equals('Critical'));
    });

    test('endSession discovers device from patient record if deviceId argument is N/A', () async {
      Map<String, dynamic>? devicePatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path.endsWith('/patients/patient_stored.json') && method == 'GET') {
          return http.Response(
            jsonEncode({
              'name': 'Stored Patient',
              'chair': 'Chair 2',
              'status': 'Ongoing',
              'device': 'dev_from_record',
              'bpm': 80,
              'spo2': 97,
            }),
            200,
          );
        }

        if (path.endsWith('/devices/dev_from_record.json') && method == 'GET') {
          return http.Response(
            jsonEncode({
              'bpm': 82,
              'spo2': 97,
            }),
            200,
          );
        }

        if (path.endsWith('/patients/patient_stored.json') && method == 'PATCH') {
          return http.Response('{}', 200);
        }

        if (path.endsWith('/devices/dev_from_record.json') && method == 'PATCH') {
          devicePatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(devicePatched), 200);
        }

        return http.Response('{}', 200);
      });

      final result = await service.endSession(
        patientId: 'patient_stored',
        deviceId: 'N/A', // caller passes N/A or empty
        client: mockClient,
      );

      expect(result, isTrue);
      expect(devicePatched, isNotNull);
      expect(devicePatched!['status'], equals('AVAILABLE'));
      expect(devicePatched!['bpm'], equals(0));
      expect(devicePatched!['spo2'], equals(0));
    });

    test('AppState.endSession updates local patient state and device model upon success', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final appState = AppState();
      // Setup patient in app state
      const patient = Patient(
        id: 'patient_app_test',
        name: 'App State Patient',
        mrn: 'MRN001',
        initials: 'AP',
        chair: 'Chair 1',
        department: 'Nephrology',
        session: 'Session 1',
        deviceId: 'dev_local',
        date: '2026-10-13',
        startTime: '08:00',
        primaryNurse: 'Nurse Ratched',
        duration: '2h',
        sessionStatus: 'Ongoing',
        status: AlertSeverity.info,
        currentHr: 72,
        currentSpO2: 98,
        hrHistory: [],
        spO2History: [],
        recentReadings: [],
        alertEvents: [],
      );

      appState.patients.add(patient);

      // Verify initial state
      expect(appState.patients.first.sessionStatus, equals('Ongoing'));
      expect(appState.patients.first.deviceId, equals('dev_local'));

      final success = await appState.endSession(
        patientId: 'patient_app_test',
        deviceId: 'dev_local',
        client: mockClient,
      );

      expect(success, isTrue);
      // Verify local patient updated
      final updatedPatient = appState.patients.firstWhere((p) => p.id == 'patient_app_test');
      expect(updatedPatient.sessionStatus, equals('Completed'));
      expect(updatedPatient.deviceId, equals('N/A'));
    });

    test('deletePatient frees device by setting status to AVAILABLE and zeroing BPM and SpO2', () async {
      Map<String, dynamic>? devicePatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path.endsWith('/patients/patient_delete.json') && method == 'DELETE') {
          return http.Response('null', 200);
        }

        if (path.endsWith('/devices/dev_del.json') && method == 'PATCH') {
          devicePatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(devicePatched), 200);
        }

        return http.Response('{}', 200);
      });

      final result = await service.deletePatient(
        'patient_delete',
        deviceId: 'dev_del',
        client: mockClient,
      );

      expect(result, isTrue);
      expect(devicePatched, isNotNull);
      expect(devicePatched!['status'], equals('AVAILABLE'));
      expect(devicePatched!['bpm'], equals(0));
      expect(devicePatched!['spo2'], equals(0));
    });
  });
}

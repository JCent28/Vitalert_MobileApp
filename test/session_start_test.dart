import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';

void main() {
  group('FirebaseRealtimeService.normalizeChair', () {
    test('normalizes chair strings accurately', () {
      expect(FirebaseRealtimeService.normalizeChair('Chair 1'), equals('1'));
      expect(FirebaseRealtimeService.normalizeChair('chair 1'), equals('1'));
      expect(FirebaseRealtimeService.normalizeChair('1'), equals('1'));
      expect(FirebaseRealtimeService.normalizeChair('Chair 2'), equals('2'));
      expect(FirebaseRealtimeService.normalizeChair('N/A'), equals(''));
      expect(FirebaseRealtimeService.normalizeChair('None'), equals(''));
      expect(FirebaseRealtimeService.normalizeChair('Unknown'), equals(''));
      expect(FirebaseRealtimeService.normalizeChair(''), equals(''));
    });
  });

  group('M6 (P1) Session Start Availability & Meta Verification', () {
    late FirebaseRealtimeService service;

    setUp(() {
      service = FirebaseRealtimeService();
    });

    test('startSession rejects when the chair is occupied by another ongoing patient', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/patients.json')) {
          return http.Response(
            jsonEncode({
              'patient_1': {
                'name': 'Existing Patient',
                'chair': 'Chair 1',
                'status': 'Ongoing',
                'device': 'device1',
              },
              'patient_2': {
                'name': 'New Patient',
                'chair': '1',
                'status': 'Completed',
                'device': 'N/A',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final result = await service.startSession(
        patientId: 'patient_2',
        sessionNum: '2',
        deviceId: 'device2',
        client: mockClient,
      );

      expect(result, isFalse);
      expect(service.lastSessionError, contains('Chair 1 is occupied by Existing Patient'));
    });

    test('startSession succeeds when previous patient in chair is completed', () async {
      Map<String, dynamic>? metaWritten;
      Map<String, dynamic>? patientPatched;
      Map<String, dynamic>? devicePatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/patients.json') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'patient_1': {
                'name': 'Past Patient',
                'chair': 'Chair 1',
                'status': 'Completed',
                'device': 'N/A',
              },
              'patient_2': {
                'name': 'New Patient',
                'chair': 'Chair 1',
                'status': 'Waiting',
                'device': 'N/A',
              },
            }),
            200,
          );
        }
        if (path.endsWith('/devices/device2.json') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'device_id': 'device2',
              'status': 'AVAILABLE',
            }),
            200,
          );
        }
        if (path.contains('/history/patient_2/session_2/meta.json') && request.method == 'PUT') {
          metaWritten = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        if (path.endsWith('/patients/patient_2.json') && request.method == 'PATCH') {
          patientPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        if (path.endsWith('/devices/device2.json') && request.method == 'PATCH') {
          devicePatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 200);
      });

      final result = await service.startSession(
        patientId: 'patient_2',
        sessionNum: '2',
        deviceId: 'device2',
        client: mockClient,
      );

      expect(result, isTrue);
      expect(service.lastSessionError, isNull);

      // Verify status written as Ongoing (NOT Waiting)
      expect(patientPatched, isNotNull);
      expect(patientPatched!['status'], equals('Ongoing'));
      expect(patientPatched!['snapshot_interval'], equals(1));
      expect(patientPatched!['stream_interval'], equals(1));
      expect(patientPatched!['session'], equals('2'));
      expect(patientPatched!['device'], equals('device2'));

      // Verify meta node structure
      expect(metaWritten, isNotNull);
      expect(metaWritten!['interval_minutes'], equals(1));
      expect(metaWritten!['stream_interval'], equals(1));
      expect(metaWritten!['source_type'], equals('actual'));
      expect(metaWritten!['mode'], equals('random'));
      expect(metaWritten!['active_seconds'], equals(0));
      expect(metaWritten!['started_at'], isNotNull);

      // Verify device updated to IN_USE
      expect(devicePatched, isNotNull);
      expect(devicePatched!['status'], equals('IN_USE'));
    });

    test('startSession records source_type as simulation when device is N/A', () async {
      Map<String, dynamic>? metaWritten;
      Map<String, dynamic>? patientPatched;

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/patients.json') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'patient_1': {
                'name': 'Patient 1',
                'chair': 'Chair 3',
                'status': 'Waiting',
                'device': 'N/A',
              },
            }),
            200,
          );
        }
        if (path.contains('/history/patient_1/session_1/meta.json') && request.method == 'PUT') {
          metaWritten = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        if (path.endsWith('/patients/patient_1.json') && request.method == 'PATCH') {
          patientPatched = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        return http.Response('{}', 200);
      });

      final result = await service.startSession(
        patientId: 'patient_1',
        sessionNum: '1',
        deviceId: 'N/A',
        client: mockClient,
      );

      expect(result, isTrue);
      expect(patientPatched!['status'], equals('Ongoing'));
      expect(metaWritten!['source_type'], equals('simulation'));
      expect(metaWritten!['interval_minutes'], equals(1));
    });

    test('startSession rejects when the assigned device is IN_USE in devices node', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/patients.json')) {
          return http.Response(
            jsonEncode({
              'patient_1': {
                'name': 'Patient 1',
                'chair': 'Chair 1',
                'status': 'Waiting',
                'device': 'N/A',
              },
            }),
            200,
          );
        }
        if (path.endsWith('/devices/device1.json')) {
          return http.Response(
            jsonEncode({
              'device_id': 'device1',
              'status': 'IN_USE',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final result = await service.startSession(
        patientId: 'patient_1',
        sessionNum: '1',
        deviceId: 'device1',
        client: mockClient,
      );

      expect(result, isFalse);
      expect(service.lastSessionError, contains('Device device1 is currently in use'));
    });

    test('startSession rejects when device is in use by another ongoing patient', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/patients.json')) {
          return http.Response(
            jsonEncode({
              'patient_1': {
                'name': 'Active Patient',
                'chair': 'Chair 1',
                'status': 'Ongoing',
                'device': 'device2',
              },
              'patient_2': {
                'name': 'Waiting Patient',
                'chair': 'Chair 2',
                'status': 'Waiting',
                'device': 'N/A',
              },
            }),
            200,
          );
        }
        if (path.endsWith('/devices/device2.json')) {
          return http.Response(
            jsonEncode({
              'device_id': 'device2',
              'status': 'AVAILABLE', // even if device node said AVAILABLE, patient node says ongoing
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final result = await service.startSession(
        patientId: 'patient_2',
        sessionNum: '1',
        deviceId: 'device2',
        client: mockClient,
      );

      expect(result, isFalse);
      expect(service.lastSessionError, contains('Device device2 is already assigned to Active Patient'));
    });
  });

  group('M6 Session History Parsing with Meta Node', () {
    test('extracts startTime, duration, and date from meta node when readings are empty', () {
      final service = FirebaseRealtimeService();
      final historyMap = {
        'patient_1': {
          'session_1': {
            'meta': {
              'started_at': '2026-10-12 14:30:00',
              'interval_minutes': 1,
              'stream_interval': 1,
              'source_type': 'actual',
              'mode': 'random',
              'active_seconds': 120, // 2 minutes
            },
            'readings': {},
          },
        },
      };

      final patientsMap = {
        'patient_1': {
          'name': 'Test Patient',
          'chair': 'Chair 1',
          'session': '1',
          'status': 'Ongoing',
          'device': 'device1',
        },
      };

      final patients = service.parsePatientsForTesting(
        patientsMap: patientsMap,
        devicesMap: {},
        alertsList: [],
        historyMap: historyMap,
      );

      expect(patients.length, equals(1));
      final p = patients.first;
      expect(p.sessionStatus, equals('Ongoing'));
      expect(p.sessionHistories.length, equals(1));

      final sh = p.sessionHistories.first;
      expect(sh.startTime, equals('14:30'));
      expect(sh.duration, equals('2m'));
      expect(sh.date, equals('Oct 12, 2026'));
      expect(p.duration, equals('2m'));
    });
  });
}

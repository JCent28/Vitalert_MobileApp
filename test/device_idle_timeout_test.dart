import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/models/patient.dart';
import 'package:vitalert/models/user_model.dart';
import 'package:vitalert/screens/patient_log_screen.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Device Inactivity & Idle Detection Logic', () {
    late FirebaseRealtimeService service;

    setUp(() {
      service = FirebaseRealtimeService();
      service.clearDeviceTrackersForTesting();
    });

    test('Patient with active telemetry is parsed as Ongoing when within 1 minute', () {
      final patientsRaw = {
        'p1': {
          'name': 'Fuellas',
          'chair': 'Chair 3',
          'session': 'Session 2',
          'status': 'Ongoing',
          'device': 'device3',
          'start_time': '18:11',
        }
      };
      final devicesRaw = {
        'device3': {
          'bpm': 78,
          'spo2': 97,
          'last_updated': '18:12:00',
        }
      };

      final patients = service.parsePatientsForTesting(
        patientsMap: patientsRaw,
        devicesMap: devicesRaw,
        alertsList: [],
        historyMap: {},
      );

      expect(patients.length, equals(1));
      final p = patients.first;
      expect(p.name, equals('Fuellas'));
      expect(p.sessionStatus, equals('Ongoing'));
      expect(p.isDeviceIdle, isFalse);
      expect(p.isWaitingIdle, isFalse);
    });

    test('Patient transitions to Waiting (Idle) when no reading changes for at least 1 minute', () {
      final patientsRaw = {
        'p1': {
          'name': 'Fuellas',
          'chair': 'Chair 3',
          'session': 'Session 2',
          'status': 'Ongoing',
          'device': 'device3',
          'start_time': '18:11',
        }
      };
      final devicesRaw = {
        'device3': {
          'bpm': 78,
          'spo2': 97,
          'last_updated': '18:12:00',
        }
      };

      // 1. Initial parse
      service.parsePatientsForTesting(
        patientsMap: patientsRaw,
        devicesMap: devicesRaw,
        alertsList: [],
        historyMap: {},
      );

      // 2. Simulate > 1 minute idle period matching the readings
      service.simulateDeviceIdleForTesting(
        'p1',
        idleDuration: const Duration(seconds: 70),
        lastReceivedTime: '18:12:24',
        lastBpm: 78,
        lastSpO2: 97,
        deviceUpdated: '18:12:00',
      );

      // 3. Second parse with no vitals or timestamp changes
      final idlePatients = service.parsePatientsForTesting(
        patientsMap: patientsRaw,
        devicesMap: devicesRaw,
        alertsList: [],
        historyMap: {},
      );

      expect(idlePatients.length, equals(1));
      final idleP = idlePatients.first;
      expect(idleP.isDeviceIdle, isTrue);
      expect(idleP.sessionStatus, equals('Waiting'));
      expect(idleP.isWaitingIdle, isTrue);
      expect(idleP.lastReceivedTimestamp, equals('18:12:24'));
      expect(idleP.idleTimeAgoText, equals('1m ago'));
    });

    test('Patient auto-recovers to Ongoing when active telemetry resumes', () {
      final patientsRaw = {
        'p1': {
          'name': 'Fuellas',
          'chair': 'Chair 3',
          'session': 'Session 2',
          'status': 'Waiting',
          'device': 'device3',
          'start_time': '18:11',
        }
      };
      final devicesRaw = {
        'device3': {
          'bpm': 78,
          'spo2': 97,
          'last_updated': '18:12:24',
        }
      };

      // Set to idle
      service.simulateDeviceIdleForTesting(
        'p1',
        idleDuration: const Duration(seconds: 75),
        lastReceivedTime: '18:12:24',
      );

      // New readings arrived! BPM changed from 78 to 82, timestamp updated
      final updatedDevicesRaw = {
        'device3': {
          'bpm': 82,
          'spo2': 98,
          'last_updated': '18:14:00',
        }
      };

      final recovered = service.parsePatientsForTesting(
        patientsMap: patientsRaw,
        devicesMap: updatedDevicesRaw,
        alertsList: [],
        historyMap: {},
      );

      expect(recovered.length, equals(1));
      final recP = recovered.first;
      expect(recP.isDeviceIdle, isFalse);
      expect(recP.sessionStatus, equals('Ongoing'));
      expect(recP.isWaitingIdle, isFalse);
    });

    test('Explicit is_idle flag from database sets isDeviceIdle and Waiting status', () {
      final patientsRaw = {
        'p_idle': {
          'name': 'Fuellas',
          'chair': 'Chair 3',
          'session': 'Session 2',
          'status': 'Waiting',
          'is_idle': true,
          'device': 'device3',
          'last_received': '18:12:24',
        }
      };

      final patients = service.parsePatientsForTesting(
        patientsMap: patientsRaw,
        devicesMap: {},
        alertsList: [],
        historyMap: {},
      );

      expect(patients.length, equals(1));
      final p = patients.first;
      expect(p.isDeviceIdle, isTrue);
      expect(p.sessionStatus, equals('Waiting'));
      expect(p.lastReceivedTimestamp, equals('18:12:24'));
    });
  });

  group('Patient Log Screen Device Idle Warning UI Test', () {
    testWidgets('Renders WAITING (IDLE) badge and Device Idle Warning Banner with CHECK DEVICE', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(
        UserModel(
          staffId: 'N-001',
          name: 'Nurse Rosa',
          role: 'Staff Nurse',
          status: 'Active',
        ),
      );

      final idlePatient = Patient(
        id: 'patient_fuellas',
        name: 'Fuellas',
        mrn: '#000003',
        initials: 'F',
        chair: '3',
        department: 'NephroAsia Dialysis Bay',
        session: 'Session 2',
        deviceId: 'device3',
        date: 'Oct 28, 2026',
        startTime: '18:11',
        primaryNurse: 'Nurse Rosa',
        duration: '1m',
        sessionStatus: 'Waiting',
        status: AlertSeverity.info,
        currentHr: 72,
        currentSpO2: 98,
        hrHistory: const [72],
        spO2History: const [98],
        recentReadings: const [],
        alertEvents: const [],
        isDeviceIdle: true,
        lastReceivedTimestamp: '18:12:24',
        lastReceivedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      appState.patients.clear();
      appState.patients.add(idlePatient);
      appState.setSelectedPatientId('patient_fuellas');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientLogScreen(
              state: appState,
              onPatientSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Patient Name and WAITING (IDLE) status pill
      expect(find.text('Fuellas'), findsOneWidget);
      expect(find.text('WAITING (IDLE)'), findsOneWidget);

      // Verify Change Patient button is present
      expect(find.text('Change Patient'), findsOneWidget);

      // Verify Device Idle / No Signal Warning Banner
      expect(find.text('Device Idle / No Signal — Please check the device'), findsOneWidget);
      expect(find.textContaining('No active reading changes from device3 for at least 1 minute'), findsOneWidget);
      expect(find.textContaining('Last received: 18:12:24'), findsOneWidget);

      // Verify IDLE — CHECK DEVICE badge
      expect(find.text('IDLE — CHECK DEVICE'), findsOneWidget);

      appState.dispose();
    });
  });
}

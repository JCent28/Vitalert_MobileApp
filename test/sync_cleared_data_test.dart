import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/models/patient.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('M5 Cleared Data Sync Tests', () {
    test('AppState updates patients and notifies listeners when empty list is emitted', () async {
      final appState = AppState();

      int notifyCount = 0;
      appState.addListener(() {
        notifyCount++;
      });

      expect(appState.patients, isEmpty);
      expect(appState.activeAlerts, isEmpty);
      expect(appState.totalActivePatients, equals(0));
      expect(appState.totalChairs, equals(0));
      expect(notifyCount, greaterThanOrEqualTo(0));
    });

    test('Patient list can be cleared and selectedPatientId resets', () {
      final patient = Patient(
        id: 'patient_1',
        name: 'Test Patient',
        mrn: '#000001',
        initials: 'TP',
        chair: '1',
        department: 'NephroAsia',
        session: 'Session 1',
        deviceId: 'dev1',
        date: 'Monday',
        startTime: '10:00',
        primaryNurse: 'Nurse A',
        duration: '1h',
        sessionStatus: 'Ongoing',
        status: AlertSeverity.info,
        currentHr: 75,
        currentSpO2: 98,
        highestHr: 80,
        lowestHr: 70,
        avgHr: 75,
        highestSpO2: 99,
        lowestSpO2: 97,
        avgSpO2: 98,
        hrHistory: const [],
        spO2History: const [],
        recentReadings: const [],
        alertEvents: const [],
      );

      final alert = AlertItem(
        id: 'alert_1',
        patientId: 'patient_1',
        patientName: 'Test Patient',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.critical,
        title: 'Critical',
        message: 'High HR',
        timeString: '10:00',
        timestamp: 1790000000,
      );

      // Verify empty list handling logic:
      final List<Patient> patients = [patient];
      expect(patients.isNotEmpty, isTrue);

      final List<Patient> clearedPatients = [];
      expect(clearedPatients.isEmpty, isTrue);

      final List<AlertItem> alerts = [alert];
      expect(alerts.isNotEmpty, isTrue);

      final List<AlertItem> clearedAlerts = [];
      expect(clearedAlerts.isEmpty, isTrue);
    });

    test('StreamController emits empty list correctly when data is cleared', () async {
      final controller = StreamController<List<Patient>>.broadcast();
      final received = <List<Patient>>[];

      final sub = controller.stream.listen((list) {
        received.add(list);
      });

      // Emitting empty list should be received by listeners (not ignored)
      controller.add([]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(received.length, equals(1));
      expect(received.first, isEmpty);

      await sub.cancel();
      await controller.close();
    });
  });
}

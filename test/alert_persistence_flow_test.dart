import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/models/patient.dart';
import 'package:vitalert/models/user_model.dart';
import 'package:vitalert/screens/alerts_screen.dart';
import 'package:vitalert/screens/patient_log_screen.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alert Persistence Flow — 7-Step Check & 15s Wait', () {
    late FirebaseRealtimeService service;

    setUp(() {
      service = FirebaseRealtimeService();
      service.clearDeviceTrackersForTesting();
      service.clearPersistenceTrackersForTesting();
    });

    test('Step 1: Zero readings (BPM == 0 or SpO2 == 0) are ignored without changing timer or counters', () {
      final t0 = DateTime(2026, 10, 31, 10, 0, 0);

      // Start with a Warning reading to start the 15s timer
      final firstBad = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 112,
        spO2: 96,
        now: t0,
      );
      expect(firstBad.badSince, equals(t0));
      expect(firstBad.goodReadingsCount, equals(0));

      // Finger lifted (BPM = 0, SpO2 = 0) at +5s -> should ignore and keep badSince == t0
      final zeroReading = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 0,
        spO2: 0,
        now: t0.add(const Duration(seconds: 5)),
      );
      expect(zeroReading.badSince, equals(t0));
      expect(zeroReading.newlyTriggeredAlert, isFalse);
      expect(zeroReading.sessionAlertCount, equals(0));
    });

    test('Steps 2–5: Warning reading waits 15 seconds before opening alert and increments counter by +1', () {
      final t0 = DateTime(2026, 10, 31, 10, 0, 0);

      // t = 0s: First Warning reading (BPM 112) -> starts 15s wait
      final r0 = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 112,
        spO2: 97,
        now: t0,
      );
      expect(r0.badSince, equals(t0));
      expect(r0.newlyTriggeredAlert, isFalse);
      expect(r0.sessionAlertCount, equals(0));

      // t = 10s: Still Warning -> 10s < 15s, no alert yet
      final r10 = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 114,
        spO2: 97,
        now: t0.add(const Duration(seconds: 10)),
      );
      expect(r10.newlyTriggeredAlert, isFalse);
      expect(r10.sessionAlertCount, equals(0));

      // t = 15s: Reaches 15s -> opens Warning alert and increments counter to 1
      final r15 = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 115,
        spO2: 97,
        now: t0.add(const Duration(seconds: 15)),
      );
      expect(r15.newlyTriggeredAlert, isTrue);
      expect(r15.triggeredSeverity, equals(AlertSeverity.warning));
      expect(r15.sessionAlertCount, equals(1));
    });

    test('Step 4 & 5: Warning worsening to Critical keeps the same 15s timer; open Warning upgrades immediately to Critical', () {
      final t0 = DateTime(2026, 10, 31, 10, 0, 0);

      // Scenario A: Warning at 0s, Critical at 10s -> opens at 15s (same timer!)
      service.evaluatePatientReadingPersistence(
        patientId: 'pA',
        bpm: 112,
        spO2: 96,
        now: t0,
      );
      final r10 = service.evaluatePatientReadingPersistence(
        patientId: 'pA',
        bpm: 135, // Critical
        spO2: 88,
        now: t0.add(const Duration(seconds: 10)),
      );
      expect(r10.badSince, equals(t0));
      expect(r10.newlyTriggeredAlert, isFalse);

      final r15 = service.evaluatePatientReadingPersistence(
        patientId: 'pA',
        bpm: 135,
        spO2: 88,
        now: t0.add(const Duration(seconds: 15)),
      );
      expect(r15.newlyTriggeredAlert, isTrue);
      expect(r15.triggeredSeverity, equals(AlertSeverity.critical));
      expect(r15.sessionAlertCount, equals(1));

      // Scenario B: Open Warning alert already exists -> Critical reading upgrades immediately
      service.evaluatePatientReadingPersistence(
        patientId: 'pB',
        bpm: 112,
        spO2: 96,
        now: t0,
      );
      final openWarn = service.evaluatePatientReadingPersistence(
        patientId: 'pB',
        bpm: 112,
        spO2: 96,
        now: t0.add(const Duration(seconds: 15)),
      );
      expect(openWarn.newlyTriggeredAlert, isTrue);
      expect(openWarn.sessionAlertCount, equals(1));

      final upgraded = service.evaluatePatientReadingPersistence(
        patientId: 'pB',
        bpm: 135, // Critical
        spO2: 96,
        now: t0.add(const Duration(seconds: 18)),
      );
      expect(upgraded.upgradedToCritical, isTrue);
      expect(upgraded.activeAlertSeverity, equals(AlertSeverity.critical));
    });

    test('Steps 6 & 7: Single stray Normal reading does NOT reset 15s timer; 3 consecutive Normal readings clear timer, auto-close Warning, and mark Critical as Recovered', () {
      final t0 = DateTime(2026, 10, 31, 10, 0, 0);

      // Start Warning timer at t0
      service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 112,
        spO2: 96,
        now: t0,
      );

      // 1 normal reading at +5s -> goodReadingsCount = 1, badSince still t0!
      final oneGood = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 80,
        spO2: 98,
        now: t0.add(const Duration(seconds: 5)),
      );
      expect(oneGood.goodReadingsCount, equals(1));
      expect(oneGood.badSince, equals(t0));

      // Bad reading at +10s -> resets goodReadingsCount to 0, timer still t0
      final backToBad = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 114,
        spO2: 96,
        now: t0.add(const Duration(seconds: 10)),
      );
      expect(backToBad.goodReadingsCount, equals(0));
      expect(backToBad.badSince, equals(t0));

      // Open Warning alert at +15s
      final opened = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 114,
        spO2: 96,
        now: t0.add(const Duration(seconds: 15)),
      );
      expect(opened.newlyTriggeredAlert, isTrue);
      expect(opened.sessionAlertCount, equals(1));

      // 3 consecutive good readings at +20s, +25s, +30s -> auto-closes Warning!
      service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 78,
        spO2: 98,
        now: t0.add(const Duration(seconds: 20)),
      );
      service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 78,
        spO2: 98,
        now: t0.add(const Duration(seconds: 25)),
      );
      final recoveredWarn = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 78,
        spO2: 98,
        now: t0.add(const Duration(seconds: 30)),
      );

      expect(recoveredWarn.goodReadingsCount, equals(3));
      expect(recoveredWarn.badSince, isNull);
      expect(recoveredWarn.autoClosedWarning, isTrue);
      expect(recoveredWarn.activeAlertOpen, isFalse);
      // Session alert counter stays at 1 even after recovery
      expect(recoveredWarn.sessionAlertCount, equals(1));

      // Now test Critical recovery on p2: marks Critical as recovered but keeps activeAlertOpen = true
      service.evaluatePatientReadingPersistence(
        patientId: 'p2',
        bpm: 135,
        spO2: 88,
        now: t0,
      );
      service.evaluatePatientReadingPersistence(
        patientId: 'p2',
        bpm: 135,
        spO2: 88,
        now: t0.add(const Duration(seconds: 15)),
      );
      service.evaluatePatientReadingPersistence(
        patientId: 'p2',
        bpm: 78,
        spO2: 98,
        now: t0.add(const Duration(seconds: 20)),
      );
      service.evaluatePatientReadingPersistence(
        patientId: 'p2',
        bpm: 78,
        spO2: 98,
        now: t0.add(const Duration(seconds: 25)),
      );
      final recoveredCrit = service.evaluatePatientReadingPersistence(
        patientId: 'p2',
        bpm: 78,
        spO2: 98,
        now: t0.add(const Duration(seconds: 30)),
      );
      expect(recoveredCrit.markedCriticalRecovered, isTrue);
      expect(recoveredCrit.activeAlertRecovered, isTrue);
      expect(recoveredCrit.activeAlertOpen, isTrue);
    });

    test('Part 3 & Part 5: Counter resets on resetPatientAlertPersistence and escalates on 60s unresolved or 3+ alerts', () {
      final t0 = DateTime(2026, 10, 31, 10, 0, 0);

      // Trigger alert at t0 + 15s
      service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 132,
        spO2: 96,
        now: t0,
      );
      final opened = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 132,
        spO2: 96,
        now: t0.add(const Duration(seconds: 15)),
      );
      expect(opened.newlyTriggeredAlert, isTrue);
      expect(opened.hasEscalated60s, isFalse);

      // 60 seconds after alert opened (t0 + 75s) -> escalates!
      final escalated = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 132,
        spO2: 96,
        now: t0.add(const Duration(seconds: 75)),
      );
      expect(escalated.hasEscalated60s, isTrue);
      expect(escalated.newlyEscalated60s, isTrue);
      expect(escalated.isCounterRed, isTrue);

      // Resetting patient persistence clears counter and 60s flag
      service.resetPatientAlertPersistence('p1');
      final afterReset = service.evaluatePatientReadingPersistence(
        patientId: 'p1',
        bpm: 75,
        spO2: 98,
        now: t0.add(const Duration(seconds: 80)),
      );
      expect(afterReset.sessionAlertCount, equals(0));
      expect(afterReset.hasEscalated60s, isFalse);
      expect(afterReset.isCounterRed, isFalse);
    });
  });

  group('Part 4 & Part 5 UI — Grouped Alert Cards & Patient Log Total Alerts Escalation', () {
    testWidgets('AlertsScreen groups up to 3 active alerts per patient card and shows Check the patient banner', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(
        UserModel(
          staffId: 'N-001',
          name: 'Nurse Rosa',
          role: 'Staff Nurse',
          status: 'Active',
        ),
      );

      final p1 = Patient(
        id: 'p1',
        name: 'Maria Clara',
        mrn: '#000010',
        initials: 'MC',
        chair: 'Chair 1',
        department: 'Dialysis',
        session: '1',
        deviceId: 'device1',
        date: 'Oct 31, 2026',
        startTime: '09:00',
        primaryNurse: 'Nurse Rosa',
        duration: '45m',
        sessionStatus: 'Ongoing',
        status: AlertSeverity.critical,
        currentHr: 134,
        currentSpO2: 88,
        hrHistory: const [134],
        spO2History: const [88],
        recentReadings: const [],
        alertEvents: const [],
        sessionAlertCount: 3,
        hasUnresolved60sAlert: true,
      );

      appState.patients
        ..clear()
        ..add(p1);

      final alerts = List.generate(4, (index) {
        return AlertItem(
          id: 'alert_${index + 1}',
          patientId: 'p1',
          patientName: 'Maria Clara',
          chairLocation: 'Chair 1',
          wardArea: 'Dialysis Bay',
          severity: index.isEven ? AlertSeverity.critical : AlertSeverity.warning,
          title: index.isEven ? 'Critical Heart Rate' : 'Warning SpO2',
          message: index.isEven ? 'HR at 134 BPM' : 'SpO2 at 88%',
          timeString: '09:1$index AM',
          hrBpm: 134,
          spO2: 88,
          isAcknowledged: false,
        );
      });

      appState.alerts
        ..clear()
        ..addAll(alerts);

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

      // 4 active alerts for the same patient should split into 2 grouped cards:
      // Card 1 has 3 alerts (numbered 1, 2, 3) and Card 2 has 1 alert, each with an "Acknowledge" button.
      expect(find.text('Acknowledge'), findsNWidgets(2));
      expect(find.text('#4'), findsNWidgets(2));
      expect(find.textContaining('Check the patient'), findsWidgets);

      appState.dispose();
    });

    testWidgets('PatientLogScreen displays red Total Alerts counter and Check the patient callout when escalated', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(
        UserModel(
          staffId: 'N-001',
          name: 'Nurse Rosa',
          role: 'Staff Nurse',
          status: 'Active',
        ),
      );

      final escalatedPatient = Patient(
        id: 'p_esc',
        name: 'Juan Luna',
        mrn: '#000012',
        initials: 'JL',
        chair: '2',
        department: 'Dialysis',
        session: 'Session 1',
        deviceId: 'device2',
        date: 'Oct 31, 2026',
        startTime: '10:00',
        primaryNurse: 'Nurse Rosa',
        duration: '20m',
        sessionStatus: 'Ongoing',
        status: AlertSeverity.critical,
        currentHr: 130,
        currentSpO2: 89,
        hrHistory: const [130],
        spO2History: const [89],
        recentReadings: const [],
        alertEvents: const [],
        sessionAlertCount: 3,
        hasUnresolved60sAlert: false,
      );

      appState.patients
        ..clear()
        ..add(escalatedPatient);
      appState.setSelectedPatientId('p_esc');

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

      expect(find.text('Check the patient'), findsOneWidget);
      expect(find.text('3 alerts this session.'), findsOneWidget);

      appState.dispose();
    });
  });
}

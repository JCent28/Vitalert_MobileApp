import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/models/patient.dart';
import 'package:vitalert/models/user_model.dart';
import 'package:vitalert/screens/alerts_screen.dart';
import 'package:vitalert/screens/dashboard_screen.dart';
import 'package:vitalert/screens/main_navigation_scaffold.dart';
import 'package:vitalert/screens/patient_log_screen.dart';
import 'package:vitalert/screens/signin_screen.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Patient createSamplePatient({
    String id = 'patient_test_01',
    String name = 'Juan dela Cruz',
    String chair = '1',
    int bpm = 78,
    int spo2 = 98,
  }) {
    return Patient(
      id: id,
      name: name,
      mrn: '#001001',
      initials: 'JC',
      chair: chair,
      department: 'NephroAsia Dialysis Bay',
      session: 'Session 1',
      deviceId: 'device1',
      date: 'Monday, October 14, 2026',
      startTime: '08:00',
      primaryNurse: 'Nurse Maria',
      duration: '1h 30m',
      sessionStatus: 'Ongoing',
      status: AlertSeverity.info,
      currentHr: bpm,
      currentSpO2: spo2,
      highestHr: 85,
      lowestHr: 72,
      avgHr: 77,
      highestSpO2: 99,
      lowestSpO2: 96,
      avgSpO2: 98,
      hrHistory: [bpm.toDouble()],
      spO2History: [spo2.toDouble()],
      recentReadings: const [],
      alertEvents: const [],
    );
  }

  AlertItem createSampleAlert({
    String id = 'alert_test_01',
    String patientId = 'patient_test_01',
    String patientName = 'Juan dela Cruz',
    AlertSeverity severity = AlertSeverity.warning,
    String message = 'High Heart Rate Detected',
  }) {
    return AlertItem(
      id: id,
      patientId: patientId,
      patientName: patientName,
      chairLocation: 'Chair 1',
      wardArea: 'NephroAsia Dialysis Bay',
      severity: severity,
      title: 'WARNING',
      message: message,
      timeString: '09:30 AM',
    );
  }

  group('M17: Vitalert Current Screen Widget Tests', () {
    testWidgets('SignInScreen renders empty input fields, role dropdown, and validates empty submission', (tester) async {
      final appState = AppState();
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(
            state: appState,
            onLoginSuccess: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header, fields, and action button exist
      expect(find.text('STAFF ID'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CLINICAL ROLE'), findsOneWidget);
      expect(find.text('Access Nurse Station'), findsOneWidget);

      // Verify fields are blank by default (M13 verification)
      final textFields = find.byType(TextField);
      final staffIdWidget = tester.widget<TextField>(textFields.at(0));
      final passwordWidget = tester.widget<TextField>(textFields.at(1));

      expect(staffIdWidget.controller?.text.isEmpty ?? true, isTrue);
      expect(passwordWidget.controller?.text.isEmpty ?? true, isTrue);

      // Tap submit with empty fields to verify validation message
      await tester.tap(find.text('Access Nurse Station'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your Staff ID.'), findsOneWidget);

      appState.dispose();
    });

    testWidgets('DashboardScreen renders active patients and telemetry summary', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(UserModel(
        staffId: 'SN-00101',
        name: 'Nurse Maria',
        role: 'Staff Nurse',
        status: 'Active',
      ));

      final patient = createSamplePatient();
      appState.patients.add(patient);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardScreen(
              state: appState,
              onPatientSelected: (_) {},
              onSignOut: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dashboard title, station badge, and patient row
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Station 2'), findsWidgets);
      expect(find.text('Juan dela Cruz'), findsWidgets);

      appState.dispose();
    });

    testWidgets('AlertsScreen renders active alerts and severity badges', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(UserModel(
        staffId: 'SN-00101',
        name: 'Nurse Maria',
        role: 'Staff Nurse',
        status: 'Active',
      ));

      final alert = createSampleAlert();
      appState.alerts.add(alert);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

      // Verify Alerts title and alert content
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('High Heart Rate Detected'), findsOneWidget);
      expect(find.text('Juan dela Cruz'), findsWidgets);

      appState.dispose();
    });

    testWidgets('PatientLogScreen renders selected patient telemetry and vitals', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(UserModel(
        staffId: 'SN-00101',
        name: 'Nurse Maria',
        role: 'Staff Nurse',
        status: 'Active',
      ));

      final patient = createSamplePatient();
      appState.patients.add(patient);
      appState.selectPatient(patient.id);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

      expect(find.text('Patient Log'), findsWidgets);
      expect(find.text('Juan dela Cruz'), findsWidgets);
      expect(find.text('Vital Trends'), findsOneWidget);

      appState.dispose();
    });

    testWidgets('MainNavigationScaffold renders bottom navigation and navigates between tabs', (tester) async {
      final appState = AppState();
      appState.setCurrentUserForTesting(UserModel(
        staffId: 'SN-00101',
        name: 'Nurse Maria',
        role: 'Staff Nurse',
        status: 'Active',
      ));

      final patient = createSamplePatient();
      final alert = createSampleAlert();
      appState.patients.add(patient);
      appState.alerts.add(alert);
      appState.selectPatient(patient.id);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationScaffold(
            state: appState,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Dashboard tab
      expect(appState.currentTabIndex, equals(0));
      expect(find.text('Dashboard'), findsWidgets);

      // Switch to Alerts tab (index 1)
      appState.setTabIndex(1);
      await tester.pumpAndSettle();
      expect(find.text('High Heart Rate Detected'), findsOneWidget);

      // Switch to Patient Log tab (index 2)
      appState.setTabIndex(2);
      await tester.pumpAndSettle();
      expect(find.text('Vital Trends'), findsOneWidget);

      appState.dispose();
    });
  });
}

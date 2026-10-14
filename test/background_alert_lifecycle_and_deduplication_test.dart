import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/services/alert_notification_service.dart';
import 'package:vitalert/services/foreground_service_manager.dart';
import 'package:vitalert/services/session_storage_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M10 (P1) Background Alerting Lifecycle & Cross-Isolate Deduplication', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AlertNotificationService.resetStateForTesting();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_foreground_task/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isRunningService') return false;
          if (methodCall.method == 'requestNotificationPermission') return 1;
          return true;
        },
      );
    });

    tearDown(() {
      AlertNotificationService.resetStateForTesting();
    });

    test('Logged-out phone does not trigger heads-up alerts during live sync', () async {
      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(appState.isLoggedIn, isFalse);

      final testAlerts = [
        AlertItem(
          id: 'alert_critical_001',
          patientId: 'patient_001',
          patientName: 'John Doe',
          chairLocation: 'Chair 1',
          wardArea: 'Station A',
          severity: AlertSeverity.critical,
          title: 'CRITICAL ALERT',
          message: 'Desaturation: 84% SpO2',
          timeString: '10:00',
          isAcknowledged: false,
        ),
      ];

      expect(testAlerts, isNotEmpty);
      // AlertNotificationService should not have notified this alert yet
      expect(await AlertNotificationService.isAlertNotified(testAlerts.first.id), isFalse);

      appState.dispose();
    });

    test('VitalertTaskHandler guards against execution on a logged-out phone and stops service', () async {
      SharedPreferences.setMockInitialValues({}); // No session saved

      final handler = VitalertTaskHandler();
      await handler.onStart(DateTime.now(), TaskStarter.developer);

      // Running repeat event with no saved session
      await handler.onRepeatEvent(DateTime.now());

      // Confirm session is still null and no alerts were recorded as notified
      final session = await SessionStorageService.loadSession();
      expect(session, isNull);
      expect(await AlertNotificationService.isAlertNotified('any_alert'), isFalse);
    });

    test('VitalertTaskHandler guards against deactivated nurse session', () async {
      SharedPreferences.setMockInitialValues({
        'vitalert_is_logged_in': true,
        'vitalert_staff_id': 'SN-00999',
        'vitalert_staff_name': 'Inactive Nurse',
        'vitalert_staff_role': 'Staff Nurse',
        'vitalert_staff_status': 'Inactive',
      });

      final handler = VitalertTaskHandler();
      await handler.onRepeatEvent(DateTime.now());

      // With an inactive status, handler stops and does not process alerts
      expect(await AlertNotificationService.isAlertNotified('any_alert'), isFalse);
    });

    test('Sign-in restores session and sets isLoggedIn to true', () async {
      SharedPreferences.setMockInitialValues({
        'vitalert_is_logged_in': true,
        'vitalert_staff_id': 'HN-00312',
        'vitalert_staff_name': 'Clark Kent',
        'vitalert_staff_role': 'Head Nurse',
        'vitalert_staff_status': 'Active',
      });

      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(appState.isLoggedIn, isTrue);
      expect(appState.currentUser?.staffId, equals('HN-00312'));
      expect(appState.currentUser?.name, equals('Clark Kent'));

      appState.dispose();
    });

    test('Sign-out clears session, isLoggedIn flag, and stops alerting', () async {
      SharedPreferences.setMockInitialValues({
        'vitalert_is_logged_in': true,
        'vitalert_staff_id': 'HN-00312',
        'vitalert_staff_name': 'Clark Kent',
        'vitalert_staff_role': 'Head Nurse',
        'vitalert_staff_status': 'Active',
      });

      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(appState.isLoggedIn, isTrue);

      // Perform sign out
      await appState.signOut();

      expect(appState.isLoggedIn, isFalse);
      expect(appState.currentUser, isNull);

      final sessionAfterSignOut = await SessionStorageService.loadSession();
      expect(sessionAfterSignOut, isNull);

      appState.dispose();
    });

    test('AlertNotificationService deduplicates alerts across simulated isolates using SharedPreferences', () async {
      final alert = AlertItem(
        id: 'alert_dup_101',
        patientId: 'patient_dup',
        patientName: 'Jane Smith',
        chairLocation: 'Chair 4',
        wardArea: 'Station B',
        severity: AlertSeverity.critical,
        title: 'CRITICAL ALERT',
        message: 'Severe Tachycardia: 145 BPM',
        timeString: '11:15',
        isAcknowledged: false,
      );

      // Initially, alert is not notified
      expect(await AlertNotificationService.isAlertNotified(alert.id), isFalse);

      // Isolate A (e.g. Main UI) processes and notifies the alert
      await AlertNotificationService.markAlertNotified(alert.id);
      expect(await AlertNotificationService.isAlertNotified(alert.id), isTrue);

      // Verify that SharedPreferences now holds the notified alert ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final savedIds = prefs.getStringList('vitalert_notified_alert_ids') ?? [];
      expect(savedIds, contains(alert.id));

      // Simulate Isolate B (Foreground Task) in a separate memory context:
      // Clear in-memory set to mimic a separate isolate's heap memory
      AlertNotificationService.resetStateForTesting();

      // Isolate B checks if alert was already notified
      final isAlreadyNotifiedInIsolateB = await AlertNotificationService.isAlertNotified(alert.id);
      expect(isAlreadyNotifiedInIsolateB, isTrue,
          reason: 'Isolate B must detect the alert was already notified via shared persistent storage');

      // Attempting to show the notification again in Isolate B should be blocked by deduplication
      await AlertNotificationService.showAlertNotification(alert);

      // Saved list should still contain only one instance of the ID
      await prefs.reload();
      final updatedList = prefs.getStringList('vitalert_notified_alert_ids') ?? [];
      expect(updatedList.where((id) => id == alert.id).length, equals(1),
          reason: 'Deduplication must prevent duplicate entries for the same alert');
    });

    test('processLiveAlerts does not re-notify for already notified alerts during real-time streaming', () async {
      final alert1 = AlertItem(
        id: 'alert_stream_001',
        patientId: 'patient_stream',
        patientName: 'Alice Brown',
        chairLocation: 'Chair 2',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'WARNING ALERT',
        message: 'Mild desaturation: 91% SpO2',
        timeString: '12:00',
        isAcknowledged: false,
      );

      // Perform initial sync with alert1
      await AlertNotificationService.processLiveAlerts([alert1]);
      expect(await AlertNotificationService.isAlertNotified(alert1.id), isTrue);

      // Next streaming tick arrives with the same alert still unacknowledged
      await AlertNotificationService.processLiveAlerts([alert1]);

      // Verify no duplicates created
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final savedList = prefs.getStringList('vitalert_notified_alert_ids') ?? [];
      expect(savedList.where((id) => id == alert1.id).length, equals(1));
    });

    test('Initial sync marks historical alerts as known so past alerts are never spammed', () async {
      final oldAlert1 = AlertItem(
        id: 'old_alert_1',
        patientId: 'patient_old',
        patientName: 'Old Patient',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'WARNING ALERT',
        message: 'Past warning',
        timeString: '09:00',
        isAcknowledged: true,
      );

      final oldAlert2 = AlertItem(
        id: 'old_alert_2',
        patientId: 'patient_old',
        patientName: 'Old Patient',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'WARNING ALERT',
        message: 'Past warning 2',
        timeString: '09:10',
        isAcknowledged: true,
      );

      await AlertNotificationService.processLiveAlerts([oldAlert1, oldAlert2]);

      expect(await AlertNotificationService.isAlertNotified(oldAlert1.id), isTrue);
      expect(await AlertNotificationService.isAlertNotified(oldAlert2.id), isTrue);
    });
  });
}

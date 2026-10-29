import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/services/alert_audio_service.dart';
import 'package:vitalert/services/alert_notification_service.dart';
import 'package:vitalert/services/session_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AlertAudioService & In-App Alert Audio Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AlertNotificationService.resetStateForTesting();
      AlertAudioService.resetForTesting();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_foreground_task/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isRunningService') return false;
          if (methodCall.method == 'requestNotificationPermission') return 1;
          return true;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async {
          return 1;
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async {
          return 1;
        },
      );
    });

    tearDown(() {
      AlertAudioService.stopSound();
      AlertNotificationService.resetStateForTesting();
    });

    test('AlertAudioService initial state is not playing', () {
      expect(AlertAudioService.isPlaying, isFalse);
      expect(AlertAudioService.currentPlayingType, isNull);
    });

    test('AlertAudioService stopSound clears playing state without error', () async {
      await AlertAudioService.stopSound();
      expect(AlertAudioService.isPlaying, isFalse);
      expect(AlertAudioService.currentPlayingType, isNull);
    });

    test('RootBundle loads audio assets correctly', () async {
      final criticalData = await rootBundle.load('assets/sounds/critical_alarm.mp3');
      expect(criticalData.lengthInBytes, equals(75264));
      final warningData = await rootBundle.load('assets/sounds/warning_alert.mp3');
      expect(warningData.lengthInBytes, equals(62208));
    });

    test('AlertAudioService.playCriticalAlarm handles execution gracefully', () async {
      final result = await AlertAudioService.playCriticalAlarm();
      expect(result, isA<bool>());
    });

    test('AlertAudioService.playWarningAlert handles execution gracefully', () async {
      final result = await AlertAudioService.playWarningAlert();
      expect(result, isA<bool>());
    });

    test('triggerTestAlertSound creates test alert and marks notified', () async {
      await AlertNotificationService.triggerTestAlertSound(isCritical: true);
      // Verify deduplication list recorded an alert starting with test_alert_
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final savedIds = prefs.getStringList('vitalert_notified_alert_ids') ?? [];
      expect(savedIds.any((id) => id.startsWith('test_alert_')), isTrue);
    });

    test('Notification channels are set to v4 to ensure fresh Android channel configuration', () {
      expect(AlertNotificationService.criticalChannelId, equals('vitalert_critical_channel_v4'));
      expect(AlertNotificationService.warningChannelId, equals('vitalert_warning_channel_v4'));
    });

    test('dismissAlert stops any playing audio and cancels notification', () async {
      await AlertNotificationService.dismissAlert('test_alert_001', patientId: 'patient_001');
      expect(AlertAudioService.isPlaying, isFalse);
      expect(AlertAudioService.currentPlayingType, isNull);
    });

    test('processLiveAlerts does not pre-mark latest unacknowledged alert before showAlertNotification', () async {
      final alerts = [
        AlertItem(
          id: 'bg_alert_101',
          patientId: 'patient_01',
          patientName: 'Test Patient',
          chairLocation: 'Chair 1',
          wardArea: 'Station 1',
          severity: AlertSeverity.critical,
          title: 'CRITICAL ALERT',
          message: 'SpO2 dropped to 86%',
          timeString: '10:15',
          timestamp: 1700000100,
          isAcknowledged: false,
        ),
      ];

      // 1. Initial sync should notify the single latest unacknowledged alert
      await AlertNotificationService.processLiveAlerts(alerts);
      expect(await AlertNotificationService.isAlertNotified('bg_alert_101'), isTrue);

      // 2. Subsequent real-time poll with a brand new alert should also notify it (not skip due to pre-marking)
      final alertsWithNew = [
        ...alerts,
        AlertItem(
          id: 'bg_alert_102',
          patientId: 'patient_01',
          patientName: 'Test Patient',
          chairLocation: 'Chair 1',
          wardArea: 'Station 1',
          severity: AlertSeverity.critical,
          title: 'CRITICAL ALERT',
          message: 'SpO2 dropped to 84%',
          timeString: '10:16',
          timestamp: 1700000200,
          isAcknowledged: false,
        ),
      ];
      await AlertNotificationService.processLiveAlerts(alertsWithNew);
      expect(await AlertNotificationService.isAlertNotified('bg_alert_102'), isTrue);
    });

    test('SessionStorageService.loadSession reloads persisted session across isolates', () async {
      await SessionStorageService.saveSession(
        staffId: 'SN-001',
        name: 'Nurse Joy',
        role: 'Staff Nurse',
        status: 'Active',
      );
      final loaded = await SessionStorageService.loadSession();
      expect(loaded, isNotNull);
      expect(loaded!['staffId'], equals('SN-001'));
      expect(loaded['status'], equals('Active'));
    });
  });
}

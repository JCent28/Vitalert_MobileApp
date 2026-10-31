import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_item.dart';
import 'alert_audio_service.dart';

class AlertNotificationService {
  static const String _prefsKeyNotifiedAlerts = 'vitalert_notified_alert_ids';
  static const String criticalChannelId = 'vitalert_critical_channel_v4';
  static const String warningChannelId = 'vitalert_warning_channel_v4';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final Set<String> _notifiedAlertIds = {};
  static final Map<String, AlertSeverity> _notifiedAlertSeverities = {};
  static bool _isInitialized = false;
  static bool _hasPerformedInitialSync = false;
  static bool _isStoreLoaded = false;
  static const int _activeNotificationId = 8888;

  /// Loads persisted notified alert IDs from SharedPreferences
  static Future<void> _ensurePersistedIdsLoaded() async {
    if (_isStoreLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final saved = prefs.getStringList(_prefsKeyNotifiedAlerts) ?? [];
      _notifiedAlertIds.addAll(saved);
      _isStoreLoaded = true;
    } catch (e) {
      debugPrint('Error loading persisted notified alert IDs: $e');
    }
  }

  /// Directly records an ID into local in-memory set (e.g. from cross-isolate port message)
  static void recordNotifiedIdInMemory(String alertId) {
    if (alertId.isNotEmpty) {
      _notifiedAlertIds.add(alertId);
    }
  }

  /// Checks whether an alert has already been notified in either isolate
  static Future<bool> isAlertNotified(String alertId) async {
    if (_notifiedAlertIds.contains(alertId)) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final saved = prefs.getStringList(_prefsKeyNotifiedAlerts) ?? [];
      if (saved.contains(alertId)) {
        _notifiedAlertIds.add(alertId);
        return true;
      }
    } catch (e) {
      debugPrint('Error checking notified alert: $e');
    }
    return false;
  }

  /// Marks a single alert as notified across memory, disk, and isolate ports
  static Future<void> markAlertNotified(String alertId, {String? severity}) async {
    if (alertId.isEmpty) return;
    _notifiedAlertIds.add(alertId);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final saved = (prefs.getStringList(_prefsKeyNotifiedAlerts) ?? []).toSet();
      saved.add(alertId);
      final list = saved.length > 200
          ? saved.toList().sublist(saved.length - 200)
          : saved.toList();
      await prefs.setStringList(_prefsKeyNotifiedAlerts, list);
    } catch (e) {
      debugPrint('Error saving notified alert ID: $e');
    }

    final payload = <String, dynamic>{
      'type': 'alert_notified',
      'id': alertId,
      'severity': ?severity,
    };

    // Broadcast to the other isolate (Task <-> Main)
    try {
      FlutterForegroundTask.sendDataToTask(payload);
    } catch (_) {}
    try {
      FlutterForegroundTask.sendDataToMain(payload);
    } catch (_) {}
  }

  /// Marks a batch of alert IDs as known (e.g. historical alerts during initial sync)
  static Future<void> markAlertsBatch(Iterable<String> alertIds) async {
    final validIds = alertIds.where((id) => id.isNotEmpty).toList();
    if (validIds.isEmpty) return;
    _notifiedAlertIds.addAll(validIds);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final saved = (prefs.getStringList(_prefsKeyNotifiedAlerts) ?? []).toSet();
      saved.addAll(validIds);
      final list = saved.length > 200
          ? saved.toList().sublist(saved.length - 200)
          : saved.toList();
      await prefs.setStringList(_prefsKeyNotifiedAlerts, list);
    } catch (e) {
      debugPrint('Error saving batch notified alert IDs: $e');
    }
  }

  static Future<void> initialize({bool isBackgroundIsolate = false}) async {
    await _ensurePersistedIdsLoaded();
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Create Android Notification Channels for Critical & Warning alarms
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        if (!isBackgroundIsolate) {
          // Request runtime notification permission for Android 13+ (API 33+)
          // Only request when an Activity is attached in the main UI isolate
          try {
            await androidPlugin.requestNotificationsPermission();
          } catch (e) {
            debugPrint('Notification permission request skipped/error: $e');
          }

          // Delete legacy channels so OS adopts fresh v4 audio configuration
          try {
            await androidPlugin.deleteNotificationChannel('vitalert_critical_channel');
            await androidPlugin.deleteNotificationChannel('vitalert_critical_channel_v2');
            await androidPlugin.deleteNotificationChannel('vitalert_critical_channel_v3');
            await androidPlugin.deleteNotificationChannel('vitalert_warning_channel');
            await androidPlugin.deleteNotificationChannel('vitalert_warning_channel_v2');
            await androidPlugin.deleteNotificationChannel('vitalert_warning_channel_v3');
          } catch (_) {}
        }

        // 1. Critical Channel (Max Importance, Screen Wake, Alarm Category, Pulsating Vibration, Custom Audio)
        final AndroidNotificationChannel criticalChannel =
            AndroidNotificationChannel(
          criticalChannelId,
          'Critical Patient Alarms',
          description:
              'Immediate alarms for critical desaturation and severe tachycardia.',
          importance: Importance.max,
          enableVibration: true,
          vibrationPattern:
              Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
          enableLights: true,
          ledColor: const Color(0xFFEF4444),
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('critical_alarm'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        // 2. Warning Channel (High Importance, Custom Audio)
        final AndroidNotificationChannel warningChannel =
            AndroidNotificationChannel(
          warningChannelId,
          'Warning Patient Alerts',
          description:
              'Alerts for physiological parameter warnings and vital deviations.',
          importance: Importance.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          enableLights: true,
          ledColor: const Color(0xFFF59E0B),
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('warning_alert'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );

        await androidPlugin.createNotificationChannel(criticalChannel);
        await androidPlugin.createNotificationChannel(warningChannel);
      }

      _isInitialized = true;
      debugPrint('AlertNotificationService initialized successfully with channel v4 (background=$isBackgroundIsolate).');
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Evaluates alerts and notifies ONLY for newly triggered unacknowledged alerts with unified cross-isolate deduplication
  static Future<void> processLiveAlerts(List<AlertItem> alerts) async {
    await _ensurePersistedIdsLoaded();

    if (alerts.isEmpty) {
      if (!_hasPerformedInitialSync) {
        _hasPerformedInitialSync = true;
      }
      return;
    }

    // Filter unacknowledged alerts (sorted newest first by timestamp, falling back to key)
    final unacknowledged = alerts.where((a) => !a.isAcknowledged).toList()
      ..sort(AlertItem.compareNewestFirst);
    final acknowledgedIds = alerts.where((a) => a.isAcknowledged).map((a) => a.id);

    // 1. On Initial App Launch: do not flood with all past alerts, but ensure the latest active unacknowledged alert notifies
    if (!_hasPerformedInitialSync) {
      _hasPerformedInitialSync = true;

      // Always mark acknowledged alerts as seen
      await markAlertsBatch(acknowledgedIds);

      if (unacknowledged.isNotEmpty) {
        final latest = unacknowledged.first;
        // Mark older unacknowledged alerts as seen so we don't spam multiple notifications at once
        if (unacknowledged.length > 1) {
          await markAlertsBatch(unacknowledged.skip(1).map((a) => a.id));
        }
        // Notify for the single latest active alert if it hasn't been notified yet
        if (!await isAlertNotified(latest.id)) {
          await showAlertNotification(latest);
        }
      }
      return;
    }

    // 2. During Real-Time Streaming: check for newly triggered unacknowledged alerts,
    // severity upgrades (Warning -> Critical), or 60-second unresolved escalations (Part 5 & Part 6)
    final List<AlertItem> newAlerts = [];
    final now = DateTime.now();

    for (final a in unacknowledged) {
      final prevSeverity = _notifiedAlertSeverities[a.id];
      final upgradedKey = '${a.id}_upgraded_critical';
      final escalated60sKey = '${a.id}_escalated_60s';

      if (!await isAlertNotified(a.id)) {
        newAlerts.add(a);
      } else if (a.severity == AlertSeverity.critical &&
          prevSeverity == AlertSeverity.warning &&
          !await isAlertNotified(upgradedKey)) {
        // Part 2 & Part 6: Existing Warning alert upgraded to Critical -> play second chime immediately
        await markAlertNotified(upgradedKey, severity: AlertSeverity.critical.name);
        _notifiedAlertSeverities[a.id] = AlertSeverity.critical;
        await showAlertNotification(a, forceNotify: true);
      } else if (a.isUnresolvedOver60s(now: now) &&
          !await isAlertNotified(escalated60sKey)) {
        // Part 5: Unresolved for >= 60 seconds -> play second chime and show "Check the patient"
        await markAlertNotified(escalated60sKey, severity: AlertSeverity.critical.name);
        await showAlertNotification(
          AlertItem(
            id: a.id,
            patientId: a.patientId,
            patientName: a.patientName,
            chairLocation: a.chairLocation,
            wardArea: a.wardArea,
            severity: AlertSeverity.critical,
            title: 'CHECK THE PATIENT',
            message: 'Check the patient — Alert unresolved for over a minute (${a.message})',
            timeString: a.timeString,
            hrBpm: a.hrBpm,
            spO2: a.spO2,
            isEscalated60s: true,
            timestamp: a.timestamp,
            session: a.session,
          ),
          forceNotify: true,
        );
      }
    }

    // Also check if any patient has reached >= 3 unacknowledged alerts in this session (Part 5 Path B)
    final Map<String, List<AlertItem>> byPatient = {};
    for (final a in unacknowledged) {
      if (a.patientId.isNotEmpty) {
        byPatient.putIfAbsent(a.patientId, () => []).add(a);
      }
    }
    for (final entry in byPatient.entries) {
      if (entry.value.length >= 3) {
        final latestThreeKey = '${entry.key}_episode3_${entry.value.first.id}';
        if (!await isAlertNotified(latestThreeKey)) {
          await markAlertNotified(latestThreeKey, severity: AlertSeverity.critical.name);
        }
      }
    }

    // Mark acknowledged alerts and older new alerts as seen BEFORE showing notification
    // Note: Do NOT mark `newAlerts.first` before calling `showAlertNotification`,
    // otherwise `showAlertNotification`'s `isAlertNotified` guard will skip it!
    await markAlertsBatch(acknowledgedIds);

    if (newAlerts.isNotEmpty) {
      newAlerts.sort(AlertItem.compareNewestFirst);
      for (final a in newAlerts) {
        _notifiedAlertSeverities[a.id] = a.severity;
      }
      if (newAlerts.length > 1) {
        await markAlertsBatch(newAlerts.skip(1).map((a) => a.id));
      }
      final topAlert = newAlerts.first;
      final patientUnackCount = byPatient[topAlert.patientId]?.length ?? 1;
      if (patientUnackCount >= 3) {
        await showAlertNotification(
          AlertItem(
            id: topAlert.id,
            patientId: topAlert.patientId,
            patientName: topAlert.patientName,
            chairLocation: topAlert.chairLocation,
            wardArea: topAlert.wardArea,
            severity: AlertSeverity.critical,
            title: 'CHECK THE PATIENT',
            message: 'Check the patient — $patientUnackCount alerts this session (${topAlert.message})',
            timeString: topAlert.timeString,
            hrBpm: topAlert.hrBpm,
            spO2: topAlert.spO2,
            timestamp: topAlert.timestamp,
            session: topAlert.session,
          ),
        );
      } else {
        await showAlertNotification(topAlert);
      }
    }
  }

  /// Displays the heads-up notification with screen wake
  static Future<void> showAlertNotification(
    AlertItem alert, {
    bool forceNotify = false,
  }) async {
    // Cross-isolate deduplication guard: if already notified, skip (unless forceNotify for upgrade/escalation)
    if (!forceNotify && await isAlertNotified(alert.id)) {
      debugPrint('AlertNotificationService: skipping already notified alert ${alert.id}');
      return;
    }

    // Record as notified across memory, storage, and cross-isolate ports
    _notifiedAlertSeverities[alert.id] = alert.severity;
    await markAlertNotified(alert.id, severity: alert.severity.name);

    final isCritical = alert.severity == AlertSeverity.critical;

    // Concurrently trigger in-app audible alarm so clinicians hear the alert directly from speaker
    if (isCritical) {
      AlertAudioService.playCriticalAlarm().catchError((e) {
        debugPrint('In-app critical audio playback error: $e');
        return false;
      });
    } else {
      AlertAudioService.playWarningAlert().catchError((e) {
        debugPrint('In-app warning audio playback error: $e');
        return false;
      });
    }

    // Use patient ID hash so each patient has at most 1 active heads-up notification, replacing older alerts from that patient
    // Clamp to positive 31-bit integer for Android NotificationManager compatibility
    final id = alert.patientId.isNotEmpty
        ? (alert.patientId.hashCode.abs() % 2147483647)
        : _activeNotificationId;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      isCritical ? criticalChannelId : warningChannelId,
      isCritical ? 'Critical Patient Alarms' : 'Warning Patient Alerts',
      channelDescription: isCritical
          ? 'Immediate alarms for critical desaturation and severe tachycardia.'
          : 'Alerts for physiological parameter warnings.',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: isCritical, // Automatically lights up the device screen for critical alarms
      category: AndroidNotificationCategory.alarm,
      color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
      colorized: true,
      ongoing: isCritical, // Keeps alarm visible until acknowledged
      autoCancel: false,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        isCritical ? 'critical_alarm' : 'warning_alert',
      ),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: isCritical ? 'CRITICAL PATIENT ALARM' : 'PATIENT WARNING',
      styleInformation: BigTextStyleInformation(
        '${alert.message}\nChair: ${alert.chairLocation} · Station: ${alert.wardArea}',
        contentTitle: isCritical
            ? '🚨 CRITICAL: ${alert.patientName} (${alert.chairLocation})'
            : '⚠️ WARNING: ${alert.patientName} (${alert.chairLocation})',
        summaryText: alert.wardArea,
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'ACKNOWLEDGE',
          'Acknowledge',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id,
        isCritical
            ? '🚨 CRITICAL: ${alert.patientName} (${alert.chairLocation})'
            : '⚠️ WARNING: ${alert.patientName} (${alert.chairLocation})',
        alert.message,
        details,
        payload: alert.patientId,
      );
    } catch (e) {
      debugPrint('Error showing alert notification: $e');
    }
  }

  static Future<void> dismissAlert(String alertId, {String? patientId}) async {
    try {
      await AlertAudioService.stopSound();
      await _notificationsPlugin.cancel(alertId.hashCode.abs() % 2147483647);
      if (patientId != null && patientId.isNotEmpty) {
        await _notificationsPlugin.cancel(patientId.hashCode.abs() % 2147483647);
      }
    } catch (_) {}
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await AlertAudioService.stopSound();
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  /// Dispatches a test alarm notification (Warning or Critical) and plays the audio directly to verify sound & vibration on-device
  static Future<void> triggerTestAlertSound({required bool isCritical}) async {
    // 1. Play audible sound directly through device speaker
    try {
      if (isCritical) {
        await AlertAudioService.playCriticalAlarm();
      } else {
        await AlertAudioService.playWarningAlert();
      }
    } catch (e) {
      debugPrint('Error playing test alert sound: $e');
    }

    // 2. Dispatch heads-up test notification
    final testAlert = AlertItem(
      id: 'test_alert_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'patient_sound_test',
      patientName: 'Audio Test Patient',
      chairLocation: 'Chair 1',
      wardArea: 'NephroAsia Station 2',
      severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
      title: isCritical ? 'Critical Desaturation' : 'Elevated Heart Rate',
      message: isCritical
          ? 'TEST CRITICAL ALARM: SpO2 critical drop to 88% (Sound Test)'
          : 'TEST WARNING ALERT: Elevated heart rate 108 BPM (Sound Test)',
      timeString: 'Just now',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await showAlertNotification(testAlert);
  }

  /// Dispatches a test alarm notification after a delay (e.g. 5 seconds) so the nurse can
  /// minimize, close, or lock the app and verify background notification & alarm sound delivery.
  static Future<void> triggerDelayedBackgroundTestAlert({
    required bool isCritical,
    Duration delay = const Duration(seconds: 5),
  }) async {
    Future.delayed(delay, () async {
      // Also notify the background task isolate to trigger if running
      try {
        FlutterForegroundTask.sendDataToTask({
          'type': 'trigger_test_alert',
          'isCritical': isCritical,
        });
      } catch (_) {}

      await triggerTestAlertSound(isCritical: isCritical);
    });
  }

  @visibleForTesting
  static void resetStateForTesting() {
    _notifiedAlertIds.clear();
    _notifiedAlertSeverities.clear();
    _isInitialized = false;
    _hasPerformedInitialSync = false;
    _isStoreLoaded = false;
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alert_item.dart';

class AlertNotificationService {
  static const String _prefsKeyNotifiedAlerts = 'vitalert_notified_alert_ids';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final Set<String> _notifiedAlertIds = {};
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
  static Future<void> markAlertNotified(String alertId) async {
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

    // Broadcast to the other isolate (Task <-> Main)
    try {
      FlutterForegroundTask.sendDataToTask({'type': 'alert_notified', 'id': alertId});
    } catch (_) {}
    try {
      FlutterForegroundTask.sendDataToMain({'type': 'alert_notified', 'id': alertId});
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

  static Future<void> initialize() async {
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
        // Request runtime notification permission for Android 13+ (API 33+)
        await androidPlugin.requestNotificationsPermission();

        // Delete legacy v1 channels if they exist so OS adopts new audio configuration
        try {
          await androidPlugin.deleteNotificationChannel('vitalert_critical_channel');
          await androidPlugin.deleteNotificationChannel('vitalert_warning_channel');
        } catch (_) {}

        // 1. Critical Channel (Max Importance, Screen Wake, Alarm Category, Pulsating Vibration, Custom Audio)
        final AndroidNotificationChannel criticalChannel =
            AndroidNotificationChannel(
          'vitalert_critical_channel_v2',
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
          'vitalert_warning_channel_v2',
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
      debugPrint('AlertNotificationService initialized successfully.');
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

    // 1. On Initial App Launch: do not flood with all past alerts
    if (!_hasPerformedInitialSync) {
      _hasPerformedInitialSync = true;

      // Mark all existing alerts in the database as seen so old history is never spammed
      await markAlertsBatch(alerts.map((a) => a.id));

      // If there is an active unacknowledged alert, only notify for the single latest one if not already notified
      if (unacknowledged.isNotEmpty) {
        final latest = unacknowledged.first;
        if (!await isAlertNotified(latest.id)) {
          await showAlertNotification(latest);
        }
      }
      return;
    }

    // 2. During Real-Time Streaming: check for newly triggered unacknowledged alerts that were NOT yet notified
    final List<AlertItem> newAlerts = [];
    for (final a in unacknowledged) {
      if (!await isAlertNotified(a.id)) {
        newAlerts.add(a);
      }
    }

    // Mark all current alerts as seen in the deduplication store
    await markAlertsBatch(alerts.map((a) => a.id));

    if (newAlerts.isNotEmpty) {
      newAlerts.sort(AlertItem.compareNewestFirst);
      await showAlertNotification(newAlerts.first);
    }
  }

  /// Displays the heads-up notification with screen wake
  static Future<void> showAlertNotification(AlertItem alert) async {
    // Cross-isolate deduplication guard: if already notified, skip
    if (await isAlertNotified(alert.id)) {
      debugPrint('AlertNotificationService: skipping already notified alert ${alert.id}');
      return;
    }

    // Record as notified across memory, storage, and cross-isolate ports
    await markAlertNotified(alert.id);

    final isCritical = alert.severity == AlertSeverity.critical;
    // Use patient ID hash so each patient has at most 1 active heads-up notification, replacing older alerts from that patient
    final id = alert.patientId.isNotEmpty
        ? alert.patientId.hashCode
        : _activeNotificationId;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      isCritical ? 'vitalert_critical_channel_v2' : 'vitalert_warning_channel_v2',
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
      await _notificationsPlugin.cancel(alertId.hashCode);
      if (patientId != null && patientId.isNotEmpty) {
        await _notificationsPlugin.cancel(patientId.hashCode);
      }
    } catch (_) {}
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  /// Dispatches a test alarm notification (Warning or Critical) to verify sound & vibration on-device
  static Future<void> triggerTestAlertSound({required bool isCritical}) async {
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

  @visibleForTesting
  static void resetStateForTesting() {
    _notifiedAlertIds.clear();
    _isInitialized = false;
    _hasPerformedInitialSync = false;
    _isStoreLoaded = false;
  }
}

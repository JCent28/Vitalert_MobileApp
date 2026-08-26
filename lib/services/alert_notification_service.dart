import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alert_item.dart';

class AlertNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final Set<String> _notifiedAlertIds = {};
  static bool _isInitialized = false;
  static bool _hasPerformedInitialSync = false;
  static const int _activeNotificationId = 8888;

  static Future<void> initialize() async {
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

        // 1. Critical Channel (Max Importance, Screen Wake, Alarm Category, Pulsating Vibration)
        final AndroidNotificationChannel criticalChannel =
            AndroidNotificationChannel(
          'vitalert_critical_channel',
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
        );

        // 2. Warning Channel (High Importance)
        final AndroidNotificationChannel warningChannel =
            AndroidNotificationChannel(
          'vitalert_warning_channel',
          'Warning Patient Alerts',
          description:
              'Alerts for physiological parameter warnings and vital deviations.',
          importance: Importance.high,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          enableLights: true,
          ledColor: const Color(0xFFF59E0B),
          playSound: true,
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

  /// Evaluates alerts from Firebase and notifies ONLY for the single latest unacknowledged alert
  static void processLiveAlerts(List<AlertItem> alerts) {
    if (alerts.isEmpty) return;

    // Filter unacknowledged alerts (already sorted newest first in _parseAlerts)
    final unacknowledged = alerts.where((a) => !a.isAcknowledged).toList();

    // 1. On Initial App Launch: do not flood with all past alerts, only notify for the 1 latest active alert
    if (!_hasPerformedInitialSync) {
      _hasPerformedInitialSync = true;

      // Mark all existing alerts in the database as seen so old history is never spammed
      for (final a in alerts) {
        _notifiedAlertIds.add(a.id);
      }

      // If there is an active unacknowledged alert, only notify for the single latest one
      if (unacknowledged.isNotEmpty) {
        showAlertNotification(unacknowledged.first);
      }
      return;
    }

    // 2. During Real-Time Streaming: check for newly triggered unacknowledged alerts
    final newAlerts = unacknowledged
        .where((a) => !_notifiedAlertIds.contains(a.id))
        .toList();

    for (final a in alerts) {
      _notifiedAlertIds.add(a.id);
    }

    if (newAlerts.isNotEmpty) {
      // Only push the single latest newly triggered alert
      showAlertNotification(newAlerts.first);
    }
  }

  /// Displays the heads-up notification with screen wake
  static Future<void> showAlertNotification(AlertItem alert) async {
    final isCritical = alert.severity == AlertSeverity.critical;
    // Use patient ID hash so each patient has at most 1 active heads-up notification, replacing older alerts from that patient
    final id = alert.patientId.isNotEmpty
        ? alert.patientId.hashCode
        : _activeNotificationId;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      isCritical ? 'vitalert_critical_channel' : 'vitalert_warning_channel',
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

    await _notificationsPlugin.show(
      id,
      isCritical
          ? '🚨 CRITICAL: ${alert.patientName} (${alert.chairLocation})'
          : '⚠️ WARNING: ${alert.patientName} (${alert.chairLocation})',
      alert.message,
      details,
      payload: alert.patientId,
    );
  }

  static Future<void> dismissAlert(String alertId, {String? patientId}) async {
    await _notificationsPlugin.cancel(alertId.hashCode);
    if (patientId != null && patientId.isNotEmpty) {
      await _notificationsPlugin.cancel(patientId.hashCode);
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}

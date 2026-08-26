import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'alert_notification_service.dart';
import '../models/alert_item.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(VitalertTaskHandler());
}

class VitalertTaskHandler extends TaskHandler {
  static const String _databaseUrl = 'https://vitalert-app-default-rtdb.asia-southeast1.firebasedatabase.app';
  final Set<String> _knownAlertIds = {};
  bool _isFirstCheck = true;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('VitalertTaskHandler onStart');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      final res = await http.get(Uri.parse('$_databaseUrl/alerts.json')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body != 'null' && res.body.trim() != 'null') {
        final alertsRaw = Map<String, dynamic>.from(jsonDecode(res.body));
        final List<AlertItem> list = [];

        alertsRaw.forEach((key, val) {
          if (val is Map) {
            final map = Map<String, dynamic>.from(val);
            final sevStr = (map['severity'] ?? 'Warning').toString().toLowerCase();
            final severity = sevStr == 'critical'
                ? AlertSeverity.critical
                : (sevStr == 'warning' ? AlertSeverity.warning : AlertSeverity.info);
            final statusStr = (map['status'] ?? 'Active').toString();
            final isAcknowledged = statusStr.toLowerCase() == 'acknowledged';

            int? bpm;
            int? spo2;
            if (map['vitals'] is Map) {
              final vitals = Map<String, dynamic>.from(map['vitals']);
              bpm = (vitals['bpm'] as num?)?.toInt();
              spo2 = (vitals['spo2'] as num?)?.toInt();
            }

            list.add(
              AlertItem(
                id: key,
                patientId: map['patient_id'] ?? '',
                patientName: map['patient_name'] ?? 'Jane Doe',
                chairLocation: 'Chair ${map['chair'] ?? '2'}',
                wardArea: map['station'] ?? 'Station 2',
                severity: severity,
                title: severity == AlertSeverity.critical ? 'CRITICAL ALERT' : 'WARNING ALERT',
                message: map['message'] ?? '',
                timeString: map['triggered_at'] ?? '00:00',
                hrBpm: bpm,
                spO2: spo2,
                isAcknowledged: isAcknowledged,
                acknowledgedBy: map['acknowledged_by'],
                acknowledgedAt: map['acknowledged_at'],
                note: map['note'],
              ),
            );
          }
        });

        list.sort((a, b) => b.id.compareTo(a.id));

        final unacknowledged = list.where((a) => !a.isAcknowledged).toList();

        if (_isFirstCheck) {
          _isFirstCheck = false;
          for (final a in list) {
            _knownAlertIds.add(a.id);
          }
        } else {
          final newAlerts = unacknowledged.where((a) => !_knownAlertIds.contains(a.id)).toList();
          for (final a in list) {
            _knownAlertIds.add(a.id);
          }
          if (newAlerts.isNotEmpty) {
            // Trigger local push notification for the newest alert
            await AlertNotificationService.initialize();
            await AlertNotificationService.showAlertNotification(newAlerts.first);
          }
        }
      }
    } catch (e) {
      debugPrint('Background task polling error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('VitalertTaskHandler onDestroy');
  }
}

class ForegroundServiceManager {
  static bool _isRunning = false;

  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'vitalert_foreground_service',
        channelName: 'Vitalert Background Monitoring',
        channelDescription: 'Maintains real-time telemetry connection for clinical patient safety.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(3000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startService() async {
    if (_isRunning) return;

    if (await FlutterForegroundTask.isRunningService) {
      _isRunning = true;
      return;
    }

    final reqResult = await FlutterForegroundTask.requestNotificationPermission();
    if (reqResult == NotificationPermission.denied) {
      debugPrint('Foreground notification permission denied.');
    }

    final startRes = await FlutterForegroundTask.startService(
      notificationTitle: '🩺 Vitalert Clinical Monitor',
      notificationText: 'Live patient telemetry active (24/7 Safety)',
      callback: startCallback,
    );

    _isRunning = startRes is ServiceRequestSuccess;
    debugPrint('Foreground service started: $_isRunning');
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
    _isRunning = false;
  }
}

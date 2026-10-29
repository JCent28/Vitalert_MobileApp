import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'alert_audio_service.dart';
import 'alert_notification_service.dart';
import 'session_storage_service.dart';
import '../models/alert_item.dart';

@pragma('vm:entry-point')
void startCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(VitalertTaskHandler());
}

class VitalertTaskHandler extends TaskHandler {
  static const String _databaseUrl =
      'https://vitalert-dcd3f-default-rtdb.asia-southeast1.firebasedatabase.app';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('VitalertTaskHandler onStart');
    await AlertNotificationService.initialize(isBackgroundIsolate: true);
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // 1. Guard: Check if a logged-in nurse session exists.
    // If logged out or inactive, stop the background service immediately.
    final session = await SessionStorageService.loadSession();
    if (session == null || (session['status'] ?? '').toLowerCase() != 'active') {
      debugPrint('VitalertTaskHandler: No active nurse session. Stopping foreground service.');
      await ForegroundServiceManager.stopService();
      return;
    }

    // 2. Poll Firebase RTDB for alerts
    try {
      final res = await http
          .get(Uri.parse('$_databaseUrl/alerts.json'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body != 'null' && res.body.trim() != 'null') {
        final alertsRaw = Map<String, dynamic>.from(jsonDecode(res.body));
        final List<AlertItem> list = [];

        alertsRaw.forEach((key, val) {
          if (val is Map) {
            final map = Map<String, dynamic>.from(val);
            list.add(AlertItem.fromMap(key, map));
          }
        });

        // Delegate to unified AlertNotificationService with shared deduplication
        await AlertNotificationService.initialize(isBackgroundIsolate: true);
        await AlertNotificationService.processLiveAlerts(list);
      }
    } catch (e) {
      debugPrint('Background task polling error: $e');
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      if (data['type'] == 'alert_notified') {
        final id = data['id'];
        if (id is String && id.isNotEmpty) {
          AlertNotificationService.recordNotifiedIdInMemory(id);
        }
      } else if (data['type'] == 'trigger_test_alert') {
        final isCritical = data['isCritical'] == true;
        AlertNotificationService.initialize(isBackgroundIsolate: true).then((_) {
          AlertNotificationService.triggerTestAlertSound(isCritical: isCritical);
        });
      }
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
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'vitalert_foreground_service',
          channelName: 'Vitalert Background Monitoring',
          channelDescription:
              'Maintains real-time telemetry connection for clinical patient safety.',
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

      // Register callback for data sent from the background task isolate to the UI isolate
      FlutterForegroundTask.addTaskDataCallback((data) {
        if (data is Map && data['type'] == 'alert_notified') {
          final id = data['id'];
          if (id is String && id.isNotEmpty) {
            AlertNotificationService.recordNotifiedIdInMemory(id);
          }
          final severity = data['severity'];
          if (severity == 'critical') {
            AlertAudioService.playCriticalAlarm().catchError((e) {
              debugPrint('ForegroundServiceManager critical audio error: $e');
              return false;
            });
          } else if (severity == 'warning') {
            AlertAudioService.playWarningAlert().catchError((e) {
              debugPrint('ForegroundServiceManager warning audio error: $e');
              return false;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('ForegroundServiceManager init error: $e');
    }
  }

  static Future<void> startService() async {
    if (_isRunning) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        _isRunning = true;
        return;
      }

      final reqResult =
          await FlutterForegroundTask.requestNotificationPermission();
      if (reqResult == NotificationPermission.denied) {
        debugPrint('Foreground notification permission denied.');
      }

      // Check and prompt for battery optimization exemption on Android
      // to prevent Android Doze mode from deferring 3s telemetry polling.
      try {
        final isIgnoring =
            await FlutterForegroundTask.isIgnoringBatteryOptimizations;
        if (!isIgnoring) {
          debugPrint('Requesting battery optimization exemption for Doze mode...');
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      } catch (batteryErr) {
        debugPrint('Battery optimization request error: $batteryErr');
      }

      final startRes = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: '🩺 Vitalert Clinical Monitor',
        notificationText: 'Live patient telemetry active (24/7 Safety)',
        callback: startCallback,
      );

      _isRunning = startRes is ServiceRequestSuccess;
      debugPrint('Foreground service started: $_isRunning');
    } catch (e) {
      debugPrint('ForegroundServiceManager startService error: $e');
    }
  }

  /// Check whether battery optimization is ignored for VitAlert
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request ignore battery optimization dialog or settings
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      return await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  static Future<void> stopService() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('stopService error: $e');
    }
    _isRunning = false;
    debugPrint('Foreground service stopped.');
  }
}


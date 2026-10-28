import 'dart:async';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/alert_item.dart';
import '../models/device_model.dart';
import '../models/patient.dart';
import '../models/user_model.dart';
import 'vital_thresholds.dart';

class FirebaseRealtimeService {
  static const String databaseUrl =
      'https://vitalert-dcd3f-default-rtdb.asia-southeast1.firebasedatabase.app';

  Timer? _pollingTimer;
  final _patientsController = StreamController<List<Patient>>.broadcast();
  final _alertsController = StreamController<List<AlertItem>>.broadcast();
  final _devicesController = StreamController<List<DeviceModel>>.broadcast();

  Stream<List<Patient>> get patientsStream => _patientsController.stream;
  Stream<List<AlertItem>> get alertsStream => _alertsController.stream;
  Stream<List<DeviceModel>> get devicesStream => _devicesController.stream;

  bool _isSyncing = false;
  String? lastSessionError;
  String? lastAlertError;
  String? lastAuthError;

  final Map<String, _DeviceTelemetryTracker> _deviceTrackers = {};

  @visibleForTesting
  void simulateDeviceIdleForTesting(
    String patientId, {
    Duration? idleDuration,
    String? lastReceivedTime,
    int? lastBpm,
    int? lastSpO2,
    String? deviceUpdated,
  }) {
    final now = DateTime.now();
    final idleTime = now.subtract(idleDuration ?? const Duration(seconds: 65));
    final existing = _deviceTrackers[patientId];
    final bpm = lastBpm ?? existing?.lastBpm ?? 75;
    final spo2 = lastSpO2 ?? existing?.lastSpO2 ?? 98;
    final devUp = deviceUpdated ?? existing?.lastDeviceUpdated ?? lastReceivedTime ?? DateFormat('HH:mm:ss').format(idleTime);

    _deviceTrackers[patientId] = _DeviceTelemetryTracker(
      lastBpm: bpm,
      lastSpO2: spo2,
      lastDeviceUpdated: devUp,
      lastChangeTime: idleTime,
      lastReceivedFormatted: lastReceivedTime ?? DateFormat('HH:mm:ss').format(idleTime),
      isIdle: true,
    );
  }

  @visibleForTesting
  void clearDeviceTrackersForTesting() {
    _deviceTrackers.clear();
  }

  /// Normalizes chair identifiers for consistent comparison (e.g. "Chair 1" -> "1").
  static String normalizeChair(String chair) {
    final clean = chair.trim().toLowerCase();
    if (clean.isEmpty || clean == 'n/a' || clean == 'none' || clean == 'unknown') return '';
    return clean.replaceAll(RegExp(r'^chair\s*', caseSensitive: false), '').trim();
  }

  void startLiveSync({Duration interval = const Duration(seconds: 2)}) {
    _pollingTimer?.cancel();
    syncData();
    _pollingTimer = Timer.periodic(interval, (_) => syncData());
  }

  void stopLiveSync() {
    _pollingTimer?.cancel();
  }

  Future<void> syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final futures = await Future.wait([
        http.get(Uri.parse('$databaseUrl/devices.json')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('$databaseUrl/patients.json')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('$databaseUrl/alerts.json')).timeout(const Duration(seconds: 5)),
        http.get(Uri.parse('$databaseUrl/history.json')).timeout(const Duration(seconds: 5)),
      ]);

      final devicesRes = futures[0];
      final patientsRes = futures[1];
      final alertsRes = futures[2];
      final historyRes = futures[3];

      Map<String, dynamic> devicesMap = {};
      List<DeviceModel> devicesList = [];
      if (devicesRes.statusCode == 200 &&
          devicesRes.body != 'null' &&
          devicesRes.body.trim().isNotEmpty &&
          devicesRes.body.trim() != 'null') {
        try {
          final decoded = jsonDecode(devicesRes.body);
          if (decoded is Map) {
            devicesMap = Map<String, dynamic>.from(decoded);
            devicesMap.forEach((k, v) {
              if (v is Map) {
                devicesList.add(DeviceModel.fromMap(k, Map<String, dynamic>.from(v)));
              }
            });
            devicesList.sort((a, b) => a.deviceId.compareTo(b.deviceId));
          }
        } catch (_) {}
        _devicesController.add(devicesList);
      } else if (devicesRes.statusCode == 200) {
        _devicesController.add([]);
      }

      Map<String, dynamic> alertsRaw = {};
      List<AlertItem> parsedAlerts = [];
      if (alertsRes.statusCode == 200 &&
          alertsRes.body != 'null' &&
          alertsRes.body.trim().isNotEmpty &&
          alertsRes.body.trim() != 'null') {
        try {
          final decoded = jsonDecode(alertsRes.body);
          if (decoded is Map) {
            alertsRaw = Map<String, dynamic>.from(decoded);
            parsedAlerts = _parseAlerts(alertsRaw);
          }
        } catch (_) {}
        _alertsController.add(parsedAlerts);
      } else if (alertsRes.statusCode == 200) {
        _alertsController.add([]);
      }

      Map<String, dynamic> historyRaw = {};
      if (historyRes.statusCode == 200 &&
          historyRes.body != 'null' &&
          historyRes.body.trim().isNotEmpty &&
          historyRes.body.trim() != 'null') {
        try {
          final decoded = jsonDecode(historyRes.body);
          if (decoded is Map) {
            historyRaw = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      if (patientsRes.statusCode == 200 &&
          patientsRes.body != 'null' &&
          patientsRes.body.trim().isNotEmpty &&
          patientsRes.body.trim() != 'null') {
        List<Patient> parsedPatients = [];
        try {
          final decoded = jsonDecode(patientsRes.body);
          if (decoded is Map) {
            final patientsRaw = Map<String, dynamic>.from(decoded);
            parsedPatients = _parsePatients(
              patientsRaw: patientsRaw,
              devicesMap: devicesMap,
              alertsList: parsedAlerts,
              historyMap: historyRaw,
            );
          }
        } catch (_) {}
        _patientsController.add(parsedPatients);
      } else if (patientsRes.statusCode == 200) {
        _patientsController.add([]);
      }
    } catch (e) {
      debugPrint('Firebase RTDB Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  List<AlertItem> _parseAlerts(Map<String, dynamic> alertsRaw) {
    final List<AlertItem> list = [];

    alertsRaw.forEach((key, val) {
      if (val is Map) {
        final map = Map<String, dynamic>.from(val);
        list.add(AlertItem.fromMap(key, map));
      }
    });

    list.sort(AlertItem.compareNewestFirst);
    return list;
  }

  @visibleForTesting
  List<AlertItem> parseAlertsForTesting(Map<String, dynamic> alertsRaw) =>
      _parseAlerts(alertsRaw);

  @visibleForTesting
  List<Patient> parsePatientsForTesting({
    required Map<String, dynamic> patientsMap,
    required Map<String, dynamic> devicesMap,
    required List<AlertItem> alertsList,
    required Map<String, dynamic> historyMap,
  }) =>
      _parsePatients(
        patientsRaw: patientsMap,
        devicesMap: devicesMap,
        alertsList: alertsList,
        historyMap: historyMap,
      );

  List<Patient> _parsePatients({
    required Map<String, dynamic> patientsRaw,
    required Map<String, dynamic> devicesMap,
    required List<AlertItem> alertsList,
    required Map<String, dynamic> historyMap,
  }) {
    final List<Patient> list = [];

    patientsRaw.forEach((patientId, val) {
      if (val is Map) {
        final pData = Map<String, dynamic>.from(val);
        final rawDevice = pData['device']?.toString() ?? 'N/A';
        final hasNoDevice = rawDevice.isEmpty ||
            rawDevice.toUpperCase() == 'N/A' ||
            rawDevice.toLowerCase().contains('no device') ||
            rawDevice.startsWith('--');
        final deviceKey = hasNoDevice ? 'N/A' : rawDevice;

        final rawSession = pData['session']?.toString() ?? '1';
        final sessionNum = rawSession.replaceAll(RegExp(r'[^0-9]'), '');
        final displaySessionNum = sessionNum.isNotEmpty ? sessionNum : '1';

        int liveBpm = 0;
        int liveSpO2 = 0;
        if (!hasNoDevice && devicesMap.containsKey(deviceKey) && devicesMap[deviceKey] is Map) {
          final dev = Map<String, dynamic>.from(devicesMap[deviceKey]);
          liveBpm = (dev['bpm'] as num?)?.toInt() ?? 0;
          liveSpO2 = (dev['spo2'] as num?)?.toInt() ?? 0;
        }

        if (liveBpm == 0 && pData['final_vitals'] is Map) {
          final fVitals = Map<String, dynamic>.from(pData['final_vitals']);
          liveBpm = (fVitals['bpm'] as num?)?.toInt() ?? 0;
          liveSpO2 = (fVitals['spo2'] as num?)?.toInt() ?? 0;
        }

        if (liveBpm == 0 && pData['bpm'] != null) {
          liveBpm = (pData['bpm'] as num?)?.toInt() ?? 0;
        } else if (liveBpm == 0 && pData['current_hr'] != null) {
          liveBpm = (pData['current_hr'] as num?)?.toInt() ?? 0;
        }

        if (liveSpO2 == 0 && pData['spo2'] != null) {
          liveSpO2 = (pData['spo2'] as num?)?.toInt() ?? 0;
        } else if (liveSpO2 == 0 && pData['current_spo2'] != null) {
          liveSpO2 = (pData['current_spo2'] as num?)?.toInt() ?? 0;
        }

        List<double> hrHistory = [];
        List<double> spO2History = [];
        List<PatientReading> recentReadings = [];
        List<PatientLogEvent> patientAlertEvents = [];
        List<PatientSessionHistory> sessionHistories = [];

        // Session history is permanent data — load it regardless of whether
        // a device is currently attached. Only live telemetry needs hasNoDevice.
        if (historyMap.containsKey(patientId) && historyMap[patientId] is Map) {
          final pHistory = Map<String, dynamic>.from(historyMap[patientId]);
          // Sort numerically so session_10 comes after session_9, not before session_2
          final sessionKeys = pHistory.keys.toList()
            ..sort((a, b) {
              final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return aNum.compareTo(bNum);
            });
          for (final sKey in sessionKeys) {
            final sVal = pHistory[sKey];
            if (sVal is Map) {
              final sMap = Map<String, dynamic>.from(sVal);
              final cleanNum = sKey.replaceAll(RegExp(r'[^0-9]'), '');
              final sNum = cleanNum.isNotEmpty ? cleanNum : sKey;
              final sMeta = sMap['meta'] is Map ? Map<String, dynamic>.from(sMap['meta'] as Map) : null;
              List<double> sHrHist = [];
              List<double> sSpO2Hist = [];
              List<PatientReading> sReadings = [];

              if (sMap['readings'] is Map) {
                final rMap = Map<String, dynamic>.from(sMap['readings']);
                final rKeys = rMap.keys.toList()..sort();
                for (final rKey in rKeys) {
                  final rVal = rMap[rKey];
                  if (rVal is Map) {
                    final r = Map<String, dynamic>.from(rVal);
                    final b = (r['bpm'] as num?)?.toInt() ?? 75;
                    final s = (r['spo2'] as num?)?.toInt() ?? 98;
                    sHrHist.add(b.toDouble());
                    sSpO2Hist.add(s.toDouble());

                    final rSevStr = (r['status'] ?? 'Normal').toString().toLowerCase();
                    final rSeverity = rSevStr == 'critical'
                        ? AlertSeverity.critical
                        : (rSevStr == 'warning' ? AlertSeverity.warning : AlertSeverity.info);

                    final remarkVal = r['remarks']?.toString() ?? r['remark']?.toString() ?? '';
                    final timestampVal = r['timestamp']?.toString() ?? '';

                    sReadings.add(
                      PatientReading(
                        id: rKey,
                        time: r['time'] ?? '00:00',
                        duration: r['duration'] ?? '1m',
                        hrBpm: b,
                        spO2: s,
                        status: (r['status'] ?? 'Normal').toString().toUpperCase(),
                        severity: rSeverity,
                        remark: remarkVal,
                        timestamp: timestampVal,
                      ),
                    );
                  }
                }
              }

              final sHighHr = sHrHist.isNotEmpty ? sHrHist.reduce((a, b) => a > b ? a : b).toInt() : 0;
              final sLowHr = sHrHist.isNotEmpty ? sHrHist.reduce((a, b) => a < b ? a : b).toInt() : 0;
              final sAvgHr = sHrHist.isNotEmpty ? sHrHist.reduce((a, b) => a + b) / sHrHist.length : 0.0;

              final sHighSpO2 = sSpO2Hist.isNotEmpty ? sSpO2Hist.reduce((a, b) => a > b ? a : b).toInt() : 0;
              final sLowSpO2 = sSpO2Hist.isNotEmpty ? sSpO2Hist.reduce((a, b) => a < b ? a : b).toInt() : 0;
              final sAvgSpO2 = sSpO2Hist.isNotEmpty ? sSpO2Hist.reduce((a, b) => a + b) / sSpO2Hist.length : 0.0;

              String sStartTime = '--';
              if (sReadings.isNotEmpty) {
                sStartTime = sReadings.first.time;
              } else if (sMeta != null && sMeta['started_at'] != null) {
                final raw = sMeta['started_at'].toString();
                try {
                  final dt = DateTime.parse(raw);
                  sStartTime = DateFormat('HH:mm').format(dt.toLocal());
                } catch (_) {
                  if (raw.contains(' ') && raw.split(' ').last.length >= 5) {
                    sStartTime = raw.split(' ').last.substring(0, 5);
                  } else {
                    sStartTime = raw;
                  }
                }
              }

              String sDuration = '--';
              if (sReadings.isNotEmpty) {
                sDuration = sReadings.last.duration;
              } else if (sMeta != null) {
                if (sMeta['active_seconds'] != null) {
                  final sec = (sMeta['active_seconds'] as num).toInt();
                  final min = sec ~/ 60;
                  sDuration = min >= 60 ? '${min ~/ 60}h ${min % 60}m' : '${min}m';
                } else if (sMeta['started_at'] != null) {
                  try {
                    final dt = DateTime.parse(sMeta['started_at'].toString());
                    final diff = DateTime.now().difference(dt.toLocal());
                    final min = diff.inMinutes;
                    if (min >= 0) {
                      sDuration = min >= 60 ? '${min ~/ 60}h ${min % 60}m' : '${min}m';
                    }
                  } catch (_) {
                    sDuration = '0m';
                  }
                }
              }

              String sDate = '';
              if (sMap['date'] != null &&
                  sMap['date'].toString().trim().isNotEmpty &&
                  !sMap['date'].toString().contains('August 21, 2026') &&
                  !sMap['date'].toString().contains('Aug 21, 2026')) {
                sDate = sMap['date'].toString().trim();
              } else if (sMap['created_at'] != null && sMap['created_at'].toString().isNotEmpty) {
                try {
                  final dt = DateTime.parse(sMap['created_at'].toString()).toLocal();
                  sDate = DateFormat('MMM d, yyyy').format(dt);
                } catch (_) {}
              } else if (sMeta != null && sMeta['started_at'] != null && sMeta['started_at'].toString().isNotEmpty) {
                try {
                  final dt = DateTime.parse(sMeta['started_at'].toString()).toLocal();
                  sDate = DateFormat('MMM d, yyyy').format(dt);
                } catch (_) {}
              }
              if (sDate.isEmpty && sReadings.isNotEmpty) {
                for (final r in sReadings) {
                  if (r.timestamp.isNotEmpty) {
                    try {
                      final dt = DateTime.parse(r.timestamp).toLocal();
                      sDate = DateFormat('MMM d, yyyy').format(dt);
                      break;
                    } catch (_) {}
                  }
                }
              }
              if (sDate.isEmpty) {
                sDate = DateFormat('MMM d, yyyy').format(DateTime.now());
              }

              sessionHistories.add(
                PatientSessionHistory(
                  sessionNumber: sNum,
                  sessionTitle: 'Session $sNum',
                  startTime: sStartTime,
                  duration: sDuration,
                  date: sDate,
                  highestHr: sHighHr,
                  lowestHr: sLowHr,
                  avgHr: sAvgHr,
                  highestSpO2: sHighSpO2,
                  lowestSpO2: sLowSpO2,
                  avgSpO2: sAvgSpO2,
                  hrHistory: sHrHist,
                  spO2History: sSpO2Hist,
                  readings: sReadings.reversed.toList(),
                ),
              );
            }
          }

          final sessionKey = 'session_$displaySessionNum';
          final sessionData = pHistory[sessionKey] ?? (pHistory.values.isNotEmpty ? pHistory.values.first : null);

          if (sessionData is Map && sessionData['readings'] is Map) {
            final readingsMap = Map<String, dynamic>.from(sessionData['readings']);
            final sortedKeys = readingsMap.keys.toList()..sort();
            for (final rKey in sortedKeys) {
              final rVal = readingsMap[rKey];
              if (rVal is Map) {
                final r = Map<String, dynamic>.from(rVal);
                final b = (r['bpm'] as num?)?.toInt() ?? 75;
                final s = (r['spo2'] as num?)?.toInt() ?? 98;
                hrHistory.add(b.toDouble());
                spO2History.add(s.toDouble());

                final rSevStr = (r['status'] ?? 'Normal').toString().toLowerCase();
                final rSeverity = rSevStr == 'critical'
                    ? AlertSeverity.critical
                    : (rSevStr == 'warning' ? AlertSeverity.warning : AlertSeverity.info);

                final remarkVal = r['remarks']?.toString() ?? r['remark']?.toString() ?? '';
                final timestampVal = r['timestamp']?.toString() ?? '';

                recentReadings.add(
                  PatientReading(
                    id: rKey,
                    time: r['time'] ?? '00:00',
                    duration: r['duration'] ?? '1m',
                    hrBpm: b,
                    spO2: s,
                    status: (r['status'] ?? 'Normal').toString().toUpperCase(),
                    severity: rSeverity,
                    remark: remarkVal,
                    timestamp: timestampVal,
                  ),
                );
              }
            }
          }
        }

        if (liveBpm == 0 && recentReadings.isNotEmpty) {
          liveBpm = recentReadings.last.hrBpm;
        } else if (liveBpm == 0 && hrHistory.isNotEmpty) {
          liveBpm = hrHistory.last.toInt();
        } else if (liveBpm == 0 && sessionHistories.isNotEmpty) {
          for (final sh in sessionHistories.reversed) {
            if (sh.readings.isNotEmpty) {
              liveBpm = sh.readings.first.hrBpm;
              break;
            }
          }
        }

        if (liveSpO2 == 0 && recentReadings.isNotEmpty) {
          liveSpO2 = recentReadings.last.spO2;
        } else if (liveSpO2 == 0 && spO2History.isNotEmpty) {
          liveSpO2 = spO2History.last.toInt();
        } else if (liveSpO2 == 0 && sessionHistories.isNotEmpty) {
          for (final sh in sessionHistories.reversed) {
            if (sh.readings.isNotEmpty) {
              liveSpO2 = sh.readings.first.spO2;
              break;
            }
          }
        }

        final highestHr = hrHistory.isNotEmpty ? hrHistory.reduce((a, b) => a > b ? a : b).toInt() : liveBpm;
        final lowestHr = hrHistory.isNotEmpty ? hrHistory.reduce((a, b) => a < b ? a : b).toInt() : liveBpm;
        final avgHr = hrHistory.isNotEmpty ? hrHistory.reduce((a, b) => a + b) / hrHistory.length : liveBpm.toDouble();

        final highestSpO2 = spO2History.isNotEmpty ? spO2History.reduce((a, b) => a > b ? a : b).toInt() : liveSpO2;
        final lowestSpO2 = spO2History.isNotEmpty ? spO2History.reduce((a, b) => a < b ? a : b).toInt() : liveSpO2;
        final avgSpO2 = spO2History.isNotEmpty ? spO2History.reduce((a, b) => a + b) / spO2History.length : liveSpO2.toDouble();

        final rawStatus = (pData['status'] ?? 'Waiting').toString();
        final isExplicitIdle = rawStatus.toLowerCase().contains('idle') ||
            pData['is_idle'] == true ||
            pData['device_idle'] == true;

        String sessionStatus = 'Waiting';
        if (isExplicitIdle) {
          sessionStatus = 'Waiting';
        } else if (rawStatus.toLowerCase() == 'ongoing') {
          sessionStatus = 'Ongoing';
        } else if (rawStatus.toLowerCase() == 'completed') {
          sessionStatus = 'Completed';
        } else if (rawStatus.toLowerCase() == 'inactive') {
          sessionStatus = 'Inactive';
        } else {
          sessionStatus = 'Waiting';
        }

        if (!sessionHistories.any((s) => s.sessionNumber == displaySessionNum)) {
          final fallbackStart = recentReadings.isNotEmpty
              ? recentReadings.first.time
              : (pData['start_time'] != null && pData['start_time'].toString().isNotEmpty && pData['start_time'] != '--'
                  ? pData['start_time'].toString()
                  : '--');
          final fallbackDuration = recentReadings.isNotEmpty
              ? recentReadings.last.duration
              : (pData['duration'] != null && pData['duration'].toString().isNotEmpty
                  ? pData['duration'].toString()
                  : (sessionStatus == 'Ongoing' ? '0m' : '--'));

          sessionHistories.add(
            PatientSessionHistory(
              sessionNumber: displaySessionNum,
              sessionTitle: 'Session $displaySessionNum',
              startTime: fallbackStart,
              duration: fallbackDuration,
              date: DateFormat('MMM d, yyyy').format(DateTime.now()),
              highestHr: highestHr,
              lowestHr: lowestHr,
              avgHr: avgHr,
              highestSpO2: highestSpO2,
              lowestSpO2: lowestSpO2,
              avgSpO2: avgSpO2,
              hrHistory: hrHistory,
              spO2History: spO2History,
              readings: recentReadings.reversed.toList(),
            ),
          );
        }

        sessionHistories.sort((a, b) {
          final aNum = int.tryParse(a.sessionNumber) ?? 0;
          final bNum = int.tryParse(b.sessionNumber) ?? 0;
          return aNum.compareTo(bNum);
        });

        final pAlerts = alertsList.where((a) => a.patientId == patientId).toList();
        for (final al in pAlerts) {
          patientAlertEvents.add(
            PatientLogEvent(
              time: al.timeString,
              severity: al.severity,
              hrBpm: al.hrBpm ?? 0,
              spO2: al.spO2 ?? 0,
              description: al.message,
              acknowledgementNote: al.isAcknowledged
                  ? 'Acknowledged by ${al.acknowledgedBy ?? "Nurse"} at ${al.acknowledgedAt ?? al.timeString}'
                  : null,
            ),
          );
        }

        // Inactivity Heartbeat Tracking
        bool isDeviceIdle = isExplicitIdle;
        String? lastReceivedTimestamp;
        DateTime? lastReceivedAt;

        if (isExplicitIdle) {
          sessionStatus = 'Waiting';
          if (pData['last_received'] != null) {
            lastReceivedTimestamp = pData['last_received'].toString();
          }
        }

        String devLastUpdated = '';
        if (!hasNoDevice && devicesMap.containsKey(deviceKey) && devicesMap[deviceKey] is Map) {
          final dev = Map<String, dynamic>.from(devicesMap[deviceKey]);
          devLastUpdated = dev['last_updated']?.toString() ?? '';
        }

        final isReceivingLiveData = !hasNoDevice && liveBpm > 0 && liveSpO2 > 0;
        final trackerKey = patientId;

        if (!hasNoDevice && (liveBpm > 0 || liveSpO2 > 0 || sessionStatus == 'Ongoing')) {
          final now = DateTime.now();
          final tracker = _deviceTrackers[trackerKey];

          if (tracker == null) {
            final formattedNow = devLastUpdated.isNotEmpty && devLastUpdated != '--'
                ? devLastUpdated
                : DateFormat('HH:mm:ss').format(now);
            _deviceTrackers[trackerKey] = _DeviceTelemetryTracker(
              lastBpm: liveBpm,
              lastSpO2: liveSpO2,
              lastDeviceUpdated: devLastUpdated,
              lastChangeTime: now,
              lastReceivedFormatted: formattedNow,
              isIdle: isExplicitIdle,
            );
            lastReceivedTimestamp = formattedNow;
            lastReceivedAt = now;
          } else {
            final hasVitalsChanged = (liveBpm != tracker.lastBpm || liveSpO2 != tracker.lastSpO2) && (liveBpm > 0 && liveSpO2 > 0);
            final hasTimestampChanged = devLastUpdated.isNotEmpty && devLastUpdated != '--' && devLastUpdated != tracker.lastDeviceUpdated;

            if (hasVitalsChanged || hasTimestampChanged) {
              // Active reading changes received!
              tracker.lastBpm = liveBpm;
              tracker.lastSpO2 = liveSpO2;
              tracker.lastDeviceUpdated = devLastUpdated;
              tracker.lastChangeTime = now;
              tracker.lastReceivedFormatted = devLastUpdated.isNotEmpty && devLastUpdated != '--'
                  ? devLastUpdated
                  : DateFormat('HH:mm:ss').format(now);
              tracker.isIdle = false;
              isDeviceIdle = false;
            } else {
              // No reading changes — check inactivity timeout (1 minute)
              final idleDiff = now.difference(tracker.lastChangeTime);
              if (idleDiff >= const Duration(minutes: 1)) {
                tracker.isIdle = true;
              }
            }

            if (tracker.isIdle) {
              isDeviceIdle = true;
              lastReceivedTimestamp = tracker.lastReceivedFormatted;
              lastReceivedAt = tracker.lastChangeTime;
              if (sessionStatus == 'Ongoing') {
                sessionStatus = 'Waiting';
                // Sync session move to Waiting in Firebase
                http.patch(
                  Uri.parse('$databaseUrl/patients/$patientId.json'),
                  body: '{"status":"Waiting"}',
                ).catchError((_) => http.Response('', 500));
              }
            } else {
              lastReceivedTimestamp = tracker.lastReceivedFormatted;
              lastReceivedAt = tracker.lastChangeTime;
            }
          }
        }

        // Auto-promote to Ongoing when device sends fresh readings and is NOT idle
        if (isReceivingLiveData && sessionStatus == 'Waiting' && !isDeviceIdle) {
          sessionStatus = 'Ongoing';
          http.patch(
            Uri.parse('$databaseUrl/patients/$patientId.json'),
            body: '{"status":"Ongoing"}',
          ).catchError((_) => http.Response('', 500));
        }

        final overallStatus = (liveBpm > 0 && liveSpO2 > 0)
            ? VitalThresholds.evaluateVitals(liveBpm, liveSpO2)
            : AlertSeverity.info;

        String lastUpdatedTime = '--';
        if (pData['final_vitals'] is Map && pData['final_vitals']['last_updated'] != null) {
          final rawTime = pData['final_vitals']['last_updated'].toString();
          if (rawTime.contains(' ') && rawTime.split(' ').last.length >= 5) {
            lastUpdatedTime = rawTime.split(' ').last.substring(0, 5);
          } else {
            lastUpdatedTime = rawTime;
          }
        } else if (recentReadings.isNotEmpty) {
          lastUpdatedTime = recentReadings.first.time;
        } else if (pData['last_updated'] != null && pData['last_updated'].toString().isNotEmpty && pData['last_updated'] != '--') {
          lastUpdatedTime = pData['last_updated'].toString();
        } else if (!hasNoDevice && devicesMap.containsKey(deviceKey) && devicesMap[deviceKey] is Map) {
          final dev = Map<String, dynamic>.from(devicesMap[deviceKey]);
          if (dev['last_updated'] != null && dev['last_updated'].toString().isNotEmpty && dev['last_updated'] != '--') {
            lastUpdatedTime = dev['last_updated'].toString();
          }
        } else if (sessionHistories.isNotEmpty) {
          for (final sh in sessionHistories.reversed) {
            if (sh.startTime != '--' && sh.startTime.isNotEmpty) {
              lastUpdatedTime = sh.startTime;
              break;
            }
          }
        }
        if (lastUpdatedTime == '--' && sessionStatus == 'Ongoing' && pData['start_time'] != null && pData['start_time'].toString().isNotEmpty && pData['start_time'] != '--') {
          lastUpdatedTime = pData['start_time'].toString();
        }

        String durationStr = recentReadings.isNotEmpty
            ? recentReadings.first.duration
            : (pData['duration'] != null && pData['duration'].toString().isNotEmpty ? pData['duration'].toString() : '--');
        if (durationStr == '--' && sessionStatus == 'Ongoing') {
          final currSh = sessionHistories.where((s) => s.sessionNumber == displaySessionNum).firstOrNull;
          if (currSh != null && currSh.duration != '--') {
            durationStr = currSh.duration;
          } else {
            durationStr = '0m';
          }
        }

        final rawName = pData['name']?.toString().trim();
        final name = (rawName != null && rawName.isNotEmpty) ? rawName : 'Unknown Patient';
        final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();

        String patientDate = '';
        if (pData['date'] != null &&
            pData['date'].toString().trim().isNotEmpty &&
            !pData['date'].toString().contains('August 21, 2026') &&
            !pData['date'].toString().contains('Aug 21, 2026')) {
          patientDate = pData['date'].toString().trim();
        } else if (pData['created_at'] != null && pData['created_at'].toString().isNotEmpty) {
          try {
            final dt = DateTime.parse(pData['created_at'].toString()).toLocal();
            patientDate = DateFormat('EEEE, MMMM d, yyyy').format(dt);
          } catch (_) {}
        }
        if (patientDate.isEmpty) {
          patientDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
        }

        final nurseName = (pData['primary_nurse'] ??
                pData['nurse'] ??
                pData['attending_nurse'] ??
                pData['nurse_name'] ??
                pData['staff_name'] ??
                '--')
            .toString()
            .trim();

        list.add(
          Patient(
            id: patientId,
            name: name,
            mrn: '#${patientId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0').substring(0, 6)}',
            initials: initials.isNotEmpty ? initials : '--',
            chair: pData['chair']?.toString() ?? '1',
            department: 'NephroAsia Dialysis Bay',
            session: 'Session $displaySessionNum',
            deviceId: deviceKey,
            date: patientDate,
            startTime: lastUpdatedTime,
            primaryNurse: nurseName.isNotEmpty ? nurseName : '--',
            duration: durationStr,
            sessionStatus: sessionStatus,
            status: overallStatus,
            currentHr: liveBpm,
            currentSpO2: liveSpO2,
            highestHr: highestHr,
            lowestHr: lowestHr,
            avgHr: avgHr,
            highestSpO2: highestSpO2,
            lowestSpO2: lowestSpO2,
            avgSpO2: avgSpO2,
            hrHistory: hrHistory.isNotEmpty ? hrHistory : (liveBpm > 0 ? [liveBpm.toDouble()] : []),
            spO2History: spO2History.isNotEmpty ? spO2History : (liveSpO2 > 0 ? [liveSpO2.toDouble()] : []),
            recentReadings: recentReadings.reversed.toList(),
            alertEvents: patientAlertEvents,
            sessionHistories: sessionHistories,
            isDeviceIdle: isDeviceIdle,
            lastReceivedTimestamp: lastReceivedTimestamp,
            lastReceivedAt: lastReceivedAt,
          ),
        );
      }
    });

    return list;
  }

  // 1. Authenticate Staff against /users node
  Future<UserModel?> authenticateStaff({
    required String staffId,
    required String password,
    String? selectedRole,
    http.Client? client,
  }) async {
    lastAuthError = null;
    try {
      final getFn = client != null ? client.get : http.get;
      final cleanStaffId = staffId.trim();
      final res = await getFn(Uri.parse('$databaseUrl/users/$cleanStaffId.json'));

      if (res.statusCode != 200 || res.body == 'null' || res.body.trim().isEmpty) {
        lastAuthError = 'Staff ID not found. Please verify your credentials.';
        debugPrint('authenticateStaff failed: Staff ID $cleanStaffId not found');
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is! Map) {
        lastAuthError = 'Invalid user record format from database.';
        debugPrint('authenticateStaff failed: Invalid record format');
        return null;
      }

      // 1. Account status validation (Active vs Inactive/Deactivated)
      final status = (data['status'] ?? 'Active').toString().trim();
      if (status.toLowerCase() != 'active') {
        lastAuthError = 'Account is deactivated. Please contact your administrator.';
        debugPrint('authenticateStaff rejected: Account $cleanStaffId is deactivated (status: $status)');
        return null;
      }

      // 2. Password verification with BCrypt
      final storedPass = (data['password'] ?? '').toString();
      bool passwordValid = false;

      if (storedPass.startsWith(r'$2')) {
        try {
          passwordValid = BCrypt.checkpw(password, storedPass);
        } catch (_) {
          try {
            // Attempt normalizing $2y$ prefix to $2a$ if needed
            final normalized = storedPass.replaceFirst(r'$2y$', r'$2a$');
            passwordValid = BCrypt.checkpw(password, normalized);
          } catch (_) {
            passwordValid = false;
          }
        }
      } else {
        // Fallback for legacy unhashed dev/test accounts
        passwordValid = storedPass.isNotEmpty && storedPass == password;
      }

      if (!passwordValid) {
        lastAuthError = 'Invalid password. Please verify your credentials.';
        debugPrint('authenticateStaff rejected: Invalid password for $cleanStaffId');
        return null;
      }

      // 3. Role validation and clinical authorization check
      final accountRole = (data['role'] ?? 'Staff Nurse').toString().trim();
      if (!_isRoleAuthorized(accountRole)) {
        lastAuthError = 'Unauthorized role: $accountRole is not permitted to access the nurse station.';
        debugPrint('authenticateStaff rejected: Role $accountRole is unauthorized');
        return null;
      }

      if (selectedRole != null && selectedRole.trim().isNotEmpty) {
        if (!_isRoleCompatible(selectedRole.trim(), accountRole)) {
          lastAuthError = 'Role mismatch: Account is registered as $accountRole, but $selectedRole was selected.';
          debugPrint('authenticateStaff rejected: Selected role ($selectedRole) does not match account role ($accountRole)');
          return null;
        }
      }

      return UserModel(
        staffId: data['staff_id']?.toString() ?? cleanStaffId,
        name: data['name']?.toString() ?? 'Staff Member',
        role: accountRole,
        status: status,
        createdAt: data['created_at']?.toString() ?? '',
      );
    } catch (e) {
      lastAuthError = 'Authentication service error: $e';
      debugPrint('RTDB Auth error: $e');
      return null;
    }
  }

  /// Determines whether a database role is authorized for clinical application access.
  bool _isRoleAuthorized(String role) {
    final r = role.toLowerCase();
    return r.contains('head nurse') ||
        r.contains('staff nurse') ||
        r == 'admin';
  }

  /// Verifies that the user-selected login role is compatible with their actual account role.
  bool _isRoleCompatible(String selectedRole, String accountRole) {
    final s = selectedRole.toLowerCase();
    final a = accountRole.toLowerCase();

    // Admin has super-access across nurse station roles
    if (a == 'admin') return true;

    if (s.contains('head nurse') && a.contains('head nurse')) return true;
    if (s.contains('staff nurse') && a.contains('staff nurse')) return true;
    if (s == a) return true;

    return false;
  }

  // 2. Add New Patient to Firebase RTDB
  Future<bool> addPatient({
    required String name,
    required String chair,
    required String session,
    required String deviceId,
    int? bpm,
    int? spo2,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final body = <String, dynamic>{
        'name': name,
        'chair': chair,
        'session': session.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
            ? session.replaceAll(RegExp(r'[^0-9]'), '')
            : '1',
        'device': deviceId.isEmpty ? 'N/A' : deviceId,
        'status': 'Waiting',
        'created_at': now,
        'snapshot_interval': 1,
        'stream_interval': 1,
      };
      if (bpm != null) body['bpm'] = bpm;
      if (spo2 != null) body['spo2'] = spo2;

      final res = await http.post(
        Uri.parse('$databaseUrl/patients.json'),
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        if (deviceId.isNotEmpty && deviceId != 'N/A') {
          await http.patch(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({'status': 'IN_USE'}),
          );
        }
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('addPatient error: $e');
      return false;
    }
  }

  // 3. Update Patient in Firebase RTDB
  Future<bool> updatePatient(
    String patientId, {
    String? name,
    String? chair,
    String? session,
    String? deviceId,
    String? status,
  }) async {
    try {
      final patch = <String, dynamic>{};
      if (name != null) patch['name'] = name;
      if (chair != null) patch['chair'] = chair;
      if (session != null) patch['session'] = session.replaceAll(RegExp(r'[^0-9]'), '');
      if (deviceId != null) patch['device'] = deviceId;
      if (status != null) patch['status'] = status;

      if (patch.isEmpty) return true;

      final res = await http.patch(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
        body: jsonEncode(patch),
      );

      if (res.statusCode == 200) {
        if (deviceId != null && deviceId.isNotEmpty && deviceId != 'N/A') {
          await http.patch(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({'status': 'IN_USE'}),
          );
        }
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('updatePatient error: $e');
      return false;
    }
  }

  // 4. Start Dialysis Session in Firebase RTDB
  Future<bool> startSession({
    required String patientId,
    required String sessionNum,
    required String deviceId,
    http.Client? client,
  }) async {
    try {
      lastSessionError = null;

      final getFn = client != null ? client.get : http.get;
      final putFn = client != null ? client.put : http.put;
      final patchFn = client != null ? client.patch : http.patch;

      // 1. Fetch current patients data to validate chair and device availability
      final patientsRes = await getFn(
        Uri.parse('$databaseUrl/patients.json'),
      ).timeout(const Duration(seconds: 5));
      if (patientsRes.statusCode != 200 || patientsRes.body == 'null' || patientsRes.body.trim().isEmpty) {
        lastSessionError = 'Failed to load clinic patients to verify availability.';
        debugPrint('startSession error: $lastSessionError');
        return false;
      }

      final decodedPatients = jsonDecode(patientsRes.body);
      if (decodedPatients is! Map) {
        lastSessionError = 'Invalid patients database format.';
        debugPrint('startSession error: $lastSessionError');
        return false;
      }
      final patientsMap = Map<String, dynamic>.from(decodedPatients);

      final patientData = patientsMap[patientId];
      if (patientData is! Map) {
        lastSessionError = 'Patient $patientId not found in database.';
        debugPrint('startSession error: $lastSessionError');
        return false;
      }
      final pMap = Map<String, dynamic>.from(patientData);
      final patientChair = (pMap['chair'] ?? '').toString();
      final targetNormalizedChair = normalizeChair(patientChair);

      // 2. Validate Chair Availability
      if (targetNormalizedChair.isNotEmpty) {
        for (final entry in patientsMap.entries) {
          if (entry.key == patientId) continue;
          if (entry.value is Map) {
            final other = Map<String, dynamic>.from(entry.value as Map);
            final otherStatus = (other['status'] ?? '').toString().toLowerCase();
            final otherChair = (other['chair'] ?? '').toString();
            if (otherStatus == 'ongoing' && normalizeChair(otherChair) == targetNormalizedChair) {
              final otherName = other['name'] ?? 'Another patient';
              lastSessionError = 'Chair $patientChair is occupied by $otherName (Ongoing session).';
              debugPrint('startSession rejected: $lastSessionError');
              return false;
            }
          }
        }
      }

      // 3. Validate Device Availability
      final isPhysical = deviceId.isNotEmpty && deviceId != 'N/A';
      if (isPhysical) {
        // Check if device is marked IN_USE in /devices node
        final devRes = await getFn(
          Uri.parse('$databaseUrl/devices/$deviceId.json'),
        ).timeout(const Duration(seconds: 5));
        if (devRes.statusCode == 200 && devRes.body != 'null' && devRes.body.trim().isNotEmpty) {
          final devDecoded = jsonDecode(devRes.body);
          if (devDecoded is Map) {
            final devMap = Map<String, dynamic>.from(devDecoded);
            final devStatus = (devMap['status'] ?? '').toString().toUpperCase();
            if (devStatus == 'IN_USE') {
              lastSessionError = 'Device $deviceId is currently in use.';
              debugPrint('startSession rejected: $lastSessionError');
              return false;
            }
          }
        }

        // Also verify no other ongoing patient is currently assigned this device
        for (final entry in patientsMap.entries) {
          if (entry.key == patientId) continue;
          if (entry.value is Map) {
            final other = Map<String, dynamic>.from(entry.value as Map);
            final otherStatus = (other['status'] ?? '').toString().toLowerCase();
            final otherDevice = (other['device'] ?? '').toString();
            if (otherStatus == 'ongoing' && otherDevice == deviceId) {
              final otherName = other['name'] ?? 'Another patient';
              lastSessionError = 'Device $deviceId is already assigned to $otherName (Ongoing session).';
              debugPrint('startSession rejected: $lastSessionError');
              return false;
            }
          }
        }
      }

      // 4. Prepare session identifiers and timestamps
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final fullTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final formattedSession = sessionNum.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
          ? sessionNum.replaceAll(RegExp(r'[^0-9]'), '')
          : '1';
      final sessionKey = 'session_$formattedSession';

      // 5. Write history/.../meta node with all required parameters
      final metaData = <String, dynamic>{
        'started_at': fullTimestamp,
        'interval_minutes': 1,
        'stream_interval': 1,
        'source_type': isPhysical ? 'actual' : 'simulation',
        'mode': 'random',
        'active_seconds': 0,
      };

      await putFn(
        Uri.parse('$databaseUrl/history/$patientId/$sessionKey/meta.json'),
        body: jsonEncode(metaData),
      );

      // 6. Update patient status to 'Ongoing' (matching web app)
      final patientPatch = <String, dynamic>{
        'session': formattedSession,
        'device': isPhysical ? deviceId : 'N/A',
        'status': 'Ongoing',
        'last_updated': fullTimestamp,
        'start_time': timeStr,
        'snapshot_interval': 1,
        'stream_interval': 1,
      };

      final res = await patchFn(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
        body: jsonEncode(patientPatch),
      );

      if (res.statusCode == 200) {
        if (isPhysical) {
          await patchFn(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({
              'status': 'IN_USE',
              'last_updated': fullTimestamp,
            }),
          );
        }
        syncData();
        return true;
      }
      lastSessionError = 'Failed to update patient node in database (status ${res.statusCode}).';
      return false;
    } catch (e) {
      lastSessionError = 'startSession error: $e';
      debugPrint('startSession error: $e');
      return false;
    }
  }

  // 5. End Dialysis Session in Firebase RTDB
  Future<bool> endSession({
    required String patientId,
    required String deviceId,
    http.Client? client,
  }) async {
    try {
      final getFn = client != null ? client.get : http.get;
      final patchFn = client != null ? client.patch : http.patch;

      String targetDeviceId = deviceId;
      int finalBpm = 0;
      int finalSpo2 = 0;

      // 1. Fetch current patient data to determine device and vitals
      try {
        final pRes = await getFn(Uri.parse('$databaseUrl/patients/$patientId.json'))
            .timeout(const Duration(seconds: 5));
        if (pRes.statusCode == 200 && pRes.body != 'null' && pRes.body.trim().isNotEmpty) {
          final decoded = jsonDecode(pRes.body);
          if (decoded is Map) {
            final pMap = Map<String, dynamic>.from(decoded);
            finalBpm = (pMap['bpm'] as num?)?.toInt() ?? 0;
            finalSpo2 = (pMap['spo2'] as num?)?.toInt() ?? 0;
            if (targetDeviceId.isEmpty || targetDeviceId == 'N/A') {
              final storedDev = pMap['device']?.toString() ?? '';
              if (storedDev.isNotEmpty && storedDev != 'N/A') {
                targetDeviceId = storedDev;
              }
            }
          }
        }
      } catch (_) {}

      // 2. Snapshot the final telemetry from the device before disconnecting
      if (targetDeviceId.isNotEmpty && targetDeviceId != 'N/A') {
        try {
          final devRes = await getFn(Uri.parse('$databaseUrl/devices/$targetDeviceId.json'))
              .timeout(const Duration(seconds: 3));
          if (devRes.statusCode == 200 && devRes.body != 'null' && devRes.body.trim().isNotEmpty) {
            final devMap = Map<String, dynamic>.from(jsonDecode(devRes.body));
            final devBpm = (devMap['bpm'] as num?)?.toInt() ?? 0;
            final devSpo2 = (devMap['spo2'] as num?)?.toInt() ?? 0;
            if (devBpm > 0) finalBpm = devBpm;
            if (devSpo2 > 0) finalSpo2 = devSpo2;
          }
        } catch (_) {}
      }

      final now = DateTime.now();
      final fullTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // 3. Evaluate clinical status for final_vitals
      final severity = (finalBpm > 0 && finalSpo2 > 0)
          ? VitalThresholds.evaluateVitals(finalBpm, finalSpo2)
          : AlertSeverity.info;
      final statusStr = severity == AlertSeverity.critical
          ? 'Critical'
          : (severity == AlertSeverity.warning ? 'Warning' : 'Normal');

      final finalVitals = <String, dynamic>{
        'bpm': finalBpm,
        'spo2': finalSpo2,
        'status': statusStr,
        'last_updated': fullTimestamp,
      };

      // 4. Update patient: status = Completed, device = N/A, write final_vitals
      final patchData = <String, dynamic>{
        'status': 'Completed',
        'device': 'N/A',
        'final_vitals': finalVitals,
        'last_updated': fullTimestamp,
      };
      if (finalBpm > 0) patchData['bpm'] = finalBpm;
      if (finalSpo2 > 0) patchData['spo2'] = finalSpo2;

      final res = await patchFn(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
        body: jsonEncode(patchData),
      );

      // 5. Update device: status = AVAILABLE, zero out BPM and SpO2 values
      if (res.statusCode == 200) {
        if (targetDeviceId.isNotEmpty && targetDeviceId != 'N/A') {
          await patchFn(
            Uri.parse('$databaseUrl/devices/$targetDeviceId.json'),
            body: jsonEncode({
              'status': 'AVAILABLE',
              'bpm': 0,
              'spo2': 0,
              'last_updated': fullTimestamp,
            }),
          );
        }
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('endSession error: $e');
      return false;
    }
  }

  // 6. Delete / Deactivate Patient from Firebase RTDB
  Future<bool> deletePatient(String patientId, {String? deviceId, http.Client? client}) async {
    try {
      final deleteFn = client != null ? client.delete : http.delete;
      final patchFn = client != null ? client.patch : http.patch;
      final res = await deleteFn(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
      );

      if (res.statusCode == 200) {
        if (deviceId != null && deviceId.isNotEmpty && deviceId != 'N/A') {
          await patchFn(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({
              'status': 'AVAILABLE',
              'bpm': 0,
              'spo2': 0,
            }),
          );
        }
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete patient error: $e');
      return false;
    }
  }

  // 7. Acknowledge Alert in Firebase RTDB
  Future<bool> acknowledgeAlert({
    required String alertId,
    required String nurseName,
    String? nurseId,
    String? userRole,
    String? patientId,
    String? session,
    String? time,
    String? note,
    http.Client? client,
  }) async {
    lastAlertError = null;

    // Role check: Admin accounts are strictly blocked from acknowledging alerts
    if (userRole != null && userRole.trim().toLowerCase() == 'admin') {
      lastAlertError = 'Admin accounts cannot acknowledge clinical alerts.';
      debugPrint('acknowledgeAlert rejected: $lastAlertError');
      return false;
    }

    try {
      final getFn = client != null ? client.get : http.get;
      final patchFn = client != null ? client.patch : http.patch;

      final now = DateTime.now();
      final timeStr = (time != null && time.isNotEmpty)
          ? time
          : DateFormat('HH:mm').format(now);
      final staffIdToWrite = (nurseId != null && nurseId.trim().isNotEmpty)
          ? nurseId.trim()
          : 'EMP-001';

      String targetPatientId = patientId ?? '';
      String targetSession = session ?? '';

      // 1. Fetch alert details if patientId or session is missing
      if (targetPatientId.isEmpty || targetSession.isEmpty) {
        try {
          final aRes = await getFn(Uri.parse('$databaseUrl/alerts/$alertId.json'))
              .timeout(const Duration(seconds: 4));
          if (aRes.statusCode == 200 && aRes.body != 'null' && aRes.body.trim().isNotEmpty) {
            final aData = jsonDecode(aRes.body);
            if (aData is Map) {
              if (targetPatientId.isEmpty) {
                targetPatientId = aData['patient_id']?.toString() ?? '';
              }
              if (targetSession.isEmpty) {
                targetSession = aData['session']?.toString() ??
                    aData['session_num']?.toString() ??
                    aData['session_id']?.toString() ??
                    '';
              }
            }
          }
        } catch (_) {}
      }

      // 2. Fetch patient details to discover session if still missing
      if (targetSession.isEmpty && targetPatientId.isNotEmpty) {
        try {
          final pRes = await getFn(Uri.parse('$databaseUrl/patients/$targetPatientId.json'))
              .timeout(const Duration(seconds: 4));
          if (pRes.statusCode == 200 && pRes.body != 'null' && pRes.body.trim().isNotEmpty) {
            final pData = jsonDecode(pRes.body);
            if (pData is Map) {
              targetSession = pData['session']?.toString() ?? '';
            }
          }
        } catch (_) {}
      }

      // 3. Resolve sessionKey and locate the alert in history if possible
      String targetSessionKey = '';
      if (targetSession.isNotEmpty) {
        final clean = targetSession.replaceAll(RegExp(r'[^0-9]'), '');
        targetSessionKey = clean.isNotEmpty ? 'session_$clean' : targetSession;
        if (!targetSessionKey.startsWith('session_')) {
          targetSessionKey = 'session_$targetSessionKey';
        }
      }

      if (targetPatientId.isNotEmpty) {
        try {
          final hRes = await getFn(Uri.parse('$databaseUrl/history/$targetPatientId.json'))
              .timeout(const Duration(seconds: 4));
          if (hRes.statusCode == 200 && hRes.body != 'null' && hRes.body.trim().isNotEmpty) {
            final hData = jsonDecode(hRes.body);
            if (hData is Map) {
              for (final entry in hData.entries) {
                final sVal = entry.value;
                if (sVal is Map && sVal['alerts'] is Map) {
                  final alertsMap = sVal['alerts'] as Map;
                  if (alertsMap.containsKey(alertId)) {
                    targetSessionKey = entry.key;
                    break;
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      if (targetSessionKey.isEmpty) {
        targetSessionKey = 'session_1';
      }

      // 4. Construct acknowledgment payload with status, staff name, staff id, and time
      final patchData = <String, dynamic>{
        'status': 'Acknowledged',
        'acknowledged_by': nurseName,
        'acknowledged_by_id': staffIdToWrite,
        'acknowledged_at': timeStr,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final patchBody = jsonEncode(patchData);

      // 5. Patch top-level alert
      final res = await patchFn(
        Uri.parse('$databaseUrl/alerts/$alertId.json'),
        body: patchBody,
      );

      // 6. Patch history/{patient}/{session}/alerts/{alertId}
      if (targetPatientId.isNotEmpty) {
        await patchFn(
          Uri.parse('$databaseUrl/history/$targetPatientId/$targetSessionKey/alerts/$alertId.json'),
          body: patchBody,
        );
      }

      if (res.statusCode == 200) {
        syncData();
        return true;
      }
      lastAlertError = 'Failed to acknowledge alert in database (status ${res.statusCode}).';
      return false;
    } catch (e) {
      lastAlertError = 'Acknowledge alert error: $e';
      debugPrint('Acknowledge alert error: $e');
      return false;
    }
  }

  // 8. Delete / Clear Acknowledged Alerts from Firebase RTDB
  Future<bool> deleteAcknowledgedAlerts({
    bool clearEntireTable = false,
    http.Client? client,
  }) async {
    lastAlertError = null;
    final getFn = client != null ? client.get : http.get;
    final patchFn = client != null ? client.patch : http.patch;
    final deleteFn = client != null ? client.delete : http.delete;

    try {
      if (clearEntireTable) {
        final delRes = await deleteFn(
          Uri.parse('$databaseUrl/alerts.json'),
        ).timeout(const Duration(seconds: 5));

        if (delRes.statusCode == 200) {
          syncData();
          return true;
        }
        lastAlertError = 'Failed to clear alerts table (status ${delRes.statusCode}).';
        return false;
      }

      // 1. Fetch current alerts from Firebase RTDB
      final res = await getFn(Uri.parse('$databaseUrl/alerts.json'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode != 200 ||
          res.body == 'null' ||
          res.body.trim().isEmpty ||
          res.body.trim() == 'null') {
        return true; // Already empty
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return true;

      // 2. Filter acknowledged alerts and prepare patch payload with null values
      final Map<String, dynamic> patchPayload = {};
      decoded.forEach((key, val) {
        if (val is Map) {
          final status = (val['status'] ?? '').toString().toLowerCase();
          final isAck = val['is_acknowledged'] == true || status == 'acknowledged';
          if (isAck) {
            patchPayload[key.toString()] = null;
          }
        }
      });

      if (patchPayload.isEmpty) {
        return true; // No acknowledged alerts to delete
      }

      // 3. Atomically delete acknowledged alerts in Firebase RTDB
      final patchRes = await patchFn(
        Uri.parse('$databaseUrl/alerts.json'),
        body: jsonEncode(patchPayload),
      ).timeout(const Duration(seconds: 5));

      if (patchRes.statusCode == 200) {
        syncData();
        return true;
      }

      lastAlertError = 'Failed to delete acknowledged alerts (status ${patchRes.statusCode}).';
      return false;
    } catch (e) {
      lastAlertError = 'Delete alerts error: $e';
      debugPrint('Delete alerts error: $e');
      return false;
    }
  }

  // 9. Record Clinical Nurse Note to Patient History in Firebase RTDB
  Future<bool> recordClinicalNote({
    required String patientId,
    required String session,
    required String note,
    required String nurseName,
    required String staffId,
  }) async {
    try {
      final noteKey = '-N-${DateTime.now().millisecondsSinceEpoch}';
      final cleanSession = session.replaceAll(RegExp(r'[^0-9]'), '');
      final sessionKey = cleanSession.isNotEmpty ? 'session_$cleanSession' : 'session_2';

      final body = jsonEncode({
        'note': note,
        'nurse_name': nurseName,
        'staff_id': staffId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      final res = await http.put(
        Uri.parse('$databaseUrl/history/$patientId/$sessionKey/notes/$noteKey.json'),
        body: body,
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Record note error: $e');
      return false;
    }
  }

  // 9. Update Remark for a specific reading / timestamp in Firebase RTDB
  Future<bool> updateReadingRemark({
    required String patientId,
    required String sessionNumber,
    required String readingId,
    required String remark,
  }) async {
    try {
      final cleanSession = sessionNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final sessionKey = cleanSession.isNotEmpty ? 'session_$cleanSession' : 'session_1';

      final patchBody = jsonEncode({
        'remarks': remark,
      });

      final res = await http.patch(
        Uri.parse('$databaseUrl/history/$patientId/$sessionKey/readings/$readingId.json'),
        body: patchBody,
      );

      if (res.statusCode == 200) {
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('updateReadingRemark error: $e');
      return false;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _patientsController.close();
    _alertsController.close();
    _devicesController.close();
  }
}

class _DeviceTelemetryTracker {
  int lastBpm;
  int lastSpO2;
  String lastDeviceUpdated;
  DateTime lastChangeTime;
  String lastReceivedFormatted;
  bool isIdle;

  _DeviceTelemetryTracker({
    required this.lastBpm,
    required this.lastSpO2,
    required this.lastDeviceUpdated,
    required this.lastChangeTime,
    required this.lastReceivedFormatted,
    this.isIdle = false,
  });
}

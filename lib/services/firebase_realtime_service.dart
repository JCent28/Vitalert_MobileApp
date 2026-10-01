import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/alert_item.dart';
import '../models/device_model.dart';
import '../models/patient.dart';
import '../models/user_model.dart';
import 'vital_thresholds.dart';

class FirebaseRealtimeService {
  static const String databaseUrl =
      'https://vitalert-app-default-rtdb.asia-southeast1.firebasedatabase.app';

  Timer? _pollingTimer;
  final _patientsController = StreamController<List<Patient>>.broadcast();
  final _alertsController = StreamController<List<AlertItem>>.broadcast();
  final _devicesController = StreamController<List<DeviceModel>>.broadcast();

  Stream<List<Patient>> get patientsStream => _patientsController.stream;
  Stream<List<AlertItem>> get alertsStream => _alertsController.stream;
  Stream<List<DeviceModel>> get devicesStream => _devicesController.stream;

  bool _isSyncing = false;

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
      if (devicesRes.statusCode == 200 && devicesRes.body != 'null') {
        devicesMap = Map<String, dynamic>.from(jsonDecode(devicesRes.body));
        devicesMap.forEach((k, v) {
          if (v is Map) {
            devicesList.add(DeviceModel.fromMap(k, Map<String, dynamic>.from(v)));
          }
        });
        devicesList.sort((a, b) => a.deviceId.compareTo(b.deviceId));
        _devicesController.add(devicesList);
      }

      Map<String, dynamic> alertsRaw = {};
      List<AlertItem> parsedAlerts = [];
      if (alertsRes.statusCode == 200 && alertsRes.body != 'null') {
        alertsRaw = Map<String, dynamic>.from(jsonDecode(alertsRes.body));
        parsedAlerts = _parseAlerts(alertsRaw);
        _alertsController.add(parsedAlerts);
      }

      Map<String, dynamic> historyRaw = {};
      if (historyRes.statusCode == 200 && historyRes.body != 'null') {
        historyRaw = Map<String, dynamic>.from(jsonDecode(historyRes.body));
      }

      if (patientsRes.statusCode == 200 && patientsRes.body != 'null') {
        final patientsRaw = Map<String, dynamic>.from(jsonDecode(patientsRes.body));
        final parsedPatients = _parsePatients(
          patientsRaw: patientsRaw,
          devicesMap: devicesMap,
          alertsList: parsedAlerts,
          historyMap: historyRaw,
        );
        _patientsController.add(parsedPatients);
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
            title: severity == AlertSeverity.critical
                ? 'CRITICAL ALERT'
                : 'WARNING ALERT',
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
    return list;
  }

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

              sessionHistories.add(
                PatientSessionHistory(
                  sessionNumber: sNum,
                  sessionTitle: 'Session $sNum',
                  startTime: sReadings.isNotEmpty ? sReadings.first.time : '--',
                  duration: sReadings.isNotEmpty ? sReadings.last.duration : '--',
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

        if (!sessionHistories.any((s) => s.sessionNumber == displaySessionNum)) {
          sessionHistories.add(
            PatientSessionHistory(
              sessionNumber: displaySessionNum,
              sessionTitle: 'Session $displaySessionNum',
              startTime: recentReadings.isNotEmpty ? recentReadings.first.time : '--',
              duration: recentReadings.isNotEmpty ? recentReadings.last.duration : '--',
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

        final rawStatus = (pData['status'] ?? 'Waiting').toString();
        String sessionStatus = 'Waiting';
        if (rawStatus.toLowerCase() == 'ongoing') {
          sessionStatus = 'Ongoing';
        } else if (rawStatus.toLowerCase() == 'completed') {
          sessionStatus = 'Completed';
        } else if (rawStatus.toLowerCase() == 'inactive') {
          sessionStatus = 'Inactive';
        } else {
          sessionStatus = 'Waiting';
        }

        // Auto-promote to Ongoing when the device starts sending live readings
        // and the database status hasn't been updated yet.
        final isReceivingLiveData = !hasNoDevice && liveBpm > 0 && liveSpO2 > 0;
        if (isReceivingLiveData && sessionStatus == 'Waiting') {
          sessionStatus = 'Ongoing';
          // Sync the updated status back to Firebase
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

        final durationStr = recentReadings.isNotEmpty
            ? recentReadings.first.duration
            : (pData['duration'] != null && pData['duration'].toString().isNotEmpty ? pData['duration'].toString() : '--');

        final name = pData['name'] ?? 'Jane Doe';
        final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();

        list.add(
          Patient(
            id: patientId,
            name: name,
            mrn: '#${patientId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0').substring(0, 6)}',
            initials: initials.isNotEmpty ? initials : 'JD',
            chair: pData['chair']?.toString() ?? '1',
            department: 'NephroAsia Dialysis Bay',
            session: 'Session $displaySessionNum',
            deviceId: deviceKey,
            date: 'Friday, August 21, 2026',
            startTime: lastUpdatedTime,
            primaryNurse: 'Clark Kent',
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
  }) async {
    try {
      final res = await http.get(Uri.parse('$databaseUrl/users/$staffId.json'));
      if (res.statusCode == 200 && res.body != 'null') {
        final data = jsonDecode(res.body);
        if (data is Map) {
          final storedPass = data['password']?.toString() ?? '';
          if (storedPass == password) {
            return UserModel(
              staffId: data['staff_id'] ?? staffId,
              name: data['name'] ?? 'Staff Member',
              role: data['role'] ?? 'Staff Nurse',
            );
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('RTDB Auth error: $e');
      return null;
    }
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
  }) async {
    try {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final formattedSession = sessionNum.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
          ? sessionNum.replaceAll(RegExp(r'[^0-9]'), '')
          : '1';

      final res = await http.patch(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
        body: jsonEncode({
          'session': formattedSession,
          'device': deviceId.isEmpty ? 'N/A' : deviceId,
          'status': 'Waiting',
          'last_updated': timeStr,
        }),
      );

      if (res.statusCode == 200) {
        if (deviceId.isNotEmpty && deviceId != 'N/A') {
          await http.patch(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({
              'status': 'IN_USE',
              'last_updated': timeStr,
            }),
          );
        }
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('startSession error: $e');
      return false;
    }
  }

  // 5. End Dialysis Session in Firebase RTDB
  Future<bool> endSession({
    required String patientId,
    required String deviceId,
  }) async {
    try {
      // 1. Snapshot the final telemetry from the device before disconnecting
      int finalBpm = 0;
      int finalSpo2 = 0;
      String finalLastUpdated = '';
      if (deviceId.isNotEmpty && deviceId != 'N/A') {
        try {
          final devRes = await http
              .get(Uri.parse('$databaseUrl/devices/$deviceId.json'))
              .timeout(const Duration(seconds: 3));
          if (devRes.statusCode == 200 && devRes.body != 'null') {
            final devMap = Map<String, dynamic>.from(jsonDecode(devRes.body));
            finalBpm = (devMap['bpm'] as num?)?.toInt() ?? 0;
            finalSpo2 = (devMap['spo2'] as num?)?.toInt() ?? 0;
            finalLastUpdated = devMap['last_updated']?.toString() ?? '';
          }
        } catch (_) {}
      }

      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      if (finalLastUpdated.isEmpty) finalLastUpdated = timeStr;

      final patchData = <String, dynamic>{
        'status': 'Completed',
        'last_updated': finalLastUpdated,
      };
      if (finalBpm > 0) patchData['bpm'] = finalBpm;
      if (finalSpo2 > 0) patchData['spo2'] = finalSpo2;

      final res = await http.patch(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
        body: jsonEncode(patchData),
      );

      if (res.statusCode == 200) {
        if (deviceId.isNotEmpty && deviceId != 'N/A') {
          await http.patch(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({
              'status': 'AVAILABLE',
              'last_updated': finalLastUpdated,
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
  Future<bool> deletePatient(String patientId, {String? deviceId}) async {
    try {
      final res = await http.delete(
        Uri.parse('$databaseUrl/patients/$patientId.json'),
      );

      if (res.statusCode == 200) {
        if (deviceId != null && deviceId.isNotEmpty) {
          await http.patch(
            Uri.parse('$databaseUrl/devices/$deviceId.json'),
            body: jsonEncode({'status': 'AVAILABLE'}),
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
    required String time,
    String? note,
  }) async {
    try {
      final patchBody = jsonEncode({
        'status': 'Acknowledged',
        'acknowledged_by': nurseName,
        'acknowledged_at': time,
        if (note != null && note.isNotEmpty) 'note': note,
      });

      final res = await http.patch(
        Uri.parse('$databaseUrl/alerts/$alertId.json'),
        body: patchBody,
      );

      if (res.statusCode == 200) {
        syncData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Acknowledge alert error: $e');
      return false;
    }
  }

  // 8. Record Clinical Nurse Note to Patient History in Firebase RTDB
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/alert_item.dart';
import '../models/device_model.dart';
import '../models/patient.dart';
import '../models/user_model.dart';
import '../services/alert_notification_service.dart';
import '../services/firebase_realtime_service.dart';
import '../services/foreground_service_manager.dart';
import '../services/session_storage_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseRealtimeService _rtdbService = FirebaseRealtimeService();
  StreamSubscription? _patientsSub;
  StreamSubscription? _alertsSub;
  StreamSubscription? _devicesSub;

  bool _isLoggedIn = false;
  bool _isRestoringSession = true; // true while reading saved session from disk
  UserModel? _currentUser;

  int _currentTabIndex = 0;
  String _selectedPatientId = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isRestoringSession => _isRestoringSession;
  UserModel? get currentUser => _currentUser;
  String get currentStaffId => _currentUser?.staffId ?? '';
  String get nurseName => _currentUser?.name ?? '';
  String get userRole => _currentUser?.role ?? '';
  bool get isHeadNurse => _currentUser?.isHeadNurse ?? false;
  bool get isStaffNurse => _currentUser?.isStaffNurse ?? false;
  String get shiftTime => 'Shift A · ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}';
  int get currentTabIndex => _currentTabIndex;
  String get selectedPatientId => _selectedPatientId;
  String? get lastSessionError => _rtdbService.lastSessionError;
  String? _lastAlertError;
  String? get lastAlertError => _lastAlertError ?? _rtdbService.lastAlertError;
  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError ?? _rtdbService.lastAuthError;

  List<Patient> _patients = [];
  List<AlertItem> _alerts = [];
  List<DeviceModel> _devices = [];

  AppState() {
    _initData();
    _bindFirebase();
    _restoreSession();
  }

  /// Reads the previously saved login session from disk.
  /// If a valid session exists the user goes straight to the dashboard;
  /// otherwise they are shown the sign-in screen.
  Future<void> _restoreSession() async {
    final saved = await SessionStorageService.loadSession();
    if (saved != null) {
      final status = saved['status'] ?? 'Active';
      if (status.toLowerCase() != 'active') {
        await SessionStorageService.clearSession();
        _currentUser = null;
        _isLoggedIn = false;
        await ForegroundServiceManager.stopService();
      } else {
        _currentUser = UserModel(
          staffId: saved['staffId']!,
          name: saved['name']!,
          role: saved['role']!,
          status: status,
        );
        _isLoggedIn = true;
        // Start background alerting only when active session is restored
        await ForegroundServiceManager.startService();
      }
    } else {
      _currentUser = null;
      _isLoggedIn = false;
      await ForegroundServiceManager.stopService();
    }
    _isRestoringSession = false;
    notifyListeners();
  }

  void _bindFirebase() {
    _patientsSub = _rtdbService.patientsStream.listen((livePatients) {
      _patients = livePatients;
      if (_patients.isNotEmpty) {
        if (!_patients.any((p) => p.id == _selectedPatientId)) {
          _selectedPatientId = _patients.first.id;
        }
      } else {
        _selectedPatientId = '';
      }
      notifyListeners();
    });

    _alertsSub = _rtdbService.alertsStream.listen((liveAlerts) {
      _alerts = liveAlerts;
      // Do NOT trigger alert notifications on a logged-out phone
      if (_isLoggedIn) {
        AlertNotificationService.processLiveAlerts(liveAlerts);
      }
      notifyListeners();
    });

    _devicesSub = _rtdbService.devicesStream.listen((liveDevices) {
      _devices = liveDevices;
      notifyListeners();
    });

    _rtdbService.startLiveSync(interval: const Duration(seconds: 2));
  }

  void _initData() {
    _patients = [];
    _alerts = [];
    _devices = [];
    _selectedPatientId = '';
  }

  Patient _createDefaultPatient() {
    return Patient(
      id: '',
      name: 'No Patient Selected',
      mrn: '--',
      initials: '--',
      chair: '--',
      department: 'NephroAsia Dialysis Bay',
      session: 'Session --',
      deviceId: 'N/A',
      date: DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
      startTime: '--',
      primaryNurse: '--',
      duration: '--',
      sessionStatus: 'Waiting',
      status: AlertSeverity.info,
      currentHr: 0,
      currentSpO2: 0,
      highestHr: 0,
      lowestHr: 0,
      avgHr: 0,
      highestSpO2: 0,
      lowestSpO2: 0,
      avgSpO2: 0,
      hrHistory: const [],
      spO2History: const [],
      recentReadings: const [],
      alertEvents: const [],
    );
  }

  List<Patient> get patients => _patients;
  List<DeviceModel> get devices => _devices;
  List<AlertItem> get alerts => _alerts;

  Patient get selectedPatient =>
      _patients.firstWhere((p) => p.id == _selectedPatientId, orElse: () => _patients.isNotEmpty ? _patients.first : _createDefaultPatient());

  List<AlertItem> get activeAlerts => _alerts.where((a) => !a.isAcknowledged).toList();
  List<AlertItem> get acknowledgedAlerts => _alerts.where((a) => a.isAcknowledged).toList();

  int get totalActivePatients => _patients.where((p) => p.sessionStatus == 'Ongoing').length;
  int get totalChairs => _patients.isNotEmpty ? _patients.map((p) => p.chair).toSet().length : 0;
  int get normalPatientsCount => _patients.where((p) => p.sessionStatus == 'Ongoing' && p.deviceId != 'N/A' && p.status == AlertSeverity.info).length;
  int get warningPatientsCount => _patients.where((p) => p.sessionStatus == 'Ongoing' && p.deviceId != 'N/A' && p.status == AlertSeverity.warning).length;
  int get criticalPatientsCount => _patients.where((p) => p.sessionStatus == 'Ongoing' && p.deviceId != 'N/A' && p.status == AlertSeverity.critical).length;

  Future<bool> signInWithFirebase(
    String staffId,
    String password, {
    String? selectedRole,
    http.Client? client,
  }) async {
    _lastAuthError = null;
    final user = await _rtdbService.authenticateStaff(
      staffId: staffId.trim(),
      password: password.trim(),
      selectedRole: selectedRole,
      client: client,
    );

    if (user != null) {
      _currentUser = user;
      _isLoggedIn = true;
      _currentTabIndex = 0;
      // Persist the session so the app restores it on next launch
      await SessionStorageService.saveSession(
        staffId: user.staffId,
        name: user.name,
        role: user.role,
        status: user.status,
      );
      // Start background monitoring upon nurse authentication
      await ForegroundServiceManager.startService();
      notifyListeners();
      return true;
    }
    _lastAuthError = _rtdbService.lastAuthError;
    notifyListeners();
    return false;
  }

  @visibleForTesting
  void setCurrentUserForTesting(UserModel? user) {
    _currentUser = user;
    _isLoggedIn = user != null;
    notifyListeners();
  }

  Future<void> signOut() async {
    // 1. Immediately stop the foreground background service
    await ForegroundServiceManager.stopService();

    // 2. Clear all visible heads-up notifications
    await AlertNotificationService.cancelAllNotifications();

    // 3. Clear the persisted session so restart won't auto-login
    await SessionStorageService.clearSession();

    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void selectPatient(String patientId) {
    _selectedPatientId = patientId;
    notifyListeners();
  }

  Future<bool> acknowledgeAlert(String alertId, {String? note, http.Client? client}) async {
    _lastAlertError = null;

    if (currentUser?.isAdmin == true || userRole.toLowerCase() == 'admin') {
      _lastAlertError = 'Admin accounts cannot acknowledge clinical alerts.';
      debugPrint('acknowledgeAlert rejected: $_lastAlertError');
      notifyListeners();
      return false;
    }

    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    final index = _alerts.indexWhere((a) => a.id == alertId);
    String? patientId;
    String? session;
    if (index != -1) {
      final a = _alerts[index];
      patientId = a.patientId;
      session = a.session;
      _alerts[index].acknowledge(
        nurseName: nurseName,
        time: timeStr,
        nurseId: currentStaffId,
      );
      if (note != null) _alerts[index].note = note;
      notifyListeners();
    }

    if (patientId != null && patientId.isNotEmpty && (session == null || session.isEmpty)) {
      final pIndex = _patients.indexWhere((p) => p.id == patientId);
      if (pIndex != -1) {
        session = _patients[pIndex].session;
      }
    }

    AlertNotificationService.dismissAlert(alertId, patientId: patientId);

    final success = await _rtdbService.acknowledgeAlert(
      alertId: alertId,
      nurseName: nurseName,
      nurseId: currentStaffId,
      userRole: userRole,
      patientId: patientId,
      session: session,
      time: timeStr,
      note: note,
      client: client,
    );

    if (!success) {
      _lastAlertError = _rtdbService.lastAlertError;
      notifyListeners();
    }
    return success;
  }

  Future<bool> startSession({
    required String patientId,
    required String sessionNum,
    required String deviceId,
    http.Client? client,
  }) async {
    final success = await _rtdbService.startSession(
      patientId: patientId,
      sessionNum: sessionNum,
      deviceId: deviceId,
      client: client,
    );
    if (success) {
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        final p = _patients[index];
        _patients[index] = p.copyWith(
          sessionStatus: 'Ongoing',
          session: 'Session $sessionNum',
          deviceId: deviceId.isEmpty ? 'N/A' : deviceId,
          status: AlertSeverity.info,
        );
        notifyListeners();
      }
    }
    return success;
  }

  Future<bool> endSession({
    required String patientId,
    required String deviceId,
    http.Client? client,
  }) async {
    final success = await _rtdbService.endSession(
      patientId: patientId,
      deviceId: deviceId,
      client: client,
    );
    if (success) {
      String targetDevId = deviceId;
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        final p = _patients[index];
        if (targetDevId.isEmpty || targetDevId == 'N/A') {
          targetDevId = p.deviceId;
        }
        _patients[index] = p.copyWith(
          sessionStatus: 'Completed',
          deviceId: 'N/A',
        );
      }
      if (targetDevId.isNotEmpty && targetDevId != 'N/A') {
        final devIndex = _devices.indexWhere((d) => d.deviceId == targetDevId);
        if (devIndex != -1) {
          final d = _devices[devIndex];
          _devices[devIndex] = DeviceModel(
            deviceId: d.deviceId,
            status: 'AVAILABLE',
            bpm: 0,
            spo2: 0,
            lastUpdated: d.lastUpdated,
          );
        }
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> updatePatientSessionStatus(String patientId, String newStatus) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      final p = _patients[index];
      _patients[index] = p.copyWith(
        sessionStatus: newStatus,
        session: 'Session ${p.chair}',
      );
      notifyListeners();
    }
    return await _rtdbService.updatePatient(patientId, status: newStatus);
  }

  Future<bool> deactivatePatient(String patientId, {String? deviceId, http.Client? client}) async {
    _patients.removeWhere((p) => p.id == patientId);
    notifyListeners();
    return await _rtdbService.deletePatient(patientId, deviceId: deviceId, client: client);
  }

  Future<bool> updatePatient(
    String patientId, {
    String? name,
    String? chair,
    String? session,
    String? deviceId,
  }) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      final p = _patients[index];
      _patients[index] = p.copyWith(
        name: name,
        chair: chair,
        session: session != null ? 'Session $session' : null,
        deviceId: deviceId,
      );
      notifyListeners();
    }
    return await _rtdbService.updatePatient(
      patientId,
      name: name,
      chair: chair,
      session: session,
      deviceId: deviceId,
    );
  }

  Future<bool> addPatient({
    required String name,
    required String chair,
    required String session,
    required String deviceId,
  }) async {
    return await _rtdbService.addPatient(
      name: name,
      chair: chair,
      session: session,
      deviceId: deviceId,
    );
  }

  Future<bool> recordClinicalNote({
    required String patientId,
    required String session,
    required String note,
  }) async {
    return await _rtdbService.recordClinicalNote(
      patientId: patientId,
      session: session,
      note: note,
      nurseName: nurseName,
      staffId: currentStaffId,
    );
  }

  Future<bool> updateReadingRemark({
    required String patientId,
    required String sessionNumber,
    required String readingId,
    required String remark,
  }) async {
    final pIdx = _patients.indexWhere((p) => p.id == patientId);
    if (pIdx != -1) {
      final p = _patients[pIdx];
      final cleanNum = sessionNumber.replaceAll(RegExp(r'[^0-9]'), '');

      final updatedHistories = p.sessionHistories.map((s) {
        if (s.sessionNumber == cleanNum || s.sessionNumber == sessionNumber) {
          final updatedReadings = s.readings.map((r) {
            if (r.id == readingId) {
              return r.copyWith(remark: remark);
            }
            return r;
          }).toList();
          return PatientSessionHistory(
            sessionNumber: s.sessionNumber,
            sessionTitle: s.sessionTitle,
            startTime: s.startTime,
            duration: s.duration,
            highestHr: s.highestHr,
            lowestHr: s.lowestHr,
            avgHr: s.avgHr,
            highestSpO2: s.highestSpO2,
            lowestSpO2: s.lowestSpO2,
            avgSpO2: s.avgSpO2,
            hrHistory: s.hrHistory,
            spO2History: s.spO2History,
            readings: updatedReadings,
          );
        }
        return s;
      }).toList();

      final updatedRecent = p.recentReadings.map((r) {
        if (r.id == readingId) {
          return r.copyWith(remark: remark);
        }
        return r;
      }).toList();

      _patients[pIdx] = p.copyWith(
        sessionHistories: updatedHistories,
        recentReadings: updatedRecent,
      );
      notifyListeners();
    }

    return await _rtdbService.updateReadingRemark(
      patientId: patientId,
      sessionNumber: sessionNumber,
      readingId: readingId,
      remark: remark,
    );
  }

  @override
  void dispose() {
    _patientsSub?.cancel();
    _alertsSub?.cancel();
    _devicesSub?.cancel();
    _rtdbService.dispose();
    super.dispose();
  }
}

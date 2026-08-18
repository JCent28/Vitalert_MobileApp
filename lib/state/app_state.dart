import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../models/patient.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = true;
  String _currentStaffId = 'RN-04812';
  final String _nurseName = 'Rosa M.';
  final String _shiftTime = '07:00 - 19:00';
  int _currentTabIndex = 0;
  String _selectedPatientId = 'pg';

  bool get isLoggedIn => _isLoggedIn;
  String get currentStaffId => _currentStaffId;
  String get nurseName => _nurseName;
  String get shiftTime => _shiftTime;
  int get currentTabIndex => _currentTabIndex;
  String get selectedPatientId => _selectedPatientId;

  late List<Patient> _patients;
  late List<AlertItem> _alerts;

  AppState() {
    _initData();
  }

  void _initData() {
    _patients = [
      const Patient(
        id: 'pg',
        name: 'Pedro Garcia',
        initials: 'PG',
        chair: 'Chair 01',
        department: 'Infusion',
        session: 'Session 3',
        date: 'June 16, 2026',
        startTime: '12:00 PM',
        primaryNurse: 'Rosa M.',
        duration: '2h 45m',
        sessionStatus: 'ONGOING',
        status: AlertSeverity.critical,
        currentHr: 142,
        currentSpO2: 88,
        hrHistory: [2.0, 4.0, 3.0, 6.0, 8.0, 5.0],
        spO2History: [8.0, 5.0, 6.0, 4.0, 5.0, 4.0],
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        recentReadings: [
          PatientReading(time: '14:00', hrBpm: 128, spO2: 91, status: 'WARN', severity: AlertSeverity.warning),
          PatientReading(time: '13:00', hrBpm: 115, spO2: 94, status: 'OK', severity: AlertSeverity.info),
          PatientReading(time: '12:00', hrBpm: 110, spO2: 95, status: 'OK', severity: AlertSeverity.info),
        ],
        alertEvents: [
          PatientLogEvent(
            time: '14:32',
            severity: AlertSeverity.critical,
            hrBpm: 142,
            spO2: 88,
            description: 'SpO2 dropped below 90% alongside tachycardia.',
            acknowledgementNote: 'Acknowledged by Rosa M. at 14:33. Oxygen flow increased.',
          ),
          PatientLogEvent(
            time: '13:45',
            severity: AlertSeverity.warning,
            hrBpm: 110,
            spO2: 94,
            description: 'Elevated heart rate detected during position change.',
          ),
        ],
      ),
      const Patient(
        id: 'sl',
        name: 'Sarah Lin',
        initials: 'SL',
        chair: 'Chair 02',
        department: 'Observation',
        session: 'Session 1',
        date: 'June 16, 2026',
        startTime: '13:00 PM',
        primaryNurse: 'Rosa M.',
        duration: '1h 30m',
        sessionStatus: 'ONGOING',
        status: AlertSeverity.warning,
        currentHr: 115,
        currentSpO2: 97,
        hrHistory: [2.0, 3.0, 4.0, 6.0, 4.0, 5.0],
        spO2History: [8.0, 8.0, 6.0, 8.0, 5.0, 8.0],
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
        recentReadings: [
          PatientReading(time: '14:00', hrBpm: 115, spO2: 97, status: 'WARN', severity: AlertSeverity.warning),
          PatientReading(time: '13:30', hrBpm: 102, spO2: 98, status: 'OK', severity: AlertSeverity.info),
        ],
        alertEvents: [
          PatientLogEvent(
            time: '14:10',
            severity: AlertSeverity.warning,
            hrBpm: 115,
            spO2: 97,
            description: 'Tachycardia alert triggered (>110 BPM).',
            acknowledgementNote: 'Assessed by Rosa M. at 14:12. Patient drinking water.',
          ),
        ],
      ),
      const Patient(
        id: 'jd',
        name: 'John Doe',
        initials: 'JD',
        chair: 'Chair 03',
        department: 'Recovery',
        session: 'Session 4',
        date: 'June 16, 2026',
        startTime: '10:30 AM',
        primaryNurse: 'Rosa M.',
        duration: '4h 00m',
        sessionStatus: 'ONGOING',
        status: AlertSeverity.info,
        currentHr: 72,
        currentSpO2: 99,
        hrHistory: [2.0, 3.0, 2.0, 4.0, 2.0, 3.0],
        spO2History: [8.0, 8.0, 8.0, 8.0, 8.0, 8.0],
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
        recentReadings: [
          PatientReading(time: '14:00', hrBpm: 72, spO2: 99, status: 'OK', severity: AlertSeverity.info),
          PatientReading(time: '13:00', hrBpm: 74, spO2: 99, status: 'OK', severity: AlertSeverity.info),
          PatientReading(time: '12:00', hrBpm: 70, spO2: 98, status: 'OK', severity: AlertSeverity.info),
        ],
        alertEvents: [],
      ),
      const Patient(
        id: 'al',
        name: 'Ana Lim',
        initials: 'AL',
        chair: 'Chair 04',
        department: 'Dialysis Bay A',
        session: 'Session 2',
        date: 'June 16, 2026',
        startTime: '11:15 AM',
        primaryNurse: 'Rosa M.',
        duration: '3h 15m',
        sessionStatus: 'ONGOING',
        status: AlertSeverity.info,
        currentHr: 78,
        currentSpO2: 98,
        hrHistory: [3.0, 3.0, 4.0, 3.0, 4.0, 3.0],
        spO2History: [8.0, 8.0, 8.0, 8.0, 8.0, 8.0],
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
        recentReadings: [
          PatientReading(time: '14:00', hrBpm: 78, spO2: 98, status: 'OK', severity: AlertSeverity.info),
        ],
        alertEvents: [],
      ),
      const Patient(
        id: 'jdc',
        name: 'Juan dela Cruz',
        initials: 'JC',
        chair: 'Chair 05',
        department: 'Dialysis Bay B',
        session: 'Session 1',
        date: 'June 16, 2026',
        startTime: '12:30 PM',
        primaryNurse: 'Rosa M.',
        duration: '2h 00m',
        sessionStatus: 'ONGOING',
        status: AlertSeverity.info,
        currentHr: 82,
        currentSpO2: 97,
        hrHistory: [3.0, 4.0, 3.0, 5.0, 4.0, 3.0],
        spO2History: [8.0, 7.0, 8.0, 8.0, 7.0, 8.0],
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        recentReadings: [
          PatientReading(time: '14:00', hrBpm: 82, spO2: 97, status: 'OK', severity: AlertSeverity.info),
        ],
        alertEvents: [],
      ),
      const Patient(
        id: 'ms',
        name: 'Maria Santos',
        initials: 'MS',
        chair: 'Chair 06',
        department: 'Dialysis Bay A',
        session: 'Session 3',
        date: 'June 16, 2026',
        startTime: '09:00 AM',
        primaryNurse: 'Rosa M.',
        duration: '5h 30m',
        sessionStatus: 'ONGOING',
        status: AlertSeverity.warning,
        currentHr: 95,
        currentSpO2: 96,
        hrHistory: [4.0, 4.0, 5.0, 6.0, 5.0, 5.0],
        spO2History: [8.0, 7.0, 7.0, 8.0, 7.0, 8.0],
        avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
        recentReadings: [
          PatientReading(time: '14:00', hrBpm: 95, spO2: 96, status: 'WARN', severity: AlertSeverity.warning),
        ],
        alertEvents: [],
      ),
    ];

    _alerts = [
      AlertItem(
        id: 'alt-1',
        patientId: 'pg',
        patientName: 'Pedro Garcia',
        chairLocation: 'Chair 3',
        wardArea: 'Dialysis Bay B',
        severity: AlertSeverity.critical,
        title: 'Critical — Heart Rate',
        message: 'SpO2 dropped to 88%',
        timeString: '14:32',
        hrBpm: 142,
        spO2: 88,
        isAcknowledged: false,
      ),
      AlertItem(
        id: 'alt-2',
        patientId: 'ms',
        patientName: 'Maria Silva',
        chairLocation: 'Chair 1',
        wardArea: 'Dialysis Bay A',
        severity: AlertSeverity.warning,
        title: 'Elevated Blood Pressure',
        message: 'BP elevated: 160/95 mmHg',
        timeString: '12:15',
        isAcknowledged: true,
        acknowledgedBy: 'Rosa M.',
        acknowledgedAt: '12:18',
      ),
      AlertItem(
        id: 'alt-3',
        patientId: 'jc',
        patientName: 'John Chen',
        chairLocation: 'Chair 5',
        wardArea: 'Dialysis Bay B',
        severity: AlertSeverity.warning,
        title: 'Cardiac Rhythm Anomaly',
        message: 'HR irregularity detected',
        timeString: '09:45',
        isAcknowledged: true,
        acknowledgedBy: 'Dr. Smith',
        acknowledgedAt: '09:50',
      ),
    ];
  }

  List<Patient> get patients => _patients;
  Patient get selectedPatient =>
      _patients.firstWhere((p) => p.id == _selectedPatientId, orElse: () => _patients.first);

  List<AlertItem> get activeAlerts => _alerts.where((a) => !a.isAcknowledged).toList();
  List<AlertItem> get acknowledgedAlerts => _alerts.where((a) => a.isAcknowledged).toList();

  int get totalActivePatients => 3;
  int get normalPatientsCount => 1;
  int get warningPatientsCount => 1;
  int get criticalPatientsCount => 1;

  void signIn(String staffId, String pin) {
    _currentStaffId = staffId.isNotEmpty ? staffId : 'RN-04812';
    _isLoggedIn = true;
    _currentTabIndex = 0;
    notifyListeners();
  }

  void signOut() {
    _isLoggedIn = false;
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

  void acknowledgeAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index].acknowledge(nurseName: _nurseName, time: '14:33');
      notifyListeners();
    }
  }

  void acknowledgePatientCritical(String patientId) {
    for (final alert in _alerts.where((a) => a.patientId == patientId && !a.isAcknowledged)) {
      alert.acknowledge(nurseName: _nurseName, time: '14:33');
    }
    notifyListeners();
  }
}

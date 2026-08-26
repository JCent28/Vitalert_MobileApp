import 'alert_item.dart';

class PatientReading {
  final String time;
  final String duration;
  final int hrBpm;
  final int spO2;
  final String status;
  final AlertSeverity severity;

  const PatientReading({
    required this.time,
    required this.duration,
    required this.hrBpm,
    required this.spO2,
    required this.status,
    required this.severity,
  });
}

class PatientLogEvent {
  final String time;
  final AlertSeverity severity;
  final int hrBpm;
  final int spO2;
  final String description;
  final String? acknowledgementNote;

  const PatientLogEvent({
    required this.time,
    required this.severity,
    required this.hrBpm,
    required this.spO2,
    required this.description,
    this.acknowledgementNote,
  });
}

class PatientSessionHistory {
  final String sessionNumber;
  final String sessionTitle;
  final String startTime;
  final String duration;
  final int highestHr;
  final int lowestHr;
  final double avgHr;
  final int highestSpO2;
  final int lowestSpO2;
  final double avgSpO2;
  final List<double> hrHistory;
  final List<double> spO2History;
  final List<PatientReading> readings;

  const PatientSessionHistory({
    required this.sessionNumber,
    required this.sessionTitle,
    this.startTime = '--',
    this.duration = '--',
    this.highestHr = 0,
    this.lowestHr = 0,
    this.avgHr = 0.0,
    this.highestSpO2 = 0,
    this.lowestSpO2 = 0,
    this.avgSpO2 = 0.0,
    this.hrHistory = const [],
    this.spO2History = const [],
    this.readings = const [],
  });
}

class Patient {
  final String id;
  final String name;
  final String mrn;
  final String initials;
  final String chair;
  final String department;
  final String session;
  final String deviceId;
  final String date;
  final String startTime;
  final String primaryNurse;
  final String duration;
  final String sessionStatus;
  final AlertSeverity status;
  final int currentHr;
  final int currentSpO2;
  final int highestHr;
  final int lowestHr;
  final double avgHr;
  final int highestSpO2;
  final int lowestSpO2;
  final double avgSpO2;
  final List<double> hrHistory;
  final List<double> spO2History;
  final List<PatientReading> recentReadings;
  final List<PatientLogEvent> alertEvents;
  final List<PatientSessionHistory> sessionHistories;
  final String? avatarUrl;

  const Patient({
    required this.id,
    required this.name,
    required this.mrn,
    required this.initials,
    required this.chair,
    required this.department,
    required this.session,
    required this.deviceId,
    required this.date,
    required this.startTime,
    required this.primaryNurse,
    required this.duration,
    required this.sessionStatus,
    required this.status,
    required this.currentHr,
    required this.currentSpO2,
    this.highestHr = 125,
    this.lowestHr = 70,
    this.avgHr = 98.0,
    this.highestSpO2 = 98,
    this.lowestSpO2 = 89,
    this.avgSpO2 = 94.3,
    required this.hrHistory,
    required this.spO2History,
    required this.recentReadings,
    required this.alertEvents,
    this.sessionHistories = const [],
    this.avatarUrl,
  });

  Patient copyWith({
    String? id,
    String? name,
    String? mrn,
    String? initials,
    String? chair,
    String? department,
    String? session,
    String? deviceId,
    String? date,
    String? startTime,
    String? primaryNurse,
    String? duration,
    String? sessionStatus,
    AlertSeverity? status,
    int? currentHr,
    int? currentSpO2,
    int? highestHr,
    int? lowestHr,
    double? avgHr,
    int? highestSpO2,
    int? lowestSpO2,
    double? avgSpO2,
    List<double>? hrHistory,
    List<double>? spO2History,
    List<PatientReading>? recentReadings,
    List<PatientLogEvent>? alertEvents,
    List<PatientSessionHistory>? sessionHistories,
    String? avatarUrl,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      mrn: mrn ?? this.mrn,
      initials: initials ?? this.initials,
      chair: chair ?? this.chair,
      department: department ?? this.department,
      session: session ?? this.session,
      deviceId: deviceId ?? this.deviceId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      primaryNurse: primaryNurse ?? this.primaryNurse,
      duration: duration ?? this.duration,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      status: status ?? this.status,
      currentHr: currentHr ?? this.currentHr,
      currentSpO2: currentSpO2 ?? this.currentSpO2,
      highestHr: highestHr ?? this.highestHr,
      lowestHr: lowestHr ?? this.lowestHr,
      avgHr: avgHr ?? this.avgHr,
      highestSpO2: highestSpO2 ?? this.highestSpO2,
      lowestSpO2: lowestSpO2 ?? this.lowestSpO2,
      avgSpO2: avgSpO2 ?? this.avgSpO2,
      hrHistory: hrHistory ?? this.hrHistory,
      spO2History: spO2History ?? this.spO2History,
      recentReadings: recentReadings ?? this.recentReadings,
      alertEvents: alertEvents ?? this.alertEvents,
      sessionHistories: sessionHistories ?? this.sessionHistories,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

import 'alert_item.dart';

class PatientReading {
  final String time;
  final int hrBpm;
  final int spO2;
  final String status; // "OK", "NORMAL", "WARN", "CRITICAL"
  final AlertSeverity severity;

  const PatientReading({
    required this.time,
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

class Patient {
  final String id;
  final String name;
  final String initials;
  final String chair;
  final String department;
  final String session;
  final String date;
  final String startTime;
  final String primaryNurse;
  final String duration;
  final String sessionStatus; // "ONGOING", "COMPLETED"
  final AlertSeverity status;
  final int currentHr;
  final int currentSpO2;
  final List<double> hrHistory;
  final List<double> spO2History;
  final List<PatientReading> recentReadings;
  final List<PatientLogEvent> alertEvents;
  final String? avatarUrl;

  const Patient({
    required this.id,
    required this.name,
    required this.initials,
    required this.chair,
    required this.department,
    required this.session,
    required this.date,
    required this.startTime,
    required this.primaryNurse,
    required this.duration,
    required this.sessionStatus,
    required this.status,
    required this.currentHr,
    required this.currentSpO2,
    required this.hrHistory,
    required this.spO2History,
    required this.recentReadings,
    required this.alertEvents,
    this.avatarUrl,
  });
}

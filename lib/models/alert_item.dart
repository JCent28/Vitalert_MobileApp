enum AlertSeverity {
  critical,
  warning,
  info,
}

class AlertItem {
  final String id;
  final String patientId;
  final String patientName;
  final String chairLocation;
  final String wardArea;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String timeString; // e.g. "14:32"
  final int? hrBpm;
  final int? spO2;
  bool isAcknowledged;
  String? acknowledgedBy;
  String? acknowledgedAt;
  String? note;

  AlertItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.chairLocation,
    required this.wardArea,
    required this.severity,
    required this.title,
    required this.message,
    required this.timeString,
    this.hrBpm,
    this.spO2,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.note,
  });

  void acknowledge({required String nurseName, required String time}) {
    isAcknowledged = true;
    acknowledgedBy = nurseName;
    acknowledgedAt = time;
  }
}

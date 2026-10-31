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
  bool isRecovered;
  bool isEscalated60s;
  String? acknowledgedBy;
  String? acknowledgedById;
  String? acknowledgedAt;
  String? note;
  final int? timestamp;
  final String? session;

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
    this.isRecovered = false,
    this.isEscalated60s = false,
    this.acknowledgedBy,
    this.acknowledgedById,
    this.acknowledgedAt,
    this.note,
    this.timestamp,
    this.session,
  });

  /// Returns the normalized timestamp in milliseconds since epoch, or null if unavailable.
  int? get timestampMs {
    final ts = timestamp;
    if (ts == null || ts <= 0) return null;
    return ts < 10000000000 ? ts * 1000 : ts;
  }

  /// Returns true if this alert is unacknowledged and has been open for at least 60 seconds.
  bool isUnresolvedOver60s({DateTime? now}) {
    if (isAcknowledged) return false;
    if (isEscalated60s) return true;
    final ms = timestampMs;
    if (ms == null) return false;
    final currentMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return (currentMs - ms) >= 60000;
  }

  factory AlertItem.fromMap(String id, Map<String, dynamic> map) {
    final sevStr = (map['severity'] ?? 'Warning').toString().toLowerCase();
    final severity = sevStr == 'critical'
        ? AlertSeverity.critical
        : (sevStr == 'warning' ? AlertSeverity.warning : AlertSeverity.info);

    final statusStr = (map['status'] ?? 'Active').toString();
    final lowerStatus = statusStr.toLowerCase();
    final isAcknowledged = lowerStatus == 'acknowledged' || map['is_acknowledged'] == true;
    final isRecovered = map['recovered'] == true ||
        map['is_recovered'] == true ||
        lowerStatus == 'recovered';
    final isEscalated60s = map['escalated_60s'] == true ||
        map['is_escalated'] == true ||
        map['unresolved_60s'] == true;

    int? bpm;
    int? spo2;
    if (map['vitals'] is Map) {
      final vitals = Map<String, dynamic>.from(map['vitals']);
      bpm = (vitals['bpm'] as num?)?.toInt();
      spo2 = (vitals['spo2'] as num?)?.toInt();
    }

    int? parsedTimestamp;
    final rawTs = map['timestamp'];
    if (rawTs != null) {
      if (rawTs is num) {
        parsedTimestamp = rawTs.toInt();
      } else if (rawTs is String) {
        final asNum = num.tryParse(rawTs);
        if (asNum != null) {
          parsedTimestamp = asNum.toInt();
        } else {
          final asDate = DateTime.tryParse(rawTs);
          if (asDate != null) {
            parsedTimestamp = asDate.millisecondsSinceEpoch ~/ 1000;
          }
        }
      }
    }

    final rawName = map['patient_name']?.toString().trim();
    final patientName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : 'Unknown';

    final rawChair = map['chair']?.toString().trim();
    final chairLocation = (rawChair != null && rawChair.isNotEmpty)
        ? rawChair
        : 'Unknown';

    final rawStation = map['station']?.toString().trim();
    final wardArea = (rawStation != null && rawStation.isNotEmpty)
        ? rawStation
        : 'Unknown';

    return AlertItem(
      id: id,
      patientId: map['patient_id']?.toString().trim() ?? '',
      patientName: patientName,
      chairLocation: chairLocation,
      wardArea: wardArea,
      severity: severity,
      title: severity == AlertSeverity.critical
          ? 'CRITICAL ALERT'
          : 'WARNING ALERT',
      message: map['message']?.toString() ?? '',
      timeString: map['triggered_at']?.toString() ?? '00:00',
      hrBpm: bpm,
      spO2: spo2,
      isAcknowledged: isAcknowledged,
      isRecovered: isRecovered,
      isEscalated60s: isEscalated60s,
      acknowledgedBy: map['acknowledged_by']?.toString(),
      acknowledgedById: map['acknowledged_by_id']?.toString(),
      acknowledgedAt: map['acknowledged_at']?.toString(),
      note: map['note']?.toString(),
      timestamp: parsedTimestamp,
      session: map['session']?.toString() ??
          map['session_num']?.toString() ??
          map['session_id']?.toString(),
    );
  }

  /// Compares alerts newest first: sorts by [timestamp] descending,
  /// falling back to [id] descending if timestamp is missing or equal.
  static int compareNewestFirst(AlertItem a, AlertItem b) {
    final aTs = a.timestamp;
    final bTs = b.timestamp;

    if (aTs != null && bTs != null) {
      final aNorm = (aTs > 0 && aTs < 10000000000) ? aTs * 1000 : aTs;
      final bNorm = (bTs > 0 && bTs < 10000000000) ? bTs * 1000 : bTs;
      final cmp = bNorm.compareTo(aNorm);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    }

    if (aTs != null && bTs == null) {
      return -1; // a has timestamp, newer first
    }

    if (aTs == null && bTs != null) {
      return 1; // b has timestamp, newer first
    }

    // Both missing timestamp: fall back to key
    return b.id.compareTo(a.id);
  }

  void acknowledge({
    required String nurseName,
    required String time,
    String? nurseId,
  }) {
    isAcknowledged = true;
    acknowledgedBy = nurseName;
    acknowledgedAt = time;
    if (nurseId != null && nurseId.isNotEmpty) {
      acknowledgedById = nurseId;
    }
  }
}

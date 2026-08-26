class DeviceModel {
  final String deviceId;
  final String status; // 'AVAILABLE', 'IN_USE', 'UNAVAILABLE'
  final int bpm;
  final int spo2;
  final String lastUpdated;

  const DeviceModel({
    required this.deviceId,
    required this.status,
    this.bpm = 0,
    this.spo2 = 0,
    this.lastUpdated = '',
  });

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';
  bool get isInUse => status.toUpperCase() == 'IN_USE' || status.toUpperCase() == 'IN USE';
  bool get isUnavailable => status.toUpperCase() == 'UNAVAILABLE';

  String get displayStatus {
    if (isInUse) return 'IN_USE';
    if (isAvailable) return 'AVAILABLE';
    return 'UNAVAILABLE';
  }

  factory DeviceModel.fromMap(String id, Map<String, dynamic> data) {
    return DeviceModel(
      deviceId: id,
      status: (data['status'] ?? 'AVAILABLE').toString().toUpperCase().replaceAll(' ', '_'),
      bpm: (data['bpm'] as num?)?.toInt() ?? 0,
      spo2: (data['spo2'] as num?)?.toInt() ?? 0,
      lastUpdated: data['last_updated']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'status': status,
      'bpm': bpm,
      'spo2': spo2,
      'last_updated': lastUpdated,
    };
  }
}

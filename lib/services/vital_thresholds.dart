import '../models/alert_item.dart';

class VitalThresholds {
  // SpO2 Thresholds
  static const double criticalMinSpo2 = 90.0;
  static const double warningMinSpo2 = 95.0;

  // Heart Rate Thresholds
  static const double criticalMaxHr = 120.0;
  static const double warningMaxHr = 100.0;
  static const double warningMinHr = 60.0;  // Warning low: 50–59 bpm (hr < 60)
  static const double criticalMinHr = 50.0; // Critical low: < 50 bpm

  // Safe Ranges
  static const String hrSafeRangeText = '60 – 100 bpm';
  static const String spo2SafeRangeText = '≥ 95%';

  /// Analyzes heart rate and SpO2 to return the clinical alert severity
  static AlertSeverity evaluateVitals(int hr, int spO2) {
    final isCrit = hr > criticalMaxHr || hr < criticalMinHr || spO2 < criticalMinSpo2;
    if (isCrit) return AlertSeverity.critical;

    final isWarn = hr > warningMaxHr || hr < warningMinHr || spO2 < warningMinSpo2;
    if (isWarn) return AlertSeverity.warning;

    return AlertSeverity.info;
  }

  /// Generates clinical summary description for an alert
  static String generateAlertMessage({required int hr, required int spO2}) {
    final List<String> messages = [];

    if (spO2 < criticalMinSpo2) {
      messages.add('Critical SpO₂ dropped to $spO2% (Threshold: < ${criticalMinSpo2.toInt()}%)');
    } else if (spO2 < warningMinSpo2) {
      messages.add('SpO₂ decreased to $spO2% (Threshold: < ${warningMinSpo2.toInt()}%)');
    }

    if (hr > criticalMaxHr) {
      messages.add('Critical Tachycardia: BPM elevated to $hr (Threshold: > ${criticalMaxHr.toInt()})');
    } else if (hr > warningMaxHr) {
      messages.add('BPM elevated to $hr bpm (Threshold: > ${warningMaxHr.toInt()})');
    } else if (hr < criticalMinHr) {
      messages.add('Critical Bradycardia: BPM dropped to $hr (Threshold: < ${criticalMinHr.toInt()})');
    } else if (hr < warningMinHr) {
      messages.add('Low BPM: $hr bpm (Warning range: ${criticalMinHr.toInt()}–${(warningMinHr - 1).toInt()} bpm)');
    }

    return messages.isNotEmpty ? messages.join(' • ') : 'Vitals within normal limits';
  }
}

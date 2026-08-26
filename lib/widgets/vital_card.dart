import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../theme/app_theme.dart';
import 'ecg_waveform_painter.dart';

class VitalTelemetryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String unit;
  final AlertSeverity severity;
  final bool isHeartRate;

  const VitalTelemetryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.severity,
    this.isHeartRate = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color badgeBg;
    final Color badgeTextColor;
    final Color iconColor;
    final Color valueColor;
    final String badgeLabel;

    switch (severity) {
      case AlertSeverity.critical:
        borderColor = AppColors.error;
        badgeBg = AppColors.errorBg;
        badgeTextColor = AppColors.error;
        iconColor = AppColors.error;
        valueColor = AppColors.error;
        badgeLabel = 'CRITICAL';
        break;
      case AlertSeverity.warning:
        borderColor = AppColors.tertiaryContainer;
        badgeBg = AppColors.tertiaryContainerBg;
        badgeTextColor = AppColors.tertiaryContainer;
        iconColor = AppColors.tertiaryContainer;
        valueColor = AppColors.onSurface;
        badgeLabel = 'WARNING';
        break;
      case AlertSeverity.info:
        borderColor = AppColors.borderLight;
        badgeBg = AppColors.normalGreenBg;
        badgeTextColor = AppColors.secondary;
        iconColor = AppColors.secondary;
        valueColor = AppColors.onSurface;
        badgeLabel = 'NORMAL';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: severity == AlertSeverity.critical ? 2.0 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background telemetry waveform
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 50,
            child: Opacity(
              opacity: 0.20,
              child: CustomPaint(
                painter: isHeartRate
                    ? EcgWaveformPainter(color: iconColor, strokeWidth: 1.5)
                    : SpO2WaveformPainter(color: iconColor, strokeWidth: 1.5),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelCaps(
                                color: iconColor,
                                fontSize: 12,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.labelCaps(
                          color: badgeTextColor,
                          fontSize: 11,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Vitals readout
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: AppTypography.displayVitals(color: valueColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unit,
                        style: AppTypography.bodyLg(
                          color: severity == AlertSeverity.critical
                              ? AppColors.error
                              : AppColors.onSurfaceVariant,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

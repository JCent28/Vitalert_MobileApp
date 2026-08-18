import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/vital_card.dart';

class PatientVitalsScreen extends StatefulWidget {
  final AppState state;
  final String patientId;
  final VoidCallback onBack;
  final VoidCallback onViewFullLog;

  const PatientVitalsScreen({
    super.key,
    required this.state,
    required this.patientId,
    required this.onBack,
    required this.onViewFullLog,
  });

  @override
  State<PatientVitalsScreen> createState() => _PatientVitalsScreenState();
}

class _PatientVitalsScreenState extends State<PatientVitalsScreen> {
  bool _isAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.state.patients.firstWhere(
      (p) => p.id == widget.patientId,
      orElse: () => widget.state.patients.first,
    );

    final isCritical = patient.status == AlertSeverity.critical;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        showBack: true,
        onBack: widget.onBack,
        showLivePulse: true,
        isLiveCritical: isCritical,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  // Patient Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: patient.avatarUrl != null
                        ? Image.network(
                            patient.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                patient.initials,
                                style: AppTypography.headlineMd(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              patient.initials,
                              style: AppTypography.headlineMd(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: AppTypography.headlineLg(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${patient.chair} • ${patient.session}',
                          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCritical ? AppColors.errorBg : AppColors.warningAmberBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isCritical ? AppColors.errorBorder : AppColors.warningAmberBorder,
                      ),
                    ),
                    child: Text(
                      isCritical ? 'CRITICAL' : 'WARNING',
                      style: AppTypography.labelCaps(
                        color: isCritical ? AppColors.error : AppColors.tertiary,
                        fontSize: 11,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alert Section Banner (if critical or warning)
            if (!_isAcknowledged) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33BA1A1A),
                      spreadRadius: 2,
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.onErrorContainer,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Critical — Heart Rate',
                                style: AppTypography.headlineMd(
                                  color: AppColors.onErrorContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Threshold exceeded for 30s',
                                style: AppTypography.bodyMd(
                                  color: AppColors.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAcknowledged = true;
                          });
                          widget.state.acknowledgePatientCritical(patient.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Critical alert acknowledged by Rosa M.'),
                              backgroundColor: AppColors.primaryContainer,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.onError,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'ACKNOWLEDGE',
                          style: AppTypography.labelCaps(
                            color: AppColors.onError,
                            fontSize: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.normalGreenBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.normalGreenBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.done_all, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alert acknowledged by Rosa M. at 14:33',
                        style: AppTypography.bodyMd(
                          color: AppColors.secondary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Vitals Metric Cards
            VitalTelemetryCard(
              label: 'HEART RATE',
              icon: Icons.favorite,
              value: '${patient.currentHr}',
              unit: 'BPM',
              severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
              isHeartRate: true,
            ),
            const SizedBox(height: 16),

            VitalTelemetryCard(
              label: 'BLOOD OXYGEN',
              icon: Icons.water_drop_outlined,
              value: '${patient.currentSpO2}',
              unit: '%',
              severity: AlertSeverity.warning,
              isHeartRate: false,
            ),
            const SizedBox(height: 16),

            // Recent Readings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Readings',
                    style: AppTypography.headlineMd(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: patient.recentReadings.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final r = patient.recentReadings[index];
                      final isWarn = r.severity == AlertSeverity.warning;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                r.time,
                                style: AppTypography.metricMono(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    '${r.hrBpm} BPM',
                                    style: AppTypography.metricMono(
                                      color: AppColors.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${r.spO2}%',
                                    style: AppTypography.metricMono(
                                      color: AppColors.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isWarn
                                    ? AppColors.tertiaryContainerBg
                                    : AppColors.normalGreenBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.status,
                                style: AppTypography.labelCaps(
                                  color: isWarn
                                      ? AppColors.tertiaryContainer
                                      : AppColors.primary,
                                  fontSize: 11,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: widget.onViewFullLog,
                      child: Text(
                        'VIEW FULL LOG',
                        style: AppTypography.labelCaps(
                          color: AppColors.primary,
                          fontSize: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

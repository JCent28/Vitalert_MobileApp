import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

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
      ),
      body: SingleChildScrollView(
        padding: context.responsivePagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.textMain,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        patient.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMd(color: AppColors.textMain).copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chair ${patient.chair} • ${patient.session}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCritical ? AppColors.criticalRed : AppColors.warningAmber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCritical ? 'CRITICAL' : 'WARNING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alert Section Banner
            if (!_isAcknowledged) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.criticalRed, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.criticalRed,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Critical SpO₂ & Tachycardia Alert',
                                style: AppTypography.headlineMd(color: AppColors.criticalRed).copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pulse elevated to 125 bpm • SpO₂ at 89%',
                                style: AppTypography.bodyMd(color: AppColors.textMain, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isAcknowledged = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Critical alert acknowledged'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Acknowledge Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.criticalRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // View Full Log CTA
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: widget.onViewFullLog,
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: const Text('View Full Vitals Log & Trends', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

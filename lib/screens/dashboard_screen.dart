import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../models/patient.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/live_pulse_badge.dart';
import '../widgets/sparkline_chart.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final Function(String patientId) onPatientSelected;
  final VoidCallback onSignOut;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onPatientSelected,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Floor Overview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Floor Overview',
                            style: AppTypography.headlineLg(color: AppColors.onSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const LivePulseBadge(isCritical: false),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oct 26, 2023 • 14:32 Local Time',
                      style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Bar Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                // Nurse Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'RM',
                      style: AppTypography.headlineMd(
                        color: AppColors.onPrimaryContainer,
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
                        state.nurseName,
                        style: AppTypography.bodyLg(
                          color: AppColors.onSurface,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Shift: ${state.shiftTime}',
                        style: AppTypography.labelCaps(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: AppColors.borderLight,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.primary),
                  label: Text(
                    'Sign Out',
                    style: AppTypography.bodyMd(
                      color: AppColors.primary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Bento Bar (4 cards in 2x2 on mobile, or 4 cols)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildActivePatientsCard()),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatusSummaryCard('NORMAL', '1', Icons.check_circle, AppColors.secondary, AppColors.normalGreenBg, AppColors.normalGreenBorder)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatusSummaryCard('WARNING', '1', Icons.warning, AppColors.tertiary, AppColors.warningAmberBg, AppColors.warningAmberBorder)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatusSummaryCard('CRITICAL', '1', Icons.emergency, AppColors.error, AppColors.errorBg, AppColors.errorBorder)),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildActivePatientsCard()),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatusSummaryCard('NORMAL', '1', Icons.check_circle, AppColors.secondary, AppColors.normalGreenBg, AppColors.normalGreenBorder)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildStatusSummaryCard('WARNING', '1', Icons.warning, AppColors.tertiary, AppColors.warningAmberBg, AppColors.warningAmberBorder)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatusSummaryCard('CRITICAL', '1', Icons.emergency, AppColors.error, AppColors.errorBg, AppColors.errorBorder)),
                          ],
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Patient Roster Title
          Text(
            'Patient Roster',
            style: AppTypography.headlineMd(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),

          // Patient Roster Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.patients.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final patient = state.patients[index];
              return _buildPatientCard(context, patient);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActivePatientsCard() {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ACTIVE PATIENTS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelCaps(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.group_outlined, size: 18, color: AppColors.onSurfaceVariant),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('3', style: AppTypography.headlineLg(color: AppColors.onSurface)),
                Text('/3 Capacity', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryCard(
    String label,
    String count,
    IconData icon,
    Color color,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelCaps(
                  color: color,
                  fontSize: 10,
                  weight: FontWeight.w700,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(count, style: AppTypography.headlineLg(color: color)),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    final Color statusColor;
    final Color badgeBg;
    final String badgeText;
    final IconData badgeIcon;
    final Color hrColor;

    switch (patient.status) {
      case AlertSeverity.critical:
        statusColor = AppColors.error;
        badgeBg = AppColors.errorBg;
        badgeText = 'CRITICAL';
        badgeIcon = Icons.emergency;
        hrColor = AppColors.error;
        break;
      case AlertSeverity.warning:
        statusColor = AppColors.tertiary;
        badgeBg = AppColors.warningAmberBg;
        badgeText = 'WARNING';
        badgeIcon = Icons.warning;
        hrColor = AppColors.tertiary;
        break;
      case AlertSeverity.info:
        statusColor = AppColors.secondary;
        badgeBg = AppColors.normalGreenBg;
        badgeText = 'NORMAL';
        badgeIcon = Icons.check_circle;
        hrColor = AppColors.secondary;
        break;
    }

    return InkWell(
      onTap: () => onPatientSelected(patient.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left urgency status accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: statusColor),
            ),

            // Card content with left padding to offset accent bar
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: Patient Info Row
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              patient.initials,
                              style: AppTypography.headlineMd(
                                color: AppColors.onSurfaceVariant,
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
                                style: AppTypography.bodyLg(
                                  color: AppColors.onSurface,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${patient.chair} • ${patient.department}',
                                style: AppTypography.bodyMd(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                badgeText,
                                style: AppTypography.labelCaps(
                                  color: statusColor,
                                  fontSize: 10,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  const Divider(height: 1, color: AppColors.borderLight),

                  // Bottom: Telemetry metrics side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BPM
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: AppColors.borderLight, width: 1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'HEART RATE',
                                    style: AppTypography.labelCaps(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Icon(Icons.favorite, size: 14, color: hrColor),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${patient.currentHr}',
                                    style: AppTypography.displayVitals(color: hrColor).copyWith(fontSize: 32, height: 1.1),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'bpm',
                                    style: AppTypography.metricMono(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BarSparkline(
                                values: patient.hrHistory,
                                barColor: hrColor,
                                opacity: 0.6,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SpO2
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'O2 SATURATION',
                                    style: AppTypography.labelCaps(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const Icon(Icons.air, size: 14, color: AppColors.onSurfaceVariant),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${patient.currentSpO2}',
                                    style: AppTypography.displayVitals(color: AppColors.onSurface).copyWith(fontSize: 32, height: 1.1),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '%',
                                    style: AppTypography.metricMono(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BarSparkline(
                                values: patient.spO2History,
                                barColor: AppColors.onSurface,
                                opacity: 0.25,
                                height: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

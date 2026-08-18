import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PatientLogScreen extends StatelessWidget {
  final AppState state;
  final Function(String patientId) onPatientSelected;

  const PatientLogScreen({
    super.key,
    required this.state,
    required this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    final patient = state.selectedPatient;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Patient Selector Pills
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.patients.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final p = state.patients[index];
                final isSelected = p.id == patient.id;

                return InkWell(
                  onTap: () => onPatientSelected(p.id),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceContainer : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.person, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          p.name,
                          style: AppTypography.bodyMd(
                            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                            weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Selected Patient Summary Card
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: AppTypography.headlineMd(color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${patient.session} - ${patient.date}',
                            style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.normalGreenBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.normalGreenBorder),
                      ),
                      child: Text(
                        patient.sessionStatus,
                        style: AppTypography.labelCaps(
                          color: AppColors.secondary,
                          fontSize: 11,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 4 metadata fields (2x2 grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaItem('LOCATION', patient.chair),
                    ),
                    Expanded(
                      child: _buildMetaItem('START TIME', patient.startTime),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaItem('PRIMARY NURSE', patient.primaryNurse),
                    ),
                    Expanded(
                      child: _buildMetaItem('DURATION', patient.duration),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hourly Readings Table Section
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Hourly Readings',
                style: AppTypography.headlineMd(color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table Header
                Container(
                  color: AppColors.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'TIME',
                          style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'HR (BPM)',
                          style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'SpO2 (%)',
                          style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'STATUS',
                          style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),

                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patient.recentReadings.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (context, index) {
                    final r = patient.recentReadings[index];
                    final isWarn = r.severity == AlertSeverity.warning;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              r.time,
                              style: AppTypography.metricMono(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${r.hrBpm}',
                              style: AppTypography.metricMono(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${r.spO2}',
                              style: AppTypography.metricMono(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isWarn ? AppColors.warningAmberBg : AppColors.normalGreenBg,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  isWarn ? 'WARNING' : 'NORMAL',
                                  style: AppTypography.labelCaps(
                                    color: isWarn ? AppColors.tertiary : AppColors.secondary,
                                    fontSize: 10,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Alert Events Section
          if (patient.alertEvents.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'Alert Events',
                  style: AppTypography.headlineMd(color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Timeline Container
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Stack(
                children: [
                  // Vertical timeline line
                  Positioned(
                    top: 12,
                    bottom: 12,
                    left: 7,
                    child: Container(
                      width: 2,
                      color: AppColors.borderLight,
                    ),
                  ),

                  // Events list
                  Column(
                    children: patient.alertEvents.map((evt) {
                      final isCritical = evt.severity == AlertSeverity.critical;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline dot
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isCritical ? AppColors.error : AppColors.tertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Event Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCritical ? AppColors.errorBorder : AppColors.borderLight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              evt.time,
                                              style: AppTypography.bodyMd(
                                                color: AppColors.onSurface,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isCritical ? AppColors.errorBg : AppColors.warningAmberBg,
                                                borderRadius: BorderRadius.circular(100),
                                              ),
                                              child: Text(
                                                isCritical ? 'CRITICAL' : 'WARNING',
                                                style: AppTypography.labelCaps(
                                                  color: isCritical ? AppColors.error : AppColors.tertiary,
                                                  fontSize: 10,
                                                  weight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${evt.hrBpm} BPM',
                                              style: AppTypography.metricMono(
                                                color: isCritical ? AppColors.error : AppColors.tertiary,
                                                weight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${evt.spO2}% SpO2',
                                              style: AppTypography.metricMono(
                                                color: isCritical ? AppColors.error : AppColors.onSurface,
                                                weight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      evt.description,
                                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                                    ),
                                    if (evt.acknowledgementNote != null) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                evt.acknowledgementNote!,
                                                style: AppTypography.bodyMd(
                                                  color: AppColors.onSurfaceVariant,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCaps(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyLg(
            color: AppColors.onSurface,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

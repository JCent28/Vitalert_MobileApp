import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  final AppState state;
  final Function(String patientId) onPatientSelected;

  const AlertsScreen({
    super.key,
    required this.state,
    required this.onPatientSelected,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final activeAlerts = widget.state.activeAlerts;
    final acknowledgedAlerts = widget.state.acknowledgedAlerts;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts',
                    style: AppTypography.headlineLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today, Oct 24',
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.primary),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Filter alerts: All beds selected'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                splashRadius: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Active tab
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _showActive = true),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _showActive ? AppColors.surfaceContainerLowest : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Active',
                            style: AppTypography.labelCaps(
                              color: _showActive ? AppColors.primary : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: activeAlerts.isNotEmpty ? AppColors.error : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${activeAlerts.length}',
                              style: AppTypography.labelCaps(
                                color: activeAlerts.isNotEmpty ? AppColors.onError : AppColors.onSurfaceVariant,
                                fontSize: 10,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Acknowledged tab
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _showActive = false),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showActive ? AppColors.surfaceContainerLowest : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Acknowledged',
                            style: AppTypography.labelCaps(
                              color: !_showActive ? AppColors.primary : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${acknowledgedAlerts.length}',
                              style: AppTypography.labelCaps(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content List
          if (_showActive) ...[
            if (activeAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48, color: AppColors.secondary),
                    const SizedBox(height: 12),
                    Text(
                      'No Active Alerts',
                      style: AppTypography.headlineMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All patient telemetry is within normal baseline thresholds.',
                      style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeAlerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = activeAlerts[index];
                  return _buildActiveAlertCard(context, alert);
                },
              ),
          ] else ...[
            if (acknowledgedAlerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Text(
                  'No Acknowledged Alerts',
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: acknowledgedAlerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final alert = acknowledgedAlerts[index];
                  return _buildAcknowledgedAlertCard(context, alert, isSecond: index > 0);
                },
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActiveAlertCard(BuildContext context, AlertItem alert) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left urgency accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: AppColors.error),
          ),

          // Faint background watermark icon
          const Positioned(
            top: 8,
            right: 8,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.warning_rounded,
                size: 96,
                color: AppColors.error,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Top row with badge and time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, size: 14, color: AppColors.onErrorContainer),
                                  const SizedBox(width: 4),
                                  Text(
                                    'CRITICAL',
                                    style: AppTypography.labelCaps(
                                      color: AppColors.onErrorContainer,
                                      fontSize: 11,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: AppColors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  alert.timeString,
                                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Patient Name & Location
                        InkWell(
                          onTap: () => widget.onPatientSelected(alert.patientId),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.patientName,
                                style: AppTypography.headlineMd(color: AppColors.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${alert.chairLocation} • ${alert.wardArea}',
                                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Status alert message
                        Row(
                          children: [
                            const Icon(Icons.trending_down, size: 20, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              alert.message,
                              style: AppTypography.bodyLg(
                                color: AppColors.error,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Acknowledge action button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.state.acknowledgeAlert(alert.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Alert for ${alert.patientName} acknowledged'),
                                  backgroundColor: AppColors.primaryContainer,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: Text(
                              'Acknowledge',
                              style: AppTypography.bodyLg(
                                color: AppColors.onPrimary,
                                weight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAcknowledgedAlertCard(BuildContext context, AlertItem alert, {bool isSecond = false}) {
    return Opacity(
      opacity: isSecond ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainerBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'WARNING',
                    style: AppTypography.labelCaps(
                      color: AppColors.tertiary,
                      fontSize: 11,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  alert.timeString,
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Patient details
            Text(
              alert.patientName,
              style: AppTypography.headlineMd(color: AppColors.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              '${alert.chairLocation} • ${alert.wardArea}',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              alert.message,
              style: AppTypography.bodyMd(color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),

            // Acknowledgment info footer
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.done_all, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Acknowledged by ${alert.acknowledgedBy ?? "Rosa M."} at ${alert.acknowledgedAt ?? "12:18"}',
                      style: AppTypography.bodyMd(
                        color: AppColors.secondary,
                        weight: FontWeight.w500,
                      ),
                    ),
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

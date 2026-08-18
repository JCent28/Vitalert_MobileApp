import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'live_pulse_badge.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final bool showLivePulse;
  final bool isLiveCritical;
  final String? subtitle;
  final VoidCallback? onSensorsTap;

  const AppTopBar({
    super.key,
    this.onBack,
    this.showBack = true,
    this.showLivePulse = false,
    this.isLiveCritical = false,
    this.subtitle,
    this.onSensorsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Back button or empty
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  splashRadius: 24,
                  tooltip: 'Back',
                )
              else
                const SizedBox(width: 48),

              // Center: VITALERT logo or Title with subtitle
              if (subtitle != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VITALERT',
                      style: AppTypography.headlineMd(color: AppColors.primary),
                    ),
                    Text(
                      subtitle!,
                      style: AppTypography.labelCaps(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'VITALERT',
                  style: AppTypography.headlineMd(color: AppColors.primary),
                ),

              // Right: Status / Sensors
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLivePulse) ...[
                    LivePulseBadge(isCritical: isLiveCritical),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: const Icon(Icons.sensors, color: AppColors.onSurfaceVariant),
                    onPressed: onSensorsTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Telemetry sensors connected (100% signal)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                    splashRadius: 24,
                    tooltip: 'Telemetry Sensors',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

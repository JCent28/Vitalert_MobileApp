import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSignOut;
  final int activeAlertCount;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onSignOut,
    this.activeAlertCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isVerySmall = context.isVerySmallPhone;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 6),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 0,
                  label: 'Dashboard',
                  icon: Icons.pie_chart_outline_rounded,
                  activeIcon: Icons.pie_chart_rounded,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 1,
                  label: 'Alerts',
                  icon: Icons.warning_amber_rounded,
                  activeIcon: Icons.warning_rounded,
                  badgeCount: activeAlertCount,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 2,
                  label: 'Vitals Log',
                  icon: Icons.monitor_heart_outlined,
                  activeIcon: Icons.monitor_heart_rounded,
                ),
              ),
              if (onSignOut != null)
                Expanded(
                  child: InkWell(
                    onTap: onSignOut,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.textMuted,
                            size: isVerySmall ? 19 : 22,
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Sign Out',
                              maxLines: 1,
                              style: AppTypography.labelCaps(
                                color: AppColors.textMuted,
                                fontSize: isVerySmall ? 9 : 10,
                                weight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMuted;
    final isVerySmall = context.isVerySmallPhone;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: isVerySmall ? 19 : 22,
                ),
                if (badgeCount > 0 && index == 1)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.criticalRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTypography.labelCaps(
                  color: color,
                  fontSize: isVerySmall ? 9 : 10,
                  weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final bool showBack;
  final VoidCallback? onLiveTap;
  final VoidCallback? onAlertsTap;
  final VoidCallback? onSignOutTap;

  const AppTopBar({
    super.key,
    this.onBack,
    this.showBack = false,
    this.onLiveTap,
    this.onAlertsTap,
    this.onSignOutTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isVerySmall = context.isVerySmallPhone;
    final isSmall = context.isSmallPhone;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 8 : (isSmall ? 12 : 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Back button or Logo + Title
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBack) ...[
                      InkWell(
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                    // Logo Icon
                    Container(
                      width: isVerySmall ? 28 : 34,
                      height: isVerySmall ? 28 : 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withAlpha(40)),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.monitor_heart,
                          size: isVerySmall ? 16 : 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: isVerySmall ? 6 : 10),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VITALERT',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTypography.headlineMd(
                              color: AppColors.textMain,
                            ).copyWith(
                              fontSize: isVerySmall ? 14 : 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'NephroAsia Dialysis Center',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTypography.bodyMd(
                              color: AppColors.textMuted,
                              fontSize: isVerySmall ? 9 : 10,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right: LIVE Pill + Bell + Sign Out
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LIVE Pill
                  InkWell(
                    onTap: onLiveTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 6 : 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.normalGreenBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.normalGreenBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.normalGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: AppTypography.labelCaps(
                              color: AppColors.normalGreen,
                              fontSize: isVerySmall ? 9.5 : 10.5,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: isVerySmall ? 4 : 6),

                  // Bell with dot
                  InkWell(
                    onTap: onAlertsTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(isVerySmall ? 4.0 : 6.0),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: isVerySmall ? 19 : 22,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Positioned(
                          top: isVerySmall ? 2 : 4,
                          right: isVerySmall ? 2 : 4,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.criticalRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sign out icon
                  if (onSignOutTap != null)
                    InkWell(
                      onTap: onSignOutTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(isVerySmall ? 4.0 : 6.0),
                        child: Icon(
                          Icons.logout_rounded,
                          size: isVerySmall ? 18 : 20,
                          color: AppColors.textMuted,
                        ),
                      ),
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

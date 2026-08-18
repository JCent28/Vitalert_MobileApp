import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LivePulseBadge extends StatefulWidget {
  final bool isCritical;
  final bool isWarning;

  const LivePulseBadge({
    super.key,
    this.isCritical = false,
    this.isWarning = false,
  });

  @override
  State<LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeBg;
    final Color dotColor;
    final Color textColor;

    if (widget.isCritical) {
      badgeBg = AppColors.errorContainer;
      dotColor = AppColors.error;
      textColor = AppColors.onErrorContainer;
    } else if (widget.isWarning) {
      badgeBg = AppColors.warningAmberBg;
      dotColor = AppColors.warningAmber;
      textColor = AppColors.tertiary;
    } else {
      badgeBg = AppColors.normalGreenBg;
      dotColor = AppColors.secondary;
      textColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: AppTypography.labelCaps(
              color: textColor,
              fontSize: 11,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

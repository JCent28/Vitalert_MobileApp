import 'package:flutter/material.dart';

class BarSparkline extends StatelessWidget {
  final List<double> values;
  final Color barColor;
  final double opacity;
  final double height;

  const BarSparkline({
    super.key,
    required this.values,
    required this.barColor,
    this.opacity = 0.5,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final normalizedMax = maxVal <= 0 ? 1.0 : maxVal;

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: values.map((val) {
            final frac = (val / normalizedMax).clamp(0.15, 1.0);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: height * frac,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

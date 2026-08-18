import 'package:flutter/material.dart';

class EcgWaveformPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  EcgWaveformPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Normalize coordinates from SVG: 0-100 x, 0-50 y
    // Base ECG rhythm pattern:
    // [0, 40], [10, 40], [15, 10], [25, 50], [35, 40], [45, 40], [50, 20], [60, 45], [70, 40], [80, 40], [85, 15], [95, 45], [100, 40]
    final points = [
      Offset(0.00 * w, 0.80 * h),
      Offset(0.10 * w, 0.80 * h),
      Offset(0.15 * w, 0.20 * h),
      Offset(0.25 * w, 1.00 * h),
      Offset(0.35 * w, 0.80 * h),
      Offset(0.45 * w, 0.80 * h),
      Offset(0.50 * w, 0.40 * h),
      Offset(0.60 * w, 0.90 * h),
      Offset(0.70 * w, 0.80 * h),
      Offset(0.80 * w, 0.80 * h),
      Offset(0.85 * w, 0.30 * h),
      Offset(0.95 * w, 0.90 * h),
      Offset(1.00 * w, 0.80 * h),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EcgWaveformPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}

class SpO2WaveformPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  SpO2WaveformPainter({
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.6);
    // Smooth quadratic bezier waves across width
    path.quadraticBezierTo(w * 0.25, h * 0.7, w * 0.5, h * 0.6);
    path.quadraticBezierTo(w * 0.75, h * 0.5, w * 1.0, h * 0.6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpO2WaveformPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

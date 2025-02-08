
import 'dart:math';
import 'package:flutter/material.dart';


class WheelPainter extends CustomPainter {
  final List<String> options;

  WheelPainter(this.options);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double sweepAngle = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      paint.color = Colors.primaries[i % Colors.primaries.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

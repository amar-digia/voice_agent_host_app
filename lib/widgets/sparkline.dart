import 'dart:math';

import 'package:flutter/material.dart';

/// A minimal line chart with an optional gradient fill underneath.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.points,
    required this.color,
    this.strokeWidth = 1.5,
    this.fill = false,
  });

  final List<double> points;
  final Color color;
  final double strokeWidth;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(points, color, strokeWidth, fill),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.points, this.color, this.strokeWidth, this.fill);

  final List<double> points;
  final Color color;
  final double strokeWidth;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minY = points.reduce(min);
    final maxY = points.reduce(max);
    final range = maxY - minY == 0 ? 1 : maxY - minY;
    // Keep the stroke from being clipped at the top and bottom edges.
    final inset = strokeWidth;
    final height = size.height - inset * 2;
    final dx = size.width / (points.length - 1);

    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = inset + height - (points[i] - minY) / range * height;
      i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }

    if (fill) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.color != color || old.fill != fill;
}

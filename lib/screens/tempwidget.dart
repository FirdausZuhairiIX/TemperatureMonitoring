import 'package:flutter/material.dart';
import 'dart:math';

class HalfCircleTemperatureIndicator extends StatelessWidget {
  final double temperature;
  final double minTemperature = 36.0;
  final double maxTemperature = 40.0;

  HalfCircleTemperatureIndicator({required this.temperature});

  @override
  Widget build(BuildContext context) {
    // Calculate the progress based on temperature
    double progress = (temperature - minTemperature) / (maxTemperature - minTemperature);

    return CustomPaint(
      size: Size(200, 100),
      painter: HalfCirclePainter(progress),
    );
  }
}

class HalfCirclePainter extends CustomPainter {
  final double progress;
  HalfCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final Paint foregroundPaint = Paint()
      ..color = progress > 0.8 ? Colors.red : Colors.green // Color changes if temperature exceeds 37°C
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Draw background half circle
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width / 2, size.height), radius: size.width / 2),
        pi, pi, false, backgroundPaint);

    // Draw progress half circle
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width / 2, size.height), radius: size.width / 2),
        pi, pi * progress, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

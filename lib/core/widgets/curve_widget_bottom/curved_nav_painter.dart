import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';

class CurvedNavPainter extends CustomPainter {
  Color color;
  late double loc;
  TextDirection textDirection;
  final double indicatorSize;

  final Color indicatorColor;
  double borderRadius;

  CurvedNavPainter({
    required double startingLoc,
    required int itemsLength,
    required this.color,
    required this.textDirection,
    this.indicatorColor = Colors.lightBlue,
    this.indicatorSize = 5,
    this.borderRadius = 25,
  }) {
    loc = 1.0 / itemsLength * (startingLoc + 0.48);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    const s = 0.07;
    const depth = 0.20;
    // Tăng valleyWith để tạo khoảng cách rộng hơn cho indicator
    final valleyWith = indicatorSize + 7;

    final path = Path()
      // top Left Corner
      ..moveTo(0, borderRadius)
      ..quadraticBezierTo(0, 0, borderRadius, 0)
      ..lineTo(loc * width - valleyWith * 2, 0)
      ..cubicTo(
        (loc + s * 0.20) * size.width - valleyWith,
        size.height * 0.05,
        loc * size.width - valleyWith,
        size.height * depth,
        (loc + s * 0.50) * size.width - valleyWith,
        size.height * depth,
      )
      ..cubicTo(
        (loc + s * 0.20) * size.width + valleyWith,
        size.height * depth,
        loc * size.width + valleyWith,
        0,
        (loc + s * 0.60) * size.width + valleyWith,
        0,
      )

      // top right corner
      ..lineTo(size.width - borderRadius, 0)
      ..quadraticBezierTo(width, 0, width, borderRadius)

      // bottom right corner
      ..lineTo(width, height - borderRadius)
      ..quadraticBezierTo(width, height, width - borderRadius, height)

      // bottom left corner
      ..lineTo(borderRadius, height)
      ..quadraticBezierTo(0, height, 0, height - borderRadius)
      ..close();

    // Vẽ shadow cho path
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, shadowPaint);

    // Vẽ path chính
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Get gradient colors from DynamicThemeService
    final dotGradientColors = DynamicThemeService.shared.getDotGradientColors();
    final dotGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dotGradientColors,
    );

    // Create gradient paint for the indicator circle
    final circleCenter = Offset(loc * width + 2, indicatorSize);
    final circleRect =
        Rect.fromCircle(center: circleCenter, radius: indicatorSize);
    final circlePaint = Paint()
      ..shader = dotGradient.createShader(circleRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(circleCenter, indicatorSize, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class DottedBorderWrapper extends StatelessWidget {
  const DottedBorderWrapper({
    super.key,
    required this.borderColor,
    required this.borderRadius,
    required this.child,
    this.dashPattern,
    this.strokeWidth,
    this.padding,
  });

  final Color borderColor;
  final double borderRadius;
  final Widget child;
  final List<double>? dashPattern;
  final double? strokeWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        padding: padding ?? EdgeInsets.zero,
        color: borderColor,
        strokeWidth: strokeWidth ?? 2,
        dashPattern: dashPattern ?? const [8, 4],
        radius: Radius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

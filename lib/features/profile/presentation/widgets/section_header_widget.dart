import 'package:flutter/material.dart';
import '../../../../core/constants/export_constants.dart';

/// Widget hiển thị header cho một section (ví dụ: "General")
class SectionHeaderWidget extends StatelessWidget {
  const SectionHeaderWidget({
    super.key,
    required this.title,
    this.padding,
  });

  final String title;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.only(
            left: AppSizes.spacingM,
            right: AppSizes.spacingM,
            top: AppSizes.spacingL,
            bottom: AppSizes.spacingM,
          ),
      child: Text(
        title,
        style: kTextHeadingStyle.copyWith(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

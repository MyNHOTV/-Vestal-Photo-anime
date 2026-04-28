import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import '../../constants/export_constants.dart';

enum IconPosition {
  left,
  right,
}

class ArtItemWidget extends StatelessWidget {
  const ArtItemWidget({
    super.key,
    this.icon,
    this.text,
    this.onTap,
    this.padding,
    this.iconSize,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.border,
    this.spacing,
    this.iconPosition = IconPosition.left,
    this.badgeHeight,
  });

  final Widget? icon;
  final String? text;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final BoxBorder? border;
  final double? spacing;
  final IconPosition iconPosition;
  final double? badgeHeight;

  bool get _isIconOnly => icon != null && (text == null || text!.isEmpty);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _isIconOnly ? _buildIconOnly() : _buildWithContent(),
    );
  }

  Widget _buildIconOnly() {
    final containerSize = badgeHeight ?? AppSizes.iconL;
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        border: border ??
            Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
      ),
      child: Center(
        child: SizedBox(
          width: containerSize * 0.6,
          height: containerSize * 0.6,
          child: icon,
        ),
      ),
    );
  }

  Widget _buildWithContent() {
    final iconWidget = icon != null
        ? SizedBox(
            width: AppSizes.iconS,
            height: AppSizes.iconS,
            child: icon,
          )
        : null;

    final textWidget = text != null && text!.isNotEmpty
        ? Text(
            text!,
            style: textStyle ??
                kTextRegularStyle.copyWith(
                  color: textColor ??
                      DynamicThemeService.shared.getPrimaryAccentColor(),
                  fontWeight: FontWeight.w700,
                ),
          )
        : null;

    return Container(
      height: badgeHeight,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        // Border pill
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPosition == IconPosition.left && iconWidget != null) ...[
            iconWidget,
            if (textWidget != null)
              SizedBox(width: spacing ?? AppSizes.spacingXS),
          ],
          if (textWidget != null) textWidget,
          if (iconPosition == IconPosition.right && iconWidget != null) ...[
            if (textWidget != null)
              SizedBox(width: spacing ?? AppSizes.spacingXS),
            iconWidget,
          ],
        ],
      ),
    );
  }
}

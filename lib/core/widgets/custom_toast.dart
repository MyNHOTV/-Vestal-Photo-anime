import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_sizes.dart';

class CustomToast extends StatelessWidget {
  final String message;
  final String? icon;
  final Color? iconBackgroundColor;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomToast({
    super.key,
    required this.message,
    this.icon,
    this.iconBackgroundColor,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingM,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingS,
          vertical: AppSizes.spacingS,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.color29171E,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green circle với checkmark icon
              SvgIcon(name: icon ?? "ic_tick_success"),
              const SizedBox(width: AppSizes.spacingM),
              // Text message
              Flexible(
                child: Text(
                  message,
                  style: kTextRegularStyle.copyWith(
                    color: textColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show toast với animation
  static void show(
    BuildContext context, {
    required String message,
    String? icon,
    Color? iconBackgroundColor,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom +
            AppSizes.bottomNavBarHeight +
            AppSizes.spacingM,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 100 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: CustomToast(
              message: message,
              icon: icon,
              iconBackgroundColor: iconBackgroundColor,
              backgroundColor: backgroundColor,
              textColor: textColor,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove sau duration
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  /// Show success toast
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      icon: 'ic_tick_success',
      iconBackgroundColor: const Color(0xFF4CAF50), // Green
      duration: duration,
    );
  }

  /// Show error toast
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      icon: 'ic_close',
      iconBackgroundColor: AppColors.error,
      duration: duration,
    );
  }

  /// Show info toast
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      icon: 'ic_close',
      iconBackgroundColor: AppColors.info,
      duration: duration,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:get/get.dart';

import '../constants/export_constants.dart';

enum StateButton { active, pressed, disable }

// ignore: must_be_immutable
class AppPrimaryButton extends StatelessWidget {
  AppPrimaryButton(
      {super.key,
      this.height,
      this.width,
      this.title,
      this.state = StateButton.active,
      required this.onTap,
      this.customContent,
      this.color,
      this.titleColor,
      this.border,
      this.borderRadius});

  final double? height;
  final double? width;
  final String? title;
  final StateButton state;
  final Function onTap;
  final Widget? customContent;
  final Color? color;
  final dynamic titleColor;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;
  int timeClick = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () async {
          // Check network trước khi navigate
          if (Get.isRegistered<NetworkService>()) {
            final hasNetwork =
                await NetworkService.to.checkNetworkForInAppFunction();
            if (!hasNetwork) {
              debugPrint('🌐 No network, blocking app button tap');
              return;
            }
            // Có mạng, tiếp tục navigate
            if (state != StateButton.disable) {
              FocusScope.of(Get.context ?? context).unfocus();
              if (timeClick == 0) {
                timeClick = 1;
                onTap();
                Future.delayed(const Duration(milliseconds: 500), () {
                  timeClick = 0;
                });
              }
            }
          } else {
            // Fallback nếu NetworkService chưa sẵn sàng
            if (state != StateButton.disable) {
              FocusScope.of(Get.context ?? context).unfocus();
              if (timeClick == 0) {
                timeClick = 1;
                onTap();
                Future.delayed(const Duration(milliseconds: 500), () {
                  timeClick = 0;
                });
              }
            }
          }
        },
        child: Container(
          height: height ?? AppSizes.buttonHeightM,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
              border: border,
              borderRadius: borderRadius ?? BorderRadius.circular(1000),
              gradient: (state == StateButton.active && color == null)
                  ? () {
                      final colors = getBackgroundColor(state,
                          DynamicThemeService.shared.getButtonGradientColors());
                      final colorList = colors is List<Color>
                          ? colors
                          : [colors as Color, colors as Color];
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colorList,
                        stops: List.generate(
                          colorList.length,
                          (i) => i / (colorList.length - 1),
                        ),
                      );
                    }()
                  : null,
              color: state == StateButton.active && color != null
                  ? color
                  : (state == StateButton.active
                      ? null
                      : (color ?? AppColors.buttonDefaultColor))),
          child: Center(
            child: customContent ??
                Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  style: kBricolageBoldStyle.copyWith(
                      color: titleColor ?? getTitleColor(state)),
                ),
          ),
        ),
      ),
    );
  }
}

dynamic getBackgroundColor(StateButton state, dynamic color) {
  switch (state) {
    case StateButton.active:
      if (color == null) {
        return AppColors.buttonDefaultColor;
      } else if (color is List<Color>) {
        return color;
      } else {
        return [color as Color, color];
      }

    case StateButton.pressed:
      return AppColors.buttonDefaultColor;
    default:
      return AppColors.buttonDefaultColor;
  }
}

Color getTitleColor(StateButton state) {
  switch (state) {
    case StateButton.disable:
      return AppColors.disableColorText;
    default:
      return AppColors.surface;
  }
}

class AppSecondaryButton extends StatelessWidget {
  AppSecondaryButton({
    super.key,
    this.height,
    this.width,
    this.title,
    this.state = StateButton.active,
    required this.onTap,
    this.customContent,
    this.borderRadius,
    this.idDialog,
  });

  final double? height;
  final double? width;
  final String? title;
  final StateButton state;
  final Function onTap;
  final Widget? customContent;
  final BorderRadiusGeometry? borderRadius;
  int timeClick = 0;
  bool? idDialog = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () async {
          if (idDialog == true) {
            if (state != StateButton.disable) {
              FocusScope.of(Get.context ?? context).unfocus();
              if (timeClick == 0) {
                timeClick = 1;
                onTap();
                Future.delayed(const Duration(milliseconds: 500), () {
                  timeClick = 0;
                });
              }
            }
            return;
          }
          if (Get.isRegistered<NetworkService>()) {
            final hasNetwork =
                await NetworkService.to.checkNetworkForInAppFunction();
            if (!hasNetwork) {
              debugPrint('🌐 No network, blocking app button tap');
              return;
            }
            if (state != StateButton.disable) {
              FocusScope.of(Get.context ?? context).unfocus();
              if (timeClick == 0) {
                timeClick = 1;
                onTap();
                Future.delayed(const Duration(milliseconds: 500), () {
                  timeClick = 0;
                });
              }
            }
          } else {
            if (state != StateButton.disable) {
              FocusScope.of(Get.context ?? context).unfocus();
              if (timeClick == 0) {
                timeClick = 1;
                onTap();
                Future.delayed(const Duration(milliseconds: 500), () {
                  timeClick = 0;
                });
              }
            }
          }
        },
        child: Container(
          height: height ?? AppSizes.buttonHeightM,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(1000),
            border: Border.all(
              color: Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.circular(1000),
                ),
                child: Container(
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: borderRadius ?? BorderRadius.circular(1000),
                  ),
                ),
              ),
              Center(
                child: customContent ??
                    ShaderMask(
                      shaderCallback: (bounds) {
                        if (state == StateButton.disable) {
                          return const LinearGradient(
                            colors: [
                              AppColors.disableColorText,
                              AppColors.disableColorText
                            ],
                          ).createShader(bounds);
                        }
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: DynamicThemeService.shared
                              .getSecondaryButtonGradientColors(),
                        ).createShader(bounds);
                      },
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        style: kTextButtonStyle.copyWith(
                          color:
                              Colors.white, // Màu này sẽ bị gradient override
                        ),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppGradientBorderButton extends StatelessWidget {
  AppGradientBorderButton({
    super.key,
    this.height,
    this.width,
    this.title,
    this.state = StateButton.active,
    required this.onTap,
    this.customContent,
    this.borderRadius,
    this.borderWidth = 1.5,
    this.padding,
    this.gradientColors,
    this.fillColor = Colors.white,
    this.disabledFillColor,
    this.titleStyle,
    this.titleColor,
    this.useGradientText = false,
    this.checkNetwork = true,
  });

  final double? height;
  final double? width;
  final String? title;
  final StateButton state;
  final VoidCallback onTap;
  final Widget? customContent;
  final BorderRadiusGeometry? borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final List<Color>? gradientColors;
  final Color fillColor;
  final Color? disabledFillColor;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final bool useGradientText;
  final bool checkNetwork;

  int timeClick = 0;

  Future<void> _handleTap(BuildContext context) async {
    if (state == StateButton.disable) return;

    if (checkNetwork && Get.isRegistered<NetworkService>()) {
      final hasNetwork = await NetworkService.to.checkNetworkForInAppFunction();
      if (!hasNetwork) {
        debugPrint('🌐 No network, blocking app button tap');
        return;
      }
    }

    FocusScope.of(Get.context ?? context).unfocus();
    if (timeClick == 0) {
      timeClick = 1;
      onTap();
      Future.delayed(const Duration(milliseconds: 500), () {
        timeClick = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = state == StateButton.disable
        ? const [AppColors.disableColorText, AppColors.disableColorText]
        : (gradientColors ??
            DynamicThemeService.shared.getButtonGradientColors());

    final innerColor = state == StateButton.disable
        ? (disabledFillColor ?? fillColor.withOpacity(0.6))
        : fillColor;

    final resolvedTitleColor = titleColor ??
        (state == StateButton.disable
            ? AppColors.disableColorText
            : DynamicThemeService.shared.getPrimaryAccentColor());

    Widget label = Text(
      title ?? '',
      textAlign: TextAlign.center,
      style: (titleStyle ?? kTextButtonStyle).copyWith(
        color: useGradientText ? Colors.white : resolvedTitleColor,
      ),
    );

    if (useGradientText) {
      label = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: effectiveGradient,
        ).createShader(bounds),
        child: label,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () => _handleTap(context),
        child: Container(
          height: height ?? AppSizes.buttonHeightM,
          width: width ?? double.infinity,
          padding: EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: effectiveGradient,
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(1000),
          ),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                  vertical: AppSizes.spacingS,
                ),
            decoration: BoxDecoration(
              color: innerColor,
              borderRadius: borderRadius ?? BorderRadius.circular(1000),
            ),
            child: Center(
              child: customContent ?? label,
            ),
          ),
        ),
      ),
    );
  }
}

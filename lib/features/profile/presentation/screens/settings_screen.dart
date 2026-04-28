import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/services/android_splash_service.dart';
import '../../../../core/services/dynamic_theme_service.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/widgets/grid_background.dart';
import '../widgets/section_header_widget.dart';
import '../widgets/settings_item_widget.dart';
import '../../../../core/widgets/simple_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _changeTheme(DynamicTheme theme, BuildContext context) {
    final themeService = DynamicThemeService.shared;
    final currentTheme = themeService.currentTheme.value;

    // Nếu theme giống nhau thì không làm gì
    if (currentTheme == theme) return;

    // Set theme mới
    // Theme sẽ được lưu và áp dụng khi app khởi động lại (kill và mở lại)
    themeService.setTheme(theme);
  }

  void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.color231B1D,
          title: Text(
            tr('restart_app'),
            style: kTextRegularStyle.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            tr('restart_app_desc'),
            style: kTextRegularStyle.copyWith(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                tr('cancel'),
                style: kTextRegularStyle.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Đóng dialog
                Navigator.of(context).pop();

                // Gọi restartApp từ Android native
                AndroidSplashService.shared.restartApp();
              },
              child: Text(
                tr('restart'),
                style: kTextRegularStyle.copyWith(
                  color: Colors.orange,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: SimpleAppBar(
        title: tr('settings'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(
              child: SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First General Section
                  SectionHeaderWidget(title: tr('general')),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingM,
                    ),
                    child: Column(
                      children: [
                        SettingsItemWidget(
                          title: tr('notification'),
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to notification settings
                          },
                        ),
                        SettingsItemWidget(
                          title: tr('languages'),
                          icon: const Icon(
                            Icons.language,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to language settings
                          },
                        ),
                        SettingsItemWidget(
                          title: tr('download'),
                          icon: const Icon(
                            Icons.download_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to download settings
                          },
                        ),
                        // Theme Selector
                        Obx(() {
                          final themeService = DynamicThemeService.shared;
                          final remoteConfigTheme = RemoteConfigService
                              .shared.appThemeFromRemoteConfig;
                          final isRemoteConfigControlled =
                              remoteConfigTheme != null;

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: AppSizes.spacingS),
                            padding: const EdgeInsets.all(AppSizes.spacingM),
                            decoration: BoxDecoration(
                              color: AppColors.color231B1D,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusL),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.palette_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSizes.spacingM),
                                    Expanded(
                                      child: Text(
                                        'Theme',
                                        style: kTextRegularStyle.copyWith(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Nút Reset App
                                    GestureDetector(
                                      onTap: () {
                                        _showRestartDialog(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.orange,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.refresh,
                                              color: Colors.orange,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Reset',
                                              style: kTextRegularStyle.copyWith(
                                                color: Colors.orange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isRemoteConfigControlled)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Remote',
                                          style: kTextRegularStyle.copyWith(
                                            color: AppColors.primaryLight,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ThemeButton(
                                        title: 'Pink',
                                        theme: DynamicTheme.COLOR_PINK,
                                        isSelected:
                                            themeService.currentTheme.value ==
                                                DynamicTheme.COLOR_PINK,
                                        isDisabled: isRemoteConfigControlled,
                                        onTap: () {
                                          if (!isRemoteConfigControlled) {
                                            _changeTheme(
                                                DynamicTheme.COLOR_PINK,
                                                context);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.spacingS),
                                    Expanded(
                                      child: _ThemeButton(
                                        title: 'Blue',
                                        theme: DynamicTheme.COLOR_BLUE,
                                        isSelected:
                                            themeService.currentTheme.value ==
                                                DynamicTheme.COLOR_BLUE,
                                        isDisabled: isRemoteConfigControlled,
                                        onTap: () {
                                          if (!isRemoteConfigControlled) {
                                            _changeTheme(
                                                DynamicTheme.COLOR_BLUE,
                                                context);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Second General Section
                  SectionHeaderWidget(title: tr('general')),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingM,
                    ),
                    child: Column(
                      children: [
                        SettingsItemWidget(
                          title: tr('contact_us'),
                          icon: const Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to contact us
                          },
                        ),
                        SettingsItemWidget(
                          title: tr('term_of_service'),
                          icon: const Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to terms of service
                          },
                        ),
                        SettingsItemWidget(
                          title: tr('subscriptions_term'),
                          icon: const Icon(
                            Icons.verified_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to subscriptions term
                          },
                        ),
                        SettingsItemWidget(
                          title: tr('privacy_policy'),
                          icon: const Icon(
                            Icons.privacy_tip_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onTap: () {
                            // TODO: Navigate to privacy policy
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.title,
    required this.theme,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String title;
  final DynamicTheme theme;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.shared;
    Color buttonColor;
    List<Color> gradientColors;

    if (theme == DynamicTheme.COLOR_PINK) {
      gradientColors = [
        AppColors.colorA30049,
        AppColors.colorFF18BA,
        AppColors.colorE037B3,
        AppColors.colorAD01C3,
        AppColors.color600088,
      ];
      buttonColor = AppColors.colorFF00AE;
    } else {
      gradientColors = [
        AppColors.primaryDark,
        AppColors.primary,
        AppColors.primaryLight,
        AppColors.primary,
        AppColors.primaryDark,
      ];
      buttonColor = AppColors.primaryLight;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spacingS,
          horizontal: AppSizes.spacingM,
        ),
        decoration: BoxDecoration(
          gradient: isSelected && !isDisabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          color: isDisabled
              ? AppColors.disableColorText.withOpacity(0.2)
              : isSelected
                  ? null
                  : AppColors.color231B1D,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isSelected && !isDisabled
                ? Colors.transparent
                : buttonColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: kTextRegularStyle.copyWith(
              color: isDisabled
                  ? AppColors.disableColorText
                  : isSelected
                      ? Colors.white
                      : buttonColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

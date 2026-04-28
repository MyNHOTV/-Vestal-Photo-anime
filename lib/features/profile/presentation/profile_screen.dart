import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/image_picker_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_icon.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsService.shared.logEvent(
      name: 'tab_profile_show',
    );
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/icons/img_bg_setting.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Setting title button
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.spacingM,
                    bottom: AppSizes.spacingL,
                  ),
                  child: _buildSettingButton(),
                ),
                // Settings list
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: ListView(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height / 11),
                      children: [
                        _buildSettingsItem(
                          icon: 'ic_language_setting',
                          title: tr('languages'),
                          onTap: () async {
                            final hasNet = await NetworkService.to
                                .checkNetworkForInAppFunction();
                            if (!hasNet) return;
                            Get.toNamed(AppRoutes.languageSelection);
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: 'ic_shared_setting',
                          title: tr('share'),
                          onTap: () async {
                            final hasNet = await NetworkService.to
                                .checkNetworkForInAppFunction();
                            if (!hasNet) return;
                            // Set flag khi bắt đầu share
                            ImagePickerService.shared.setSharing(true);
                            final currentLocale = context.locale.languageCode;
                            final playStoreLink =
                                'https://play.google.com/store/apps/details?id=com.ai.anime.art.generator.photo.create.aiart&hl=$currentLocale';
                            // Share text kèm link
                            final shareText =
                                '${tr('check_out_this_amazing')}\n\n$playStoreLink';
                            try {
                              await Share.share(shareText);
                            } finally {
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                ImagePickerService.shared.setSharing(false);
                              });
                            }
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: 'ic_rate_setting',
                          title: tr('privacy_policy'),
                          onTap: () async {
                            final hasNet = await NetworkService.to
                                .checkNetworkForInAppFunction();
                            if (!hasNet) return;
                            Get.toNamed(
                              AppRoutes.webview,
                              arguments: {
                                'url':
                                    'https://zentrixa.io/privacy-policy-for-pdf-reader/',
                                'title': tr('privacy_policy'),
                              },
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: 'ic_policy_setting',
                          title: tr('term_of_service'),
                          onTap: () async {
                            final hasNet = await NetworkService.to
                                .checkNetworkForInAppFunction();
                            if (!hasNet) return;
                            Get.toNamed(
                              AppRoutes.webview,
                              arguments: {
                                'url': 'https://zentrixa.io/terms-of-service/',
                                'title': tr('term_of_service'),
                              },
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: 'ic_policy_setting',
                          title: tr('subscriptions_term'),
                          onTap: () async {
                            final hasNet = await NetworkService.to
                                .checkNetworkForInAppFunction();
                            if (!hasNet) return;
                            Get.toNamed(
                              AppRoutes.webview,
                              arguments: {
                                'url':
                                    'https://zentrixa.io/subscription-terms/',
                                'title': tr('subscriptions_term'),
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingButton() {
    return IntrinsicWidth(
      child: AppGradientBorderButton(
        customContent: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.colorAE8CF5,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            Text(
              tr('settings'),
              style: kTextRegularStyle.copyWith(
                color: AppColors.color400FA7,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: AppSizes.spacingS),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.colorAE8CF5,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        onTap: () {},
        useGradientText: false,
        titleColor: AppColors.color400FA7,
      ),
    );
  }

  Widget _buildSettingsItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingM,
        ),
        child: Row(
          children: [
            // Icon in purple circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.colorEAE7FE,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgIcon(
                  name: icon,
                  width: 18,
                  height: 18,
                  color: AppColors.color400FA7,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            // Title
            Expanded(
              child: Text(
                title,
                style: kTextRegularStyle.copyWith(
                  color: AppColors.color121212,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppColors.color727885,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
      indent: AppSizes.spacingM + 40 + AppSizes.spacingM,
    );
  }
}

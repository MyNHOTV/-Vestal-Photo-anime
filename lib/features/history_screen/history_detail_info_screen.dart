import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:get/get.dart';

import '../../../core/constants/export_constants.dart';
import '../../../core/services/ads_service.dart';
import '../../../core/widgets/grid_background.dart';
import '../../../core/widgets/simple_app_bar.dart';
import '../image_generation/data/datasources/aspect_ratio_data_source.dart';
import '../image_generation/domain/entities/generated_image.dart';

class HistoryDetailInfoScreen extends StatefulWidget {
  const HistoryDetailInfoScreen({super.key});

  @override
  State<HistoryDetailInfoScreen> createState() =>
      _HistoryDetailInfoScreenState();
}

class _HistoryDetailInfoScreenState extends State<HistoryDetailInfoScreen> {
  static int backCount = 0;
  bool _canPop = false;

  void _handleBack() async {
    final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
    if (!hasNet) return;

    backCount++;
    if (backCount % 2 != 0) {
      AdService().loadInterstitial(
        type: 'inter_detail',
        onComplete: () {
          AdService().showInterstitial(
            'inter_detail',
            onComplete: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              if (mounted) {
                setState(() {
                  _canPop = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                });
              }
            },
          );
        },
      );
    } else {
      if (mounted) {
        setState(() {
          _canPop = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = Get.arguments as GeneratedImage?;
    final aspectRatio = image?.aspectRatio ?? '1:1';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.shared.screenImageInfoShow();
    });
    if (image == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('image_detail'))),
        body: Center(child: Text(tr('no_image_data'))),
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const Positioned.fill(
                child: GridBackground(
                  child: SizedBox.shrink(),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    SimpleAppBar(
                      title: tr('image_detail'),
                      onLeadingTap: _handleBack,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: AppSizes.spacingM,
                            right: AppSizes.spacingM,
                            bottom: AppSizes.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Your Prompt Section
                            Text(
                              tr('your_prompt'),
                              style: kTextHeadingStyle.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacingS),
                            Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height / 8,
                              padding: const EdgeInsets.only(
                                  left: 16.0,
                                  top: 16.0,
                                  bottom: 16.0,
                                  right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.color29171E,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusL),
                                border: Border.all(
                                  color: AppColors.color595959,
                                  width: 1,
                                ),
                              ),
                              child: Scrollbar(
                                radius: const Radius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      image.userPrompt,
                                      style: kTextRegularStyle.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSizes.spacingS),
                            // Image Style & Aspect Ratio Section
                            Text(
                              tr('style'),
                              style: kTextHeadingStyle.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacingS),
                            // Row chứa 2 ô: Style và Aspect Ratio
                            Row(
                              children: [
                                // Style card
                                Flexible(child: _buildStyleCard(image.styleId)),
                                // const SizedBox(width: AppSizes.spacingM),
                                // // Aspect Ratio card
                                // Flexible(
                                //     child: _buildAspectRatioCard(aspectRatio)),
                              ],
                            ),
                            const Spacer(),
                            //back button to close,
                            AppPrimaryButton(
                              onTap: () {
                                _handleBack();
                              },
                              title: tr('back_to_image'),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Obx(() {
            if (!RemoteConfigService.shared.adsEnabled &&
                !RemoteConfigService.shared.nativeInfoEnabled) {
              return const SizedBox.shrink();
            }
            return const NativeAdWidget(
              uniqueKey: 'native_info',
              factoryId: 'native_small_image_top',
              backgroundColor: Colors.white,
              height: 210,
              hasBorder: true,
              margin: EdgeInsets.only(
                  left: AppSizes.spacingM,
                  right: AppSizes.spacingM,
                  bottom: AppSizes.spacingM),
              padding: EdgeInsets.zero,
            );
          })),
    );
  }

  Widget _buildStyleCard(int? styleId) {
    if (styleId == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.color231B1D,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: AppColors.color595959,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            tr('no_style'),
            style: kTextSmallStyle.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    final styles = HomeDataSource.getImageStyles();
    final style = styles.firstWhere(
      (s) => s.id == styleId,
      orElse: () => styles.first,
    );

    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(
                  color: AppColors.color29171E,
                  width: 6,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                child: style.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: style.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildStylePlaceholder(),
                        errorWidget: (context, url, error) =>
                            // Nếu load imageUrl lỗi, fallback về imageAsset
                            style.imageAsset != null
                                ? Image.asset(
                                    style.imageAsset!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildStylePlaceholder(),
                                  )
                                : _buildStylePlaceholder(),
                        maxWidthDiskCache: 2048,
                        maxHeightDiskCache: 2048,
                      )
                    : style.imageAsset != null
                        ? Image.asset(
                            style.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildStylePlaceholder(),
                          )
                        : _buildStylePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            style.name,
            style: kTextSmallStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStylePlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildAspectRatioCard(String aspectRatio) {
    final aspectRatios = AspectRatioDataSource.getAspectRatios();
    final selectedRatio = aspectRatios.firstWhere(
      (ratio) => ratio.aspectRatio == aspectRatio,
      orElse: () => aspectRatios.first,
    );

    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.color29171E,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: Center(
                child: Container(
                  width: selectedRatio.iconWidth + 16,
                  height: selectedRatio.iconHeight + 16,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            tr(selectedRatio.i18nKey),
            style: kTextSmallStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/cached_image_widget.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:flutter_quick_base/features/image_generation/domain/entities/generated_image.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import '../../../../features/home/presentation/widget/home_library_widget.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImageGenerationController>();

    // Load history khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadHistory(refresh: true);
      AnalyticsService.shared.screenHistoryShow();
    });

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.colorBlack,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/icons/image_my_creation_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: AppSizes.spacingM,
                ),
                // My Creations title button
                IntrinsicWidth(
                  child: AppGradientBorderButton(
                    // width: MediaQuery.of(context).size.width / 2,
                    // padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width/3),
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
                          tr('my_creations'),
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
                ),
                const SizedBox(
                  height: AppSizes.buttonHeightM,
                ),
                // Grid content
                Expanded(
                  child: Obx(() {
                    final history = controller.history;
                    if (history.isEmpty) {
                      return _buildEmptyState();
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: (!RemoteConfigService.shared.adsEnabled ||
                                    !RemoteConfigService.shared
                                        .isNativeEnabled('native_history'))
                                ? 0
                                : AppSizes.spacingM,
                            // right: AppSizes.spacingM,
                            bottom: AppSizes.bottomNavBarHeight,
                          ),
                          child: _buildGrid(history, constraints.maxWidth),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<GeneratedImage> history, double maxWidth) {
    // Calculate how many rows we need (2 items per row)
    final rows = (history.length / 2).ceil();

    return Column(
      children: [
        for (int row = 0; row < rows; row++)
          ..._buildRowWithAd(history, row, maxWidth),
      ],
    );
  }

  List<Widget> _buildRowWithAd(
    List<GeneratedImage> history,
    int rowIndex,
    double maxWidth,
  ) {
    final widgets = <Widget>[];

    // Build the row with 2 images
    final startIndex = rowIndex * 2;
    final endIndex = (startIndex + 2).clamp(0, history.length);
    final rowImages = history.sublist(startIndex, endIndex);

    // Calculate item width (accounting for spacing between items)
    // maxWidth already accounts for padding from SingleChildScrollView
    final itemWidth = (maxWidth - AppSizes.spacingL) / 2.1;
    final itemHeight = itemWidth / 0.75; // Based on aspect ratio 0.75

    // Add the row of images
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
        child: SizedBox(
          width: maxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: _buildImageCard(rowImages[0]),
              ),
              if (rowImages.length > 1) ...[
                const SizedBox(width: AppSizes.radiusL),
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: _buildImageCard(rowImages[1]),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Insert ad after every row (after every 2 items)
    // Luôn chèn ads sau row đầu tiên (rowIndex == 0), sau đó cứ 2 row lại chèn 1 ads
    // Hoặc chèn ads sau mỗi row nếu còn item phía sau
    if (rowIndex == 0 || endIndex < history.length) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
              bottom: AppSizes.spacingS, top: AppSizes.spacingS),
          child: _buildAdItem(),
        ),
      );
    }

    return widgets;
  }

  Widget _buildAdItem() {
    return Obx(() {
      if (!RemoteConfigService.shared.adsEnabled ||
          !RemoteConfigService.shared.isNativeEnabled('native_history')) {
        return const SizedBox.shrink();
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: NativeAdWidget(
          uniqueKey: 'native_history',
          factoryId: 'native_small_image_top',
          margin: const EdgeInsets.only(
              right: AppSizes.spacingM, bottom: AppSizes.spacingM),
          padding: EdgeInsets.zero,
          hasBorder: true,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.colorAE8CF5, width: 0.5),
          backgroundColor: Colors.white,
          height: 210,
          buttonColor: DynamicThemeService.shared.getActiveColorADS(),
          adBackgroundColor: DynamicThemeService.shared.getActiveColorADS(),
        ),
      );
    });
  }

  Widget _buildImageCard(GeneratedImage image) {
    final controller = Get.find<ImageGenerationController>();
    return GestureDetector(
      onTap: () async {
        final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
        if (!hasNet) return;
        final result =
            await Get.toNamed(AppRoutes.historyDetail, arguments: image);

        if (result == true) {
          controller.loadHistory(refresh: true);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: CachedImageWidget(
                imagePath: image.imagePath,
                fit: BoxFit.cover,
                placeholder: _buildPlaceholder(),
                errorWidget: _buildPlaceholder(),
              ),
            ),
            // Info icon in top right
            // Positioned(
            //   top: 8,
            //   right: 8,
            //   child: GestureDetector(
            //     onTap: () async {
            //       final hasNet =
            //           await NetworkService.to.checkNetworkForInAppFunction();
            //       if (!hasNet) return;
            //       final result = await Get.toNamed(
            //         AppRoutes.historyDetail,
            //         arguments: image,
            //       );
            //
            //       if (result == true) {
            //         controller.loadHistory(refresh: true);
            //       }
            //     },
            //     child: const SvgIcon(
            //       name: 'ic_info',
            //       width: 20,
            //       height: 20,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SvgIcon(name: "ic_empty_library"),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              tr('no_created_images_yet'),
              style: kBricolageRegularStyle.copyWith(
                  color: AppColors.color727885, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/extensions/context_extensions.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/utils/export_extensions.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/appbar/custom_transparent_appbar.dart';
import 'package:flutter_quick_base/core/widgets/cached_image_widget.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/core/widgets/confirm_watch_ad_dialog.dart';
import 'package:flutter_quick_base/core/widgets/grid_background.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/simple_app_bar.dart';
import 'package:flutter_quick_base/features/image_detail/controller/image_detail_screen_controller.dart';
import 'package:flutter_quick_base/features/image_generation/domain/entities/generated_image.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final image = Get.arguments as GeneratedImage?;
    final controller = Get.put(ImageDetailScreenController());
    final genController = Get.find<ImageGenerationController>();

    if (image == null) {
      return Scaffold(
        appBar: SimpleAppBar(title: tr('detail')),
        body: Center(child: Text(tr('no_image_data'))),
      );
    }

    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: SizedBox.expand(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/icons/image_detai.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // SimpleAppBar(
                  //   title: tr('detail'),
                  // ),
                  CustomTransparentAppBar(
                    title: tr('image_detail'),
                    nextIcon: 'ic_delete',
                    nextIconSize: 20,
                    nextIconColor: AppColors.color434A50,
                    onNextTap: () {
                      ConfirmWatchAdDialog.show(
                        context: context,
                        adCount: 1,
                        typeImage: TypeImage.deleteImage,
                        title: tr('delete_image'),
                        content: tr('image_will_be_deleted_confirmation'),
                        confirmText: tr('delete'),
                        cancelText: tr('cancel'),
                        onConfirm: () async {
                          genController.deleteImage(image.id);
                          await genController.loadHistory(refresh: true);
                          Get.back(result: true);
                          controller.showToastMessage(tr('delete_image'),
                              type: 'success');
                        },
                      );
                    },
                  ),
                  // Image display
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizes.spacingM,
                      right: AppSizes.spacingM,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      child: _buildImage(image),
                    ),
                  ),
                  const Expanded(child: SizedBox(height: AppSizes.spacingM)),
                  Obx(() {
                    if (!RemoteConfigService.shared.adsEnabled &&
                        !RemoteConfigService.shared.nativeInfoEnabled) {
                      return const SizedBox.shrink();
                    }
                    return NativeAdWidget(
                      uniqueKey: 'native_info',
                      factoryId: 'native_small_image_top',
                      backgroundColor: Colors.white,
                      margin: const EdgeInsets.only(
                          left: AppSizes.spacingM,
                          right: AppSizes.spacingM,
                          bottom: AppSizes.spacingM),
                      padding: EdgeInsets.zero,
                      height: 210,
                      hasBorder: true,
                      borderRadius: BorderRadius.circular(5),
                      border:
                          Border.all(color: AppColors.colorAE8CF5, width: 0.5),
                      buttonColor:
                          DynamicThemeService.shared.getPrimaryAccentColor(),
                      adBackgroundColor:
                          DynamicThemeService.shared.getPrimaryAccentColor(),
                    );
                  }),
                  // Toast message (above share/delete buttons)
                  Obx(() => controller.showToast.value
                      ? Padding(
                          padding: const EdgeInsets.only(
                            left: AppSizes.spacingM,
                            right: AppSizes.spacingM,
                            bottom: AppSizes.spacingS,
                          ),
                          child: _buildToastWidget(
                            controller.toastMessage.value,
                            controller.toastType.value,
                          ),
                        )
                      : const SizedBox.shrink()),
                  // Action buttons: Share and Delete
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: AppPrimaryButton(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              controller.shareImageWithOption(context);
            },
            customContent: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  name: 'ic_share',
                  color: AppColors.surface,
                ),
                const SizedBox(width: AppSizes.spacingS),
                Text(
                  tr('share'),
                  style: kBricolageBoldStyle.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildImage(GeneratedImage image) {
    final aspectRatioValue = _getAspectRatioValue(image.aspectRatio ?? '1:1');
    final size = _getImageSizeByAspectRatio(aspectRatioValue);

    return Stack(
      children: [
        SizedBox(
          height: size['height'],
          width: size['width'],
          child: AspectRatio(
            aspectRatio: aspectRatioValue,
            child: CachedImageWidget(
              imagePath: image.imagePath,
              fit: BoxFit.cover,
              placeholder: _buildPlaceholder(),
              errorWidget: _buildPlaceholder(),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double> _getImageSizeByAspectRatio(double aspectRatioValue) {
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    const padding = AppSizes.spacingM * 2;

    double width;
    double height;

    if (aspectRatioValue == 9 / 16) {
      width = screenWidth - padding * 5;
      height = screenHeight / 2;
    } else if (aspectRatioValue == 3 / 4) {
      width = screenWidth - padding * 3;
      height = screenHeight / 2.5;
    } else if (aspectRatioValue == 1.0) {
      width = screenWidth - padding;
      height = screenHeight / 2.5;
    } else if (aspectRatioValue == 4 / 3) {
      width = screenWidth - padding;
      height = screenHeight / 3.0;
    } else if (aspectRatioValue == 16 / 9) {
      width = screenWidth - padding;
      height = screenHeight / 4;
    } else {
      width = screenWidth - padding;
      height = screenHeight / 2.5;
    }

    return {'width': width, 'height': height};
  }

  double _getAspectRatioValue(String aspectRatio) {
    final parts = aspectRatio.split(':');
    if (parts.length == 2) {
      final width = double.tryParse(parts[0]);
      final height = double.tryParse(parts[1]);
      if (width != null && height != null && height != 0) {
        return width / height;
      }
    }
    return 1.0;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.textSecondary,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildToastWidget(String message, String toastType) {
    final isError = toastType == 'error';
    final isDelete = toastType == 'delete';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.color29171E,
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
                      if (!isDelete)
                        Center(
                          child: SvgIcon(
                            name: isError ? 'ic_close' : 'ic_tick_success',
                            width: isError ? 20 : 24,
                            height: isError ? 20 : 24,
                            color: isError ? Colors.white : null,
                          ),
                        )
                      else
                        const Center(
                          child: SvgIcon(
                            name: 'ic_delete',
                            width: 18,
                            height: 18,
                            color: AppColors.colorFF4538,
                          ),
                        ),
                      const SizedBox(width: AppSizes.spacingM),
                      // Text message
                      Flexible(
                        child: Text(
                          message,
                          style: kTextRegularStyle.copyWith(
                            color: Colors.white,
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
            ),
          ),
        );
      },
    );
  }
}

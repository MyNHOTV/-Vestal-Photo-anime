import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import '../../../../core/constants/export_constants.dart';
import '../../../../core/widgets/export_widgets.dart';

class GenerationImageStepWidget extends StatelessWidget {
  const GenerationImageStepWidget({super.key, required this.controller});

  final ImageGenerationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasImage = controller.selectedImagePath.value.isNotEmpty;
      final isUploading = controller.isFakeUploading.value;

      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!hasImage && !isUploading)
              _buildUploadPlaceholder(context)
            else if (isUploading)
              _buildUploadingState(context)
            else
              _buildUploadedImage(context),
            SizedBox(height: MediaQuery.of(context).size.height / 4)
          ],
        ),
      );
    });
  }

  Widget _buildUploadingState(BuildContext context) {
    return Obx(() {
      final progress = controller.fakeUploadProgress.value;
      return DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(16),
          dashPattern: [8, 4],
          strokeWidth: 2,
          color: AppColors.surface,
          padding: EdgeInsets.all(16),
        ),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height / 1.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgIcon(
                  name: "ic_generate_image_pick",
                  color: DynamicThemeService.shared.getPrimaryAccentColor(),
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  tr('upload_image_for_accurate_results_or_skip'),
                  style: kTextRegularStyle.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingS),
                AppProgressBar(
                  progress: progress,
                  height: 8.0,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUploadPlaceholder(BuildContext context) {
    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        radius: Radius.circular(16),
        dashPattern: [8, 4],
        strokeWidth: 2,
        color: AppColors.surface,
        padding: EdgeInsets.all(16),
      ),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height / 1.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(
                name: "ic_generate_image_pick",
                color: DynamicThemeService.shared.getPrimaryAccentColor(),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                tr('upload_image_for_accurate_results_or_skip'),
                style: kTextRegularStyle.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingS),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 8),
                child: AppPrimaryButton(
                  title: tr('open_gallery'),
                  onTap: () => controller.selectImage(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedImage(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 1.7,
      child: Stack(
        children: [
          LoadingSpinKitFading(
            imageUrl: controller.selectedImagePath.value,
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 1.7,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ArtItemWidget(
              badgeHeight: 44,
              onTap: () async {
                final hasNet =
                    await NetworkService.to.checkNetworkForInAppFunction();
                if (!hasNet) return;
                controller.clearSelectedImage();
              },
              icon: const SvgIcon(name: "ic_delete"),
            ),
          ),
        ],
      ),
    );
  }
}

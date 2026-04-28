import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/features/image_detail/controller/image_detail_screen_controller.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import '../../../core/constants/export_constants.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:lottie/lottie.dart';

class ImageDetailScreen extends GetView<ImageDetailScreenController> {
  const ImageDetailScreen({
    super.key,
  });

  @override
  ImageDetailScreenController get controller =>
      Get.put(ImageDetailScreenController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.shared.screenResultShow();
    });
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
          if (!hasNet) return;

          await controller.handleBackIfNotSaved(context);
        },
        child: Scaffold(
          extendBody: true,
          // extendBodyBehindAppBar: true,
          backgroundColor: AppColors.colorBlack,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/icons/image_generating_screen.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: Lottie.asset(
                                'assets/icons/json_success_lottie.json',
                                fit: BoxFit.contain,
                                repeat: true,
                                animate: true,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              tr('your_creation_is_ready'),
                              style: kBricolageBoldStyle.copyWith(
                                  color: AppColors.color121212, fontSize: 18),
                            )
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        // Image display
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: AppSizes.spacingM,
                                      right: AppSizes.spacingM),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusL),
                                    child: _buildImage(controller),
                                  ),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.spacingM),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildActionButton(
                                        iconName: 'ic_dowload',
                                        label: tr('save'),
                                        onTap: () {
                                          controller
                                              .downloadImageWithOption(context);
                                        },
                                      ),
                                      _buildActionButton(
                                        iconName: 'ic_share',
                                        label: tr('share'),
                                        onTap: () {
                                          controller
                                              .shareImageWithOption(context);
                                        },
                                      ),
                                      _buildActionButton(
                                        iconName: 'ic_home_active',
                                        label: tr('home'),
                                        onTap: () {
                                          controller
                                              .handleBackIfNotSaved(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Toast message moved to Stack
                        Obx(() => controller.showToast.value
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    top: AppSizes.spacingS,
                                    bottom: AppSizes.spacingS),
                                child: _buildToastWidget(
                                  controller.toastMessage.value,
                                  controller.toastType.value,
                                ),
                              )
                            : const SizedBox(height: AppSizes.spacingM)),

                        const SizedBox(height: AppSizes.spacingS),
                        // Action buttons
                        _buildNewImageButton(context),
                        const SizedBox(height: AppSizes.spacingM),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Map<String, double> _getImageSizeByAspectRatio(double aspectRatioValue) {
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    const padding = AppSizes.spacingM * 2;

    double width;
    double height;

    // Check aspectRatioValue và rẽ nhánh
    if (aspectRatioValue == 9 / 16) {
      // 9:16 - Portrait dài
      width = screenWidth - padding * 5;
      height = screenHeight / 2; // Cao hơn
    } else if (aspectRatioValue == 3 / 4) {
      // 3:4 - Portrait
      width = screenWidth - padding * 3;
      height = screenHeight / 2.5;
    } else if (aspectRatioValue == 1.0) {
      // 1:1 - Square
      width = screenWidth - padding;
      height = screenHeight / 2.5; // Giữ nguyên như code hiện tại
    } else if (aspectRatioValue == 4 / 3) {
      // 4:3 - Landscape
      width = screenWidth - padding;
      height = screenHeight / 3.0; // Thấp hơn
    } else if (aspectRatioValue == 16 / 9) {
      // 16:9 - Landscape rộng
      width = screenWidth - padding;
      height = screenHeight / 4; // Rất thấp
    } else {
      // 1:1 - Square
      width = screenWidth - padding;
      height = screenHeight / 2.5; // Giữ nguyên như code hiện tại
    }

    return {
      'width': width,
      'height': height,
    };
  }

  Widget _buildImage(ImageDetailScreenController controller) {
    // final size = _getImageSizeByAspectRatio(controller.aspectRatioValue);
    final size = _getImageSizeByAspectRatio(3 / 4);
    return Stack(
      children: [
        // Image với aspect ratio
        SizedBox(
          height: size['height'],
          width: size['width'],
          child: AspectRatio(
            aspectRatio: controller.aspectRatioValue,
            child: CachedImageWidget(
              imagePath: controller.image.imagePath,
              fit: BoxFit.cover,
              placeholder: _buildPlaceholder(),
              errorWidget: _buildPlaceholder(),
            ),
          ),
        ),
        // Positioned(
        //   top: 12,
        //   right: 12,
        //   child: ArtItemWidget(
        //     badgeHeight: 44,
        //     onTap: () async {
        //       final hasNet =
        //           await NetworkService.to.checkNetworkForInAppFunction();
        //       if (!hasNet) return;
        //       Get.toNamed(
        //         AppRoutes.imageDetailInfo,
        //         arguments: controller.image,
        //       );
        //     },
        //     border: Border.all(
        //       color: AppColors.color29171E,
        //       width: 1,
        //     ),
        //     backgroundColor: AppColors.color29171E,
        //     icon: const SvgIcon(
        //       name: "ic_notice",
        //     ),
        //   ),
        // ),
        const Positioned(
            bottom: 12,
            right: 12,
            width: 80,
            height: 80,
            child: SvgIcon(
              name: 'ic_generate_ai',
              color: Colors.white54,
            )),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.textSecondary,
      child: const Center(
        child: SpinKitFadingCircle(
          color: AppColors.disableColorText,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String iconName,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgIcon(
            name: iconName,
            color: AppColors.color727885,
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            label,
            style: kTextRegularStyle.copyWith(
              color: AppColors.color727885,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      child: AppPrimaryButton(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final canProceed = await controller.canProceedToNewImage(context);
          if (canProceed == false) {
            return;
          }
          final genController = Get.find<ImageGenerationController>();
          genController.resetToInitialState();
          final previous = genController.previousRoute.value;
          if (previous == 'listStyle') {
            final styles = genController.previousListStyleStyles.toList();
            final groupName = genController.previousListStyleGroupName.value;
            Get.offNamedUntil(
              AppRoutes.listStyle,
              (route) => route.settings.name == AppRoutes.mainTabar,
              arguments: {
                'isView': true,
                'styles': styles,
                'groupName':
                    groupName.isNotEmpty ? groupName : tr('image_style'),
              },
            );
          } else {
            // Mặc định về home
            Get.offAllNamed(AppRoutes.mainTabar);
          }
        },
        title: tr('new_image'),
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
                            width: isError ? 14 : 20,
                            height: isError ? 14 : 20,
                            color: isError ? AppColors.error : null,
                          ),
                        )
                      else
                        Center(
                          child: SvgIcon(
                            name: 'ic_delete',
                            width: 18,
                            height: 18,
                            color: AppColors.colorFF4538,
                          ),
                        ),
                      const SizedBox(width: AppSizes.spacingS),
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

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/export_widgets.dart';
import 'package:flutter_quick_base/core/widgets/grid_background.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/widget_new/generation_final_step_widget.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/widget_new/generation_image_step_widget.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/widget_new/generation_style_grid_widget.dart';
import 'package:get/get.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

import '../../../../core/constants/export_constants.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final ImageGenerationController controller =
      Get.find<ImageGenerationController>();
  final ScrollController _styleScrollController = ScrollController();
  bool _shouldScroll = false;
  bool _hasScrolled = false;
  GenerationStep? _lastStep;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final preSelectedStyle = args['style'];
      if (preSelectedStyle != null) {
        _shouldScroll = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateStyleFromArguments();
      // Nếu đi từ generate và chưa có style được chọn, chọn style đầu tiên
      final args = Get.arguments;
      final fromGenerate = args != null &&
          args is Map<String, dynamic> &&
          (args['fromGenerate'] as bool? ?? false);

      if (fromGenerate &&
          controller.selectedStyle.value == null &&
          controller.imageStyles.isNotEmpty) {
        controller.selectStyle(controller.imageStyles.first);
      }
    });
  }

  @override
  void dispose() {
    _styleScrollController.dispose();
    // controller.resetToInitialState();
    super.dispose();
  }

  void _scrollToSelectedStyle() {
    if (!_shouldScroll || _hasScrolled) return;

    final selectedStyle = controller.selectedStyle.value;
    if (selectedStyle == null ||
        controller.currentStep.value != GenerationStep.style) {
      return;
    }

    final styles = controller.imageStyles.value;
    if (styles.isEmpty) return;

    final selectedIndex = styles.indexWhere(
      (style) => style.id == selectedStyle.id,
    );

    if (selectedIndex < 0) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !_styleScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted || !_styleScrollController.hasClients) return;
          _performScroll(selectedIndex);
        });
        return;
      }
      _performScroll(selectedIndex);
    });
  }

  void _performScroll(int selectedIndex) {
    if (!mounted || !_styleScrollController.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = AppSizes.spacingM * 2;
    final availableWidth = screenWidth - horizontalPadding;
    final itemWidth = (availableWidth - (AppSizes.spacingS * 2)) / 3;
    final itemHeight = itemWidth / 0.75;
    const textHeight = 20.0;
    final itemTotalHeight = itemHeight + AppSizes.spacingS + textHeight;

    final row = selectedIndex ~/ 3;

    final scrollPosition =
        (row * itemTotalHeight) - (MediaQuery.of(context).size.height / 3);

    final finalScrollPosition = scrollPosition > 0 ? scrollPosition : 0.0;

    _styleScrollController.animateTo(
      finalScrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _hasScrolled = true;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateDownDirection],
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: false,
        backgroundColor: AppColors.colorBlack,
        resizeToAvoidBottomInset: false,
        body: Obx(
          () {
            final isUploading = controller.isFakeUploading.value &&
                controller.currentStep.value == GenerationStep.image;
            return AbsorbPointer(
              absorbing: isUploading,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: GridBackground(
                      child: SizedBox.shrink(),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SimpleAppBar(
                          title: tr('generation'),
                          onLeadingTap: () async {
                            final hasNet = await NetworkService.to
                                .checkNetworkForInAppFunction();
                            if (!hasNet) return;
                            Get.back();
                            controller.resetToInitialState();
                          },
                        ),
                        //  subtitle
                        Obx(
                          () => Padding(
                              padding: const EdgeInsets.only(
                                  left: AppSizes.spacingM,
                                  right: AppSizes.spacingM,
                                  bottom: AppSizes.spacingS),
                              child: Text(
                                controller.stepSubtitle,
                                style: kTextHeadingStyle.copyWith(fontSize: 14),
                              )),
                        ),
                        // Content area - scrollable
                        Expanded(
                          child: Obx(() {
                            if (controller.currentStep.value ==
                                    GenerationStep.style &&
                                _shouldScroll &&
                                !_hasScrolled) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollToSelectedStyle();
                              });
                            }
                            // Track step change và chỉ log analytics khi step thay đổi
                            final currentStep = controller.currentStep.value;
                            if (_lastStep != currentStep) {
                              _lastStep = currentStep;

                              switch (currentStep) {
                                case GenerationStep.style:
                                  AnalyticsService.shared
                                      .screenChooseStyleShow();
                                  break;
                                case GenerationStep.image:
                                  AnalyticsService.shared
                                      .screenUploadImageShow();
                                  break;
                                case GenerationStep.generate:
                                  AnalyticsService.shared.screenSummaryShow();
                                  break;
                              }
                            }

                            switch (controller.currentStep.value) {
                              case GenerationStep.style:
                                return SingleChildScrollView(
                                  controller: _styleScrollController,
                                  padding: const EdgeInsets.only(
                                      bottom: AppSizes.bottomNavBarHeight * 2),
                                  child: GenerationStyleGridWidget(
                                    styles: controller.imageStyles.value,
                                    selectedStyleId:
                                        controller.selectedStyle.value?.id,
                                    onStyleSelected: (style) =>
                                        controller.selectStyle(style),
                                  ),
                                );
                              case GenerationStep.image:
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSizes.spacingM,
                                    left: AppSizes.spacingM,
                                    right: AppSizes.spacingM,
                                  ),
                                  child: GenerationImageStepWidget(
                                    controller: controller,
                                  ),
                                );
                              case GenerationStep.generate:
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSizes.spacingM,
                                  ),
                                  child: GenerationFinalStepWidget(
                                    controller: controller,
                                  ),
                                );
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                  // Bottom navigation buttons - fix cứng
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Obx(() => Column(
                          children: [
                            _buildBottomNavigation(context),
                            //TODO:ADS HERE
                            if (!RemoteConfigService.shared.adsEnabled)
                              const SizedBox.shrink()
                            else
                              GestureDetector(
                                  onTap: () {
                                    switch (controller.currentStep.value) {
                                      case GenerationStep.style:
                                        AnalyticsService.shared
                                            .bannerAdChooseStyleClick();
                                        break;
                                      case GenerationStep.image:
                                        AnalyticsService.shared
                                            .bannerAdChooseImageClick();
                                        break;
                                      case GenerationStep.generate:
                                        AnalyticsService.shared
                                            .bannerAdSummaryClick();
                                        break;
                                    }
                                  },
                                  child: !RemoteConfigService
                                          .shared.bannerAdaptiveGenerateEnabled
                                      ? const SizedBox.shrink()
                                      : const CollapsibleBannerAdWidget(
                                          placement: 'banner_adaptive_generate',
                                        ))
                          ],
                        )),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final isFirstStep = controller.currentStep.value == GenerationStep.style;
    final isLastStep = controller.currentStep.value == GenerationStep.generate;
    final isEditMode = controller.isEditMode.value;

    return ClipRRect(
      // borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thêm nút Immediately Generate nếu ở step generate
                if (isLastStep &&
                    !isEditMode &&
                    RemoteConfigService.shared.rewardQuickGenerateEnabled &&
                    RemoteConfigService.shared.adsEnabled)
                  GestureDetector(
                    onTap: () {
                      controller.prepareImmediateGeneration();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AppPrimaryButton(
                        customContent: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SvgIcon(name: 'ic_watch_ads_button'),
                            const SizedBox(width: 4),
                            Text(
                              tr('quick_generate'),
                              style: kTextButtonStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // title: tr('quick_generate'),
                        onTap: () => controller.prepareImmediateGeneration(),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    if (!isEditMode &&
                        !isFirstStep &&
                        controller.currentStep.value != GenerationStep.generate)
                      Expanded(
                        child: AppSecondaryButton(
                          title: tr('previous'),
                          onTap: () => controller.previousStep(),
                        ),
                      ),
                    if (!isEditMode &&
                        !isFirstStep &&
                        controller.currentStep.value != GenerationStep.generate)
                      const SizedBox(width: 12),

                    // Continue/Generate button
                    Expanded(
                      child: Obx(() => controller.currentStep.value ==
                              GenerationStep.generate
                          ? AppSecondaryButton(
                              title: isEditMode
                                  ? tr('confirm')
                                  : (isLastStep ? tr('generate') : tr('next')),
                              state: controller.canContinueStep
                                  ? StateButton.active
                                  : StateButton.disable,
                              onTap: () {
                                controller.nextStep();
                              },
                            )
                          : AppPrimaryButton(
                              title: isEditMode
                                  ? tr('confirm')
                                  : (isLastStep ? tr('generate') : tr('next')),
                              state: controller.canContinueStep
                                  ? StateButton.active
                                  : StateButton.disable,
                              onTap: () {
                                controller.nextStep();
                              },
                            )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

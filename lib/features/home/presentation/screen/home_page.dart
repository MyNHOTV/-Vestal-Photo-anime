import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/extensions/context_extensions.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/firebase_messaging_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/style_selection_dialog.dart';
import 'package:flutter_quick_base/core/widgets/text_more_widget.dart';
import 'package:flutter_quick_base/core/widgets/trending_style_grid_widget.dart';
import 'package:flutter_quick_base/core/widgets/style_group_section_widget.dart';
import 'package:flutter_quick_base/features/home/presentation/widget/home_library_widget.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/widgets/grid_background.dart';
import '../controller/home_controller.dart';
import '../widget/home_header_widget.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  HomeController get controller => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    // Đánh dấu app đã sẵn sàng và xử lý pending navigation nếu có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessagingService.shared.markAppReady();
    });

    final imageController = controller.imageGenerationController;
    final screenSize = MediaQuery.of(context).size;
    final headerHeight = screenSize.height / 2.6;

    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateDownDirection],
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Stack(
            children: [
              SafeArea(
                top: false,
                bottom: false,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: AppSizes.spacingL,
                      ),
                      HomeHeaderWidget(
                        height: headerHeight,
                      ),
                      // Content scrollable
                      Column(
                        children: [
                          Obx(() {
                            final groups = controller.styleGroups.toList();
                            return Column(
                              children: groups.asMap().entries.map((entry) {
                                final index = entry.key;
                                final group = entry.value;

                                return Column(
                                  children: [
                                    // Style Group Section
                                    StyleGroupSectionWidget(
                                      groupName: group.name,
                                      icon: group.icon,
                                      styles: group.styles,
                                      isLayoutType1: index % 2 == 0,
                                      onStyleSelected: (style) {
                                        AnalyticsService.shared
                                            .styleClick(style.name);
                                        StyleSelectionDialog.show(
                                          context: context,
                                          style: style,
                                          onCancel: () {
                                            Navigator.of(context).pop();
                                          },
                                          onConfirm: () {
                                            Navigator.of(context).pop();
                                            // Set selected style và navigate to upload image
                                            controller.selectedStyle.value =
                                                style;
                                            final genController = Get.find<
                                                ImageGenerationController>();
                                            genController.selectStyle(style);
                                            genController
                                                .setPreviousRoute('home');
                                            Get.toNamed(
                                              AppRoutes.uploadImage,
                                              arguments: style,
                                            );
                                            // // Navigate to upload image screen
                                            // AdService().loadInterstitial(
                                            //   type: 'inter_new',
                                            //   onComplete: () {
                                            //     AdService().showInterstitial(
                                            //       'inter_new',
                                            //       onComplete: () async {
                                            //         await Future.delayed(
                                            //             const Duration(
                                            //                 milliseconds: 100));
                                            //         // Get.toNamed(
                                            //         //   AppRoutes.generate,
                                            //         //   arguments: {'fromGenerate': true},
                                            //         // );
                                            //         Get.toNamed(
                                            //           AppRoutes.uploadImage,
                                            //           arguments: style,
                                            //         );
                                            //       },
                                            //     );
                                            //   },
                                            // );
                                          },
                                        );
                                      },
                                      onSeeAllTap: () {
                                        Get.toNamed(
                                          AppRoutes.listStyle,
                                          arguments: {
                                            'isView': true,
                                            'styles': group.styles,
                                            'groupName': group.name,
                                          },
                                        );
                                      },
                                    ),

                                    // Thêm Native Ad sau group thứ 2 (index 0)
                                    if (index == 0) ...[
                                      // const SizedBox(height: AppSizes.spacingM),
                                      Obx(() {
                                        if (!RemoteConfigService
                                                .shared.adsEnabled &&
                                            !RemoteConfigService
                                                .shared.nativeImageEnabled) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSizes.spacingM,
                                          ),
                                          child: NativeAdWidget(
                                            uniqueKey: 'native_home',
                                            factoryId: 'native_small_image_top',
                                            hasBorder: true,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                                color: AppColors.colorAE8CF5,
                                                width: 0.5),
                                            backgroundColor: AppColors.surface,
                                            height: 210,
                                            margin: EdgeInsets.zero,
                                            padding: EdgeInsets.zero,
                                            // hasBorder: true,
                                            buttonColor: DynamicThemeService
                                                .shared
                                                .getActiveColorADS(),
                                            adBackgroundColor:
                                                DynamicThemeService.shared
                                                    .getActiveColorADS(),
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: AppSizes.spacingM),
                                    ],
                                  ],
                                );
                              }).toList(),
                            );
                          }),
                          // HomeLibraryWidget(
                          //   controller: imageController,
                          //   onMoreStyleTap: () {
                          //     Get.toNamed(AppRoutes.history);
                          //   },
                          // ),
                          const SizedBox(
                              height: AppSizes.bottomNavBarHeight +
                                  AppSizes.appBarHeight),
                        ],
                      ),
                    ],
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

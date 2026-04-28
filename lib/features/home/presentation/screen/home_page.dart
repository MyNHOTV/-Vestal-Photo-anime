import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/firebase_messaging_service.dart';
import 'package:flutter_quick_base/core/widgets/style_selection_dialog.dart';
import 'package:flutter_quick_base/core/widgets/style_group_section_widget.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

import '../../../../core/constants/export_constants.dart';
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

                                return StyleGroupSectionWidget(
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
                                        controller.selectedStyle.value = style;
                                        final genController = Get.find<
                                            ImageGenerationController>();
                                        genController.selectStyle(style);
                                        genController.setPreviousRoute('home');
                                        Get.toNamed(
                                          AppRoutes.uploadImage,
                                          arguments: style,
                                        );
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

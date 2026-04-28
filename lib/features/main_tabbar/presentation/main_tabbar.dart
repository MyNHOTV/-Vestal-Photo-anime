import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/curve_widget_bottom/dot_curved_bottom_nav.dart';
import 'package:flutter_quick_base/core/widgets/custom_widget_bottom/custom_bottom_nav_bar.dart';
import 'package:flutter_quick_base/features/ai_art/presentation/screen/ai_art_screen.dart';
import 'package:flutter_quick_base/features/ai_tool/presentation/screen/ai_tool_screen.dart';
import 'package:flutter_quick_base/features/library/presentation/screens/library_screen.dart';
import 'package:flutter_quick_base/features/profile/presentation/profile_screen.dart';
import 'package:get/get.dart';

import '../../home/presentation/screen/home_page.dart';
import 'main_tabbar_controller.dart';

class MainTabbar extends StatelessWidget {
  const MainTabbar({super.key});

  List<BottomNavItem> get _bottomNavItems => [
        BottomNavItem(
          iconName: "ic_home_unactive",
          activeIconName: "ic_home_active",
          label: tr('home'),
        ),
        BottomNavItem(
          iconName: "ic_ai_art_unactive",
          activeIconName: "ic_ai_art_active",
          label: tr('ai_art'),
        ),
        BottomNavItem(
          iconName: "ic_ai_tool_unactive",
          activeIconName: "ic_ai_tool_active",
          label: tr('ai_tool'),
        ),
        BottomNavItem(
          iconName: "ic_my_creation_unactive",
          activeIconName: "ic_my_creation_active",
          label: tr('library'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainTabbarController());

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.colorBlack.withOpacity(0.8),
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value.clamp(0, 3),
          children: [
            if (controller.isTabInitialized(0))
              const HomePage(), // index 0: Home
            if (controller.isTabInitialized(2))
              const AiToolScreen(), // index 2: AiTool
            if (controller.isTabInitialized(1))
              const AiArtScreen(), // index 1: AiArt
            if (controller.isTabInitialized(3))
              const LibraryScreen(), // index 3: Library
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => CustomBottomNavBar(
          selectedIndex: controller.currentIndex.value.clamp(0, 3),
          items: _bottomNavItems,
          onTap: (index) {
            controller.changeTab(index);
          },
          showIndicator: true,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

// Widget hiển thị ads ở dưới tab bar
class _BottomAdsRow extends StatelessWidget {
  const _BottomAdsRow();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!RemoteConfigService.shared.isBannerEnabled('banner_home')) {
        return const SizedBox.shrink();
      }
      return Container(
        height: 50, // Chiều cao banner ads
        color: Colors.transparent,
        child: const CollapsibleBannerAdWidget(
          placement: 'banner_home',
          isCollapsible: false,
        ),
      );
    });
  }
}

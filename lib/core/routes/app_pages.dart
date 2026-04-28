import 'package:flutter_quick_base/features/ai_art/presentation/screen/ai_art_screen.dart';
import 'package:flutter_quick_base/features/ai_tool/presentation/screen/ai_tool_screen.dart';
import 'package:flutter_quick_base/features/edit_generate_item/edit_aspect_ratio_screen.dart';
import 'package:flutter_quick_base/features/edit_generate_item/edit_image_screen.dart';
import 'package:flutter_quick_base/features/edit_generate_item/edit_style_screen.dart';
import 'package:flutter_quick_base/features/generation/generation_screen.dart';
import 'package:flutter_quick_base/features/history_screen/history_detail_info_screen.dart';
import 'package:flutter_quick_base/features/history_screen/history_detail_screen.dart';
import 'package:flutter_quick_base/features/history_screen/history_screen.dart';
import 'package:flutter_quick_base/features/image_detail/screen/image_detail_info_screen.dart';
import 'package:flutter_quick_base/features/image_detail/screen/image_detail_screen.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/screens/image_generating_screen.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/screens/image_generation_screen.dart';
import 'package:flutter_quick_base/features/library/presentation/screens/library_screen.dart';
import 'package:flutter_quick_base/features/list_style/list_style_screen.dart';
import 'package:flutter_quick_base/features/main_tabbar/presentation/main_tabbar.dart';
import 'package:flutter_quick_base/features/on_boarding/language_selection_screen.dart';
import 'package:flutter_quick_base/features/on_boarding/on_boarding_screen.dart';
import 'package:flutter_quick_base/features/profile/presentation/profile_screen.dart';
import 'package:flutter_quick_base/features/profile/presentation/screens/settings_screen.dart';
import 'package:flutter_quick_base/features/profile/presentation/widgets/webview_page.dart';
import 'package:flutter_quick_base/features/splash/splash_screen.dart';
import 'package:flutter_quick_base/features/upload_image_screen/upload_image_screen.dart';
import 'package:get/get.dart';

import '../../features/home/presentation/screen/home_page.dart';
import 'app_routes.dart';

/// App Pages configuration
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.mainTabar,
      page: () => const MainTabbar(),
    ),
    GetPage(
      name: AppRoutes.generate,
      page: () => const ImageGenerationScreen(),
    ),
    GetPage(
      name: AppRoutes.library,
      page: () => const LibraryScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: AppRoutes.listStyle,
      // page: ()=> const ListStyleScreen(),
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return ListStyleScreen(
          isView: args?['isView'] ?? true,
          styles: args?['styles'] ?? [],
          initialSelectedIndex: args?['initialSelectedIndex'],
          groupName: args?['groupName'],
          fromGeneration: args?['fromGeneration'] ?? false,
        );
      },
      transition: Transition.rightToLeft, // Hoặc Transition.cupertino
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.imageDetail,
      page: () {
        return const ImageDetailScreen();
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.imageGenerating,
      page: () => const ImageGeneratingScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.imageDetailInfo,
      page: () {
        return const ImageDetailInfoScreen();
      },
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.editStyle,
      page: () => const EditStyleScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.editAspectRatio,
      page: () => const EditAspectRatioScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.editImage,
      page: () => const EditImageScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.historyDetail,
      page: () {
        return const HistoryDetailScreen();
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.historyDetailInfo,
      page: () {
        return const HistoryDetailInfoScreen();
      },
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.languageSelection,
      page: () => const LanguageSelectionScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.uploadImage,
      page: () => const UploadImageScreen(),
    ),
    GetPage(
      name: AppRoutes.generation,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return GenerationScreen(
          uploadedImagePath: args?['uploadedImagePath'] as String?,
          selectedStyleId: args?['selectedStyleId'] as int?,
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.webview,
      page: () {
        final arguments = Get.arguments as Map<String, dynamic>?;
        return WebViewPage(
          url: arguments?['url'] ?? '',
          title: arguments?['title'] ?? '',
        );
      },
    ),
    GetPage(
      name: AppRoutes.aiTools,
      page: () {
        return AiToolScreen();
      },
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.aiArt,
      page: () {
        return AiArtScreen();
      },
      transition: Transition.native,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Thêm các pages khác ở đây
  ];
}

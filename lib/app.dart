import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/image_picker_service.dart';
import 'package:get/get.dart';

import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/image_generation/presentation/controllers/image_generation_controller.dart';

class QuickBaseApp extends StatefulWidget {
  const QuickBaseApp({super.key});

  @override
  State<QuickBaseApp> createState() => _QuickBaseAppState();
}

class _QuickBaseAppState extends State<QuickBaseApp>
    with WidgetsBindingObserver {
  bool _appOpenShownRecently = false;
  bool _isFromBackground = false;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _isFromBackground = true;
    } else if (state == AppLifecycleState.resumed && _isFromBackground) {
      _isFromBackground = false;
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    // Reset cờ tránh bị kẹt trạng thái từ lần resume trước
    _adService.setResumedDuringAd(false);

    // Reset retry count khi app resume để đảm bảo có cơ hội load ad mới
    _adService.resetAppOpenRetryCount();

    // Kiểm tra nếu đang pick image thì không show resume ad
    if (ImagePickerService.shared.isPicking) {
      debugPrint("⏸️ App resumed while picking image, skipping app open ad");
      return;
    }

    // Kiểm tra nếu đang generating thì bỏ qua app open ad
    // (sẽ được handle trong image_generating_screen)
    try {
      if (Get.isRegistered<ImageGenerationController>()) {
        final controller = Get.find<ImageGenerationController>();
        if (controller.isGenerating.value) {
          debugPrint("⏸️ App resumed during generation, skipping app open ad");
          return;
        }
      }
    } catch (e) {
      // Controller không tồn tại, tiếp tục bình thường
    }

    // Thêm điều kiện kiểm tra nếu một quảng cáo toàn màn hình khác đang hiển thị
    if (!mounted ||
        _appOpenShownRecently ||
        _adService.isShowingFullScreenAd ||
        _adService.adJustClosed) {
      if (_adService.isShowingFullScreenAd) {
        debugPrint("📺 App resumed during full screen ad. Setting flag.");
        _adService.setResumedDuringAd(true);
      }
      return;
    }

    await _adService.loadAppOpen(
      'resume',
      onLoaded: () async {
        if (!mounted) return;
        _appOpenShownRecently = true; // Đặt cờ ngay trước khi hiển thị
        await _adService.showAppOpen(
          'resume',
          onComplete: () {
            debugPrint("⭐ AppOpen resume đã show xong.");
            // Đặt lại cờ sau một khoảng thời gian chờ sau khi quảng cáo đã đóng
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                _appOpenShownRecently = false;
              }
            });
          },
        );
      },
      onFailed: () {
        debugPrint("❌ AppOpen resume failed to load.");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: tr('app_title'),
      locale: context.locale,
      fallbackLocale: const Locale('en'),
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      defaultTransition: Transition.rightToLeft,
      getPages: AppPages.pages,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/firebase_messaging_service.dart';
import 'package:flutter_quick_base/main.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isPageAnimating = false;

  List<Widget> get _pages {
    return [
      OnboardingPage(
        pageIndex: 0,
        totalPages: _getTotalPages(),
        image: 'assets/icons/img_page_1.png',
        titleKey: 'turn_ideas_into_images',
        subtitleKey: 'upload_image_to_start_creating',
        onNext: _nextPage,
      ),
      OnboardingPage(
        pageIndex: 1,
        totalPages: _getTotalPages(),
        image: 'assets/icons/img_page_2.png',
        titleKey: 'generate_fast_get_it_right',
        subtitleKey: 'high_quality_images_generated_in_seconds',
        onNext: _nextPage,
      ),
      OnboardingPage(
        pageIndex: 2,
        totalPages: _getTotalPages(),
        image: 'assets/icons/img_page_4.png',
        titleKey: 'save_share_instantly',
        subtitleKey: 'download_share_your_creations_in_one_tap',
        onNext: _completeOnboarding,
        isLast: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.shared.screenOb1Show();
    if (Get.isRegistered<NetworkService>()) {
      NetworkService.to.setNetworkContext(NetworkContext.obd);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<NetworkService>()) {
          NetworkService.to.checkAndShowNetworkDialog();
        }
      });
    }

    _pageController = PageController();
  }

  int _getTotalPages() {
    return 3;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    debugPrint("🎯 Onboarding completed!");
    AnalyticsService.shared.actionCompleteOb();
    await LocalStorageService.shared.put('has_completed_onboarding', true);
    Get.offAllNamed(AppRoutes.mainTabar);
    if (kFirebaseEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseMessagingService.shared.markAppReady();
      });
    }
  }

  void _nextPage() {
    if (!mounted) return;
    if (_isPageAnimating) return;
    if (_currentPage < _pages.length - 1) {
      _isPageAnimating = true;
      _pageController
          .nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut)
          .whenComplete(() {
        _isPageAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(children: [
          SafeArea(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                _isPageAnimating = false;
                setState(() {
                  _currentPage = index;
                });
                switch (index) {
                  case 0:
                    AnalyticsService.shared.screenOb1Show();
                    break;
                  case 1:
                    AnalyticsService.shared.screenOb2Show();
                    break;
                  case 2:
                    AnalyticsService.shared.screenOb3Show();
                    break;
                  case 3:
                    AnalyticsService.shared.screenOb4Show();
                    break;
                  default:
                    break;
                }
              },
              itemBuilder: (context, index) => _pages[index],
            ),
          ),
        ]),
      ),
    );
  }
}

// Onboarding Page với bottom controls tích hợp
class OnboardingPage extends StatelessWidget {
  final int pageIndex;
  final int totalPages;
  final String image;
  final String titleKey;
  final String subtitleKey;
  final VoidCallback onNext;
  final bool isLast;

  const OnboardingPage({
    super.key,
    required this.pageIndex,
    required this.totalPages,
    required this.image,
    required this.titleKey,
    required this.subtitleKey,
    required this.onNext,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = tr(titleKey);
    final subtitle = tr(subtitleKey);

    return Column(
      children: [
        const SizedBox(
          height: AppSizes.spacingM,
        ),
        Expanded(
          flex: 9,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: kBricolageBoldStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.color121212,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: kBricolageRegularStyle.copyWith(
                    fontSize: 14,
                    color: AppColors.color727885,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (image.isNotEmpty)
                  Image.asset(
                    image,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color:
                            DynamicThemeService.shared.getPrimaryAccentColor(),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.image,
                      size: 64,
                      color: DynamicThemeService.shared.getPrimaryAccentColor(),
                    ),
                  ),
                const SizedBox(height: AppSizes.spacingS),
              ],
            ),
          ),
        ),
        Expanded(flex: 1, child: _buildBottomControls(context)),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + bottomInset + 30,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots indicator
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 8,
                  width: pageIndex == index ? 16 : 8,
                  decoration: BoxDecoration(
                    color: pageIndex == index
                        ? DynamicThemeService.shared.getPrimaryAccentColor()
                        : AppColors.disableColorText,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
          // Next / Done button
          GestureDetector(
            onTap: onNext,
            child: Text(
              isLast ? tr('get_started') : tr('next'),
              style: TextStyle(
                fontSize: 14,
                color: DynamicThemeService.shared.getActiveColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

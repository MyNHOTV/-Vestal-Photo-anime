import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/services/firebase_messaging_service.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_2_floor_wrapper.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _maxPageReached = 0;
  late RemoteConfigService remoteConfig;
  bool _isPageAnimating = false;
  bool _shouldShowNativeAdFull = false;

  // Preloaded Ad State
  NativeAd? _preloadedNativeAd;
  bool _isPreloadedAdLoaded = false;

  // Thêm subscription để listen network changes
  Worker? _networkWorker;

  bool get _hasBottomAds {
    return remoteConfig.adsEnabled && NetworkService().isConnected.value;
  }

  List<Widget> get _pages {
    return [
      OnboardingPage(
        pageIndex: 0,
        totalPages: _getTotalPages(),
        image: 'assets/icons/img_page_1.png',
        titleKey: 'turn_ideas_into_images',
        subtitleKey: 'upload_image_to_start_creating',
        onNext: _nextPage,
        hasBottomAds: _hasBottomAds &&
            (remoteConfig.nativeOnboarding1_2FloorEnabled ||
                remoteConfig.nativeOnboarding1Enabled),
      ),
      OnboardingPage(
        pageIndex: 1,
        totalPages: _getTotalPages(),
        image: 'assets/icons/img_page_2.png',
        titleKey: 'generate_fast_get_it_right',
        subtitleKey: 'high_quality_images_generated_in_seconds',
        onNext: _nextPage,
        hasBottomAds: _hasBottomAds &&
            (remoteConfig.nativeOnboarding2_2FloorEnabled ||
                remoteConfig.nativeOnboarding2Enabled),
      ),
      if (_shouldShowNativeAdFull)
        FullScreenNativeAdPage(
          pageIndex: 2,
          totalPages: _getTotalPages(),
          onNext: _nextPage,
          preloadedAd: _preloadedNativeAd,
          isAdLoaded: _isPreloadedAdLoaded,
        ),
      OnboardingPage(
        pageIndex: _shouldShowNativeAdFull ? 3 : 2,
        totalPages: _getTotalPages(),
        image: 'assets/icons/img_page_4.png',
        titleKey: 'save_share_instantly',
        subtitleKey: 'download_share_your_creations_in_one_tap',
        onNext: _completeOnboarding,
        isLast: true,
        hasBottomAds: _hasBottomAds &&
            (remoteConfig.nativeOnboarding3Enabled ||
                remoteConfig.nativeOnboarding3_2FloorEnabled),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.shared.screenOb1Show();
// Set context cho NetworkService
    if (Get.isRegistered<NetworkService>()) {
      NetworkService.to.setNetworkContext(NetworkContext.obd);
      // Check và show popup nếu mạng đã mất từ trước
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<NetworkService>()) {
          NetworkService.to.checkAndShowNetworkDialog();
        }
      });
    }

    remoteConfig = RemoteConfigService.shared;
    _pageController = PageController();

    _shouldShowNativeAdFull = remoteConfig.adsEnabled &&
        (remoteConfig.nativeOnboardingFullEnabled ||
            remoteConfig.nativeOnboardingFull2FloorEnabled) &&
        NetworkService.to.isConnected.value;

    // Thêm listener để theo dõi thay đổi mạng
    _listenToNetworkChanges();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldShowNativeAdFull && _preloadedNativeAd == null) {
        _preloadAd();
      }
    });
  }

  // Thêm method để listen network changes
  void _listenToNetworkChanges() {
    if (!Get.isRegistered<NetworkService>()) return;

    _networkWorker = ever(NetworkService.to.isConnected, (bool isConnected) {
      if (!mounted) return;

      final shouldShow = remoteConfig.adsEnabled &&
          (remoteConfig.nativeOnboardingFullEnabled ||
              remoteConfig.nativeOnboardingFull2FloorEnabled) &&
          isConnected;

      // Chỉ update nếu giá trị thay đổi và đang ở page 0 hoặc 1 (trước khi đến full screen ad)
      if (shouldShow != _shouldShowNativeAdFull && _currentPage < 2) {
        debugPrint(
            '🌐 Network status changed: $isConnected, updating _shouldShowNativeAdFull to $shouldShow');
        setState(() {
          _shouldShowNativeAdFull = shouldShow;
        });

        // Nếu mạng được bật lại và chưa preload ad, thì preload ngay
        if (shouldShow && _preloadedNativeAd == null && _currentPage <= 1) {
          _preloadAd();
        }
      }
    });
  }

  void _preloadAd() {
    if (!_shouldShowNativeAdFull || _preloadedNativeAd != null) return;

    // Đảm bảo có mạng mới load
    if (!NetworkService.to.isConnected.value) {
      debugPrint("🚫 No network, skipping full screen ad preload");
      if (mounted) {
        setState(() {
          _shouldShowNativeAdFull =
              false; // Không load được thì ẩn luôn màn full
        });
      }
      return;
    }
    // Logic: Ưu tiên 2floor, nếu fail thì fallback sang native_onboarding_full
    final bool shouldTry2Floor = remoteConfig.nativeOnboardingFull2FloorEnabled;
    final bool shouldTryNormal = remoteConfig.nativeOnboardingFullEnabled;
    if (!shouldTry2Floor && !shouldTryNormal) {
      debugPrint(
          "🚫 Both native_onboarding_full and native_onboarding_full_2floor are disabled");
      if (mounted) {
        setState(() {
          _shouldShowNativeAdFull = false;
        });
      }
      return;
    }

    // Chọn adUnitId: ưu tiên 2floor nếu enabled
    final adUnitId = shouldTry2Floor
        ? Platform.isAndroid
            ? remoteConfig.androidNativeOnboardingFull2Floor
            : remoteConfig.iosNativeOnboardingFull2Floor
        : Platform.isAndroid
            ? remoteConfig.androidNativeOnboardingFull
            : remoteConfig.iosNativeOnboardingFull;
    final bool isPreloading2Floor = shouldTry2Floor;

    debugPrint('🚀 Preloading Native Onboarding Full Ad...');

    _preloadedNativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId:
          'native_fullscreen_image_1', // Must match NativeAdWidget expectation
      request: const AdRequest(),
      listener: NativeAdListener(
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          final revenue = valueMicros / 1000000.0;
          debugPrint(
            '💰 Native Ad revenue: $revenue $currencyCode (Precision: $precision)',
          );
          final adPlacement = isPreloading2Floor
              ? 'native_onboarding_full_2floor'
              : 'native_onboarding_full';
          AnalyticsService.shared.logAdRevenue(
            amount: revenue,
            currency: currencyCode,
            adNetwork: ad.responseInfo?.mediationAdapterClassName,
            adUnitId: ad.adUnitId,
            adPlacement: adPlacement,
            adType: 'Native',
          );
        },
        onAdLoaded: (ad) {
          debugPrint("✅ Preloaded Native Ad Loaded!");
          if (mounted) {
            setState(() {
              _isPreloadedAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ Preloaded Native Ad Failed: ${error.message}");
          ad.dispose();
          if (isPreloading2Floor && shouldTryNormal) {
            debugPrint(
                "🔀 2Floor failed, falling back to native_onboarding_full...");
            if (mounted) {
              setState(() {
                _preloadedNativeAd = null;
                _isPreloadedAdLoaded = false;
              });
            }
            // Retry với normal floor
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _preloadAdFallback();
              }
            });
          } else {
            // Không có fallback, nhưng vẫn giữ _shouldShowNativeAdFull = true
            // để NativeAd2FloorWrapper có cơ hội load lại
            debugPrint(
                "⚠️ Preload failed, but keeping screen visible for NativeAd2FloorWrapper to retry");
            if (mounted) {
              setState(() {
                _preloadedNativeAd = null;
                _isPreloadedAdLoaded = false;
                // ✅ FIX: KHÔNG ẩn màn hình, để NativeAd2FloorWrapper tự load
                // _shouldShowNativeAdFull = false; // REMOVED
              });
            }
          }
        },
      ),
    );
    _preloadedNativeAd?.load();
  }

  void _preloadAdFallback() {
    if (_preloadedNativeAd != null) return;

    if (!NetworkService.to.isConnected.value) {
      debugPrint("🚫 No network, skipping fallback preload");
      // ✅ FIX: Vẫn giữ màn hình để NativeAd2FloorWrapper tự load
      return;
    }

    final adUnitId = Platform.isAndroid
        ? remoteConfig.androidNativeOnboardingFull
        : remoteConfig.iosNativeOnboardingFull;

    debugPrint(
        '🚀 Preloading Native Onboarding Full Ad (fallback to normal)...');

    _preloadedNativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'native_fullscreen_image_1',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint("✅ Preloaded Native Ad Loaded (fallback)!");
          if (mounted) {
            setState(() {
              _isPreloadedAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
              "❌ Preloaded Native Ad Failed (fallback): ${error.message}");
          ad.dispose();
          // ✅ FIX: Vẫn giữ màn hình, để NativeAd2FloorWrapper tự load
          if (mounted) {
            setState(() {
              _preloadedNativeAd = null;
              _isPreloadedAdLoaded = false;
              // ✅ FIX: KHÔNG ẩn màn hình, để NativeAd2FloorWrapper tự load
              // _shouldShowNativeAdFull = false; // REMOVED
            });
          }
        },
      ),
    );
    _preloadedNativeAd?.load();
  }

  int _getTotalPages() {
    return _shouldShowNativeAdFull ? 4 : 3;
  }

  @override
  void dispose() {
    AdService().setNativeFullScreenAdShowing(false);
    _preloadedNativeAd?.dispose();
    _pageController.dispose();
    // Dispose network worker
    _networkWorker?.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    debugPrint("🎯 Onboarding completed!");
    AnalyticsService.shared.actionCompleteOb();
    await LocalStorageService.shared.put('has_completed_onboarding', true);
    Get.offAllNamed(AppRoutes.mainTabar);
    // Đánh dấu app đã sẵn sàng và xử lý pending navigation nếu có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessagingService.shared.markAppReady();
    });
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
    final pages = _pages;
    final clampedIndex = _currentPage.clamp(
      0,
      pages.isNotEmpty ? pages.length - 1 : 0,
    );
    final isFullScreenAd =
        pages.isNotEmpty && pages[clampedIndex] is FullScreenNativeAdPage;
    final bottomAds = [
      NativeAd2FloorWrapper(
          factoryId: 'native_medium_image_top_2',
          key: const Key('2f_native_onboarding_1_wrapper'),
          primaryUniqueKey: '2f_native_onboarding_1',
          fallbackUniqueKey: 'native_onboarding_1',
          enable2Floor: remoteConfig.nativeOnboarding1_2FloorEnabled,
          buttonColor: DynamicThemeService.shared.getActiveColorADS(),
          adBackgroundColor: DynamicThemeService.shared.getActiveColorADS()),
      const SizedBox.shrink(),
      // NativeAd2FloorWrapper(
      //     key: const Key('2f_native_onboarding_2_wrapper'),
      //     primaryUniqueKey: '2f_native_onboarding_2',
      //     fallbackUniqueKey: 'native_onboarding_2',
      //     enable2Floor: remoteConfig.nativeOnboarding2_2FloorEnabled,
      //     buttonColor: DynamicThemeService.shared.getPrimaryAccentColor(),
      //     adBackgroundColor:
      //         DynamicThemeService.shared.getPrimaryAccentColor()),
      if (_shouldShowNativeAdFull)
        const SizedBox.shrink(key: Key('native_onboarding_full_space')),
      NativeAd2FloorWrapper(
          factoryId: 'native_medium_image_top_2',
          key: const Key('2f_native_onboarding_3_wrapper'),
          primaryUniqueKey: '2f_native_onboarding_3',
          fallbackUniqueKey: 'native_onboarding_3',
          enable2Floor: remoteConfig.nativeOnboarding3_2FloorEnabled,
          buttonColor: DynamicThemeService.shared.getActiveColorADS(),
          adBackgroundColor: DynamicThemeService.shared.getActiveColorADS()),
    ];
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [
          // Positioned.fill(
          //   child: isFullScreenAd
          //       ? const SizedBox.shrink()
          //       : const GridBackground(
          //           child: SizedBox.shrink(),
          //         ),
          // ),
          SafeArea(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                _isPageAnimating = false;
                setState(() {
                  _currentPage = index;
                  if (index > _maxPageReached) {
                    _maxPageReached = index;
                  }
                });
                final isAdPage = _pages[index] is FullScreenNativeAdPage;
                AdService().setNativeFullScreenAdShowing(isAdPage);
                if (index == 0 || index == 1) {
                  if (_shouldShowNativeAdFull && _preloadedNativeAd == null) {
                    _preloadAd();
                  }
                }
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
        bottomNavigationBar: Obx(() {
          if (!RemoteConfigService.shared.adsEnabled) {
            return const SizedBox.shrink();
          }
          return Stack(
            alignment: Alignment.bottomCenter,
            children: List.generate(bottomAds.length, (index) {
              // Chỉ load ad của page hiện tại, page kế tiếp (preload), hoặc các page đã từng qua
              if (index > _currentPage + 1 && index > _maxPageReached) {
                return const SizedBox.shrink();
              }
              return Offstage(
                offstage: _currentPage != index,
                child: bottomAds[index],
              );
            }),
          );
        }),
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
  final bool hasBottomAds;

  const OnboardingPage({
    super.key,
    required this.pageIndex,
    required this.totalPages,
    required this.image,
    required this.titleKey,
    required this.subtitleKey,
    required this.onNext,
    this.isLast = false,
    this.hasBottomAds = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = tr(titleKey);
    final subtitle = tr(subtitleKey);

    return Column(
      children: [
        SizedBox(
          height: AppSizes.spacingM,
        ),
        Expanded(
          flex: 9,
          child: SingleChildScrollView(
            // padding: const EdgeInsets.symmetric(horizontal: 16),
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
                // const SizedBox(height: AppSizes.spacingS),
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
                    fit: BoxFit.fill, // Changed to contain to avoid squishing
                    // height: MediaQuery.of(context).size.height *
                    //     0.35, // Limit image height
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

    return Obx(() {
      final isNetworkConnected = NetworkService().isConnected.value;
      final bool adsActuallyShowing = hasBottomAds && isNetworkConnected;
      final double extraBottomPadding = adsActuallyShowing ? 0 : 30;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + bottomInset + extraBottomPadding,
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
    });
  }
}

// Full-screen Native Ad Page - chỉ cho phép next khi ad đã load
class FullScreenNativeAdPage extends StatefulWidget {
  final int pageIndex;
  final int totalPages;
  final VoidCallback onNext;
  final NativeAd? preloadedAd;
  final bool? isAdLoaded;

  const FullScreenNativeAdPage({
    super.key,
    required this.pageIndex,
    required this.totalPages,
    required this.onNext,
    this.preloadedAd,
    this.isAdLoaded,
  });

  @override
  State<FullScreenNativeAdPage> createState() => _FullScreenNativeAdPageState();
}

class _FullScreenNativeAdPageState extends State<FullScreenNativeAdPage>
    with AutomaticKeepAliveClientMixin {
  bool _isAdLoaded = false;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    if (widget.isAdLoaded == true && widget.preloadedAd != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
          debugPrint('✅ Native full-screen ad already loaded (preloaded)');
        }
      });
    }
  }

  void _onAdLoadingChanged(bool isLoading) {
    if (!isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
          debugPrint('✅ Native full-screen ad loaded, user can proceed');
        }
      });
    }
  }

  void _onAdFailed() {
    debugPrint('⚠️ Native full-screen ad failed, auto skipping...');
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        // Native Ad chiếm toàn màn
        Positioned.fill(
            child: NativeAd2FloorWrapper(
          factoryId: 'native_fullscreen_image_1',
          key: const Key('2f_native_onboarding_full'),
          primaryUniqueKey: '2f_native_onboarding_full',
          fallbackUniqueKey: 'native_onboarding_full',
          enable2Floor:
              RemoteConfigService.shared.nativeOnboardingFull2FloorEnabled,
          onLoadingChanged: _onAdLoadingChanged,
          backgroundColor: Colors.white,
          hasBorder: false,
          onAdFailed: _onAdFailed,
          preloadedAd: widget.preloadedAd,
          isAdLoaded: widget.isAdLoaded,
          buttonColor: DynamicThemeService.shared.getPrimaryAccentColor(),
          titleColor: DynamicThemeService.shared.getPrimaryAccentColor(),
          padding: const EdgeInsets.all(0),
          margin: const EdgeInsets.all(0),
        )),

        // Skip button (chỉ hiện khi ad đã load)
        if (_isAdLoaded)
          Positioned(
            top: _getSafeTop(context) + 24,
            right: 16,
            child: _buildCloseButton(),
          ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: widget.onNext,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 22),
      ),
    );
  }

  /// 📱 Lấy phần top safe area để tránh che status bar
  double _getSafeTop(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top;
  }
}

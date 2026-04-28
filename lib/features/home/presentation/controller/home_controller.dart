import 'dart:io';

import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../image_generation/presentation/controllers/image_generation_controller.dart';
import '../../data/model/image_style_model.dart';
import '../../data/model/image_style_group_model.dart';
import '../../data/model/carousel_style_item_model.dart';

class HomeController extends GetxController {
  final ImageGenerationController imageGenerationController =
      Get.find<ImageGenerationController>();

  final Rx<ImageStyleModel?> selectedStyle = Rx<ImageStyleModel?>(null);
  final RxList<ImageStyleModel> imageStyles = <ImageStyleModel>[].obs;
  final RxList<ImageStyleGroupModel> styleGroups = <ImageStyleGroupModel>[].obs;
  final RxList<CarouselStyleItemModel> sliders = <CarouselStyleItemModel>[].obs;

  // Native ad preload cho slider
  NativeAd? _preloadedNativeSliderAd;
  final RxBool isPreloadedNativeSliderAdLoaded = false.obs;
  Worker? _networkWorker; // Worker để listen network changes

  static const String _hasShownFirstTimeKey =
      'home_has_shown_first_time'; // Key cho storage
  static const String _homeShowCountKey =
      'home_show_count'; // Key để đếm số lần mở home
  @override
  void onInit() {
    super.onInit();
    // Load số lần đã mở home từ storage
    final showCount = LocalStorageService.shared.get<int>(
          _homeShowCountKey,
          defaultValue: 0,
        ) ??
        0;

    // Tăng count lên 1
    final newCount = showCount + 1;
    LocalStorageService.shared.put(_homeShowCountKey, newCount);

    // Track event dựa trên số lần mở
    if (newCount == 1) {
      // Lần đầu tiên
      AnalyticsService.shared.screenHomeFirstShow();
      LocalStorageService.shared.put(_hasShownFirstTimeKey, true);
    } else if (newCount == 2) {
      // Lần thứ 2
      AnalyticsService.shared.screenHomeSecondShow();
    } else {
      // Lần thứ 3 trở đi
      AnalyticsService.shared.screenHomeShow();
    }
    // Set context cho NetworkService khi vào Home
    if (Get.isRegistered<NetworkService>()) {
      NetworkService.to.resetToInAppContext();
    }

    if (RemoteConfigService.shared.isInitialized.value) {
      _loadStyles();
      _loadStyleGroups();
      _loadSliders();
      _preloadNativeSliderAd();
      // Fetch async từ API
      _fetchDataFromAPI();
    } else {
      // Nếu chưa init, đợi cho đến khi init xong
      ever(RemoteConfigService.shared.isInitialized, (bool isInit) {
        if (isInit) {
          _loadStyles();
          _loadStyleGroups();
          _loadSliders();
          _preloadNativeSliderAd();
          // Fetch async từ API
          _fetchDataFromAPI();
        }
      });
    }

    // Listen to network changes để retry preload ad khi mạng được khôi phục
    _listenToNetworkChanges();

    // Listen to Remote Config changes
    ever(RemoteConfigService.shared.reverseStylesOrder, (bool shouldShuffle) {
      _loadStyles();
      _loadStyleGroups();
    });
    // Set first style as selected by default
    if (imageStyles.isNotEmpty) {
      selectedStyle.value = imageStyles.first;
    }
    Future.microtask(() {
      print('🏠 HomeController: Loading history...');
      imageGenerationController.loadHistory(refresh: true);
    });
  }

  @override
  void onReady() {
    super.onReady();
    imageGenerationController.loadHistory(refresh: true);
  }

  void selectStyle(ImageStyleModel style) {
    selectedStyle.value = style;
  }

  void _loadStyles() {
    final styles = HomeDataSource.getImageStyles();
    final shouldShuffle = RemoteConfigService.shared.reverseStylesOrder.value;
    print('HomeController: Loading styles, shouldShuffle: $shouldShuffle');

    // Kiểm tra flag từ Remote Config để xáo trộn danh sách
    if (shouldShuffle) {
      final shuffledStyles = List<ImageStyleModel>.from(styles);
      shuffledStyles.shuffle();
      imageStyles.value = shuffledStyles;
      print('HomeController: Styles shuffled, count: ${shuffledStyles.length}');
    } else {
      imageStyles.value = styles;
      print('HomeController: Styles loaded normally, count: ${styles.length}');
    }
  }

  void _loadStyleGroups() {
    final groups = HomeDataSource.getImageStyleGroups();
    styleGroups.value = groups;
    print('HomeController: Style groups loaded, count: ${groups.length}');
  }

  void _loadSliders() {
    final slidersList = HomeDataSource.getSliders();
    sliders.value = slidersList;
    print('HomeController: Sliders loaded, count: ${slidersList.length}');
  }

  // Fetch data từ API async
  Future<void> _fetchDataFromAPI() async {
    try {
      // Fetch styles trước (quan trọng để có imageUrl)
      final styles = await HomeDataSource.fetchImageStyles();
      if (styles.isNotEmpty) {
        // Reload styles sau khi fetch xong để cập nhật UI
        _loadStyles();
      }

      // Fetch style groups (sẽ tự động fetch sliders trong đó)
      final groups = await HomeDataSource.fetchImageStyleGroups();
      styleGroups.value = groups;
      print(
          'HomeController: Style groups fetched from API, count: ${groups.length}');

      // Load sliders sau khi fetch groups (vì sliders được parse từ cùng JSON)
      _loadSliders();
    } catch (e) {
      print('HomeController: Error fetching data from API: $e');
    }
  }

  bool _isPreloading = false;
  void _preloadNativeSliderAd() {
    final remoteConfig = RemoteConfigService.shared;

    // Kiểm tra xem có enabled không
    if (!remoteConfig.adsEnabled || !remoteConfig.nativeSliderEnabled) {
      print('🚫 Native slider ad disabled, skipping preload');
      return;
    }

    // Nếu đã có ad loaded, không cần preload lại
    if (_preloadedNativeSliderAd != null &&
        isPreloadedNativeSliderAdLoaded.value) {
      print('✅ Native slider ad already cached, skipping preload');
      return;
    }

    // Tránh preload trùng lặp
    if (_isPreloading) return;

    // Đảm bảo có mạng
    if (!NetworkService.to.isConnected.value) {
      print('🚫 No network, skipping native slider ad preload');
      return;
    }

    // Lấy adUnitId
    final adUnitId = Platform.isAndroid
        ? remoteConfig.androidNativeSlider
        : remoteConfig.iosNativeSlider;

    if (adUnitId.isEmpty) {
      print('⚠️ Native Slider Ad Unit ID is empty');
      return;
    }

    print('🚀 Preloading Native Slider Ad...');
    _isPreloading = true;

    // Tạo ad instance mới và gọi load ngay lập tức
    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'native_small_image_bottom_2',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          print("✅ Preloaded Native Slider Ad Loaded!");
          isPreloadedNativeSliderAdLoaded.value = true;
          _isPreloading = false;
        },
        onAdFailedToLoad: (failedAd, error) {
          print("❌ Preloaded Native Slider Ad Failed: ${error.message}");
          failedAd.dispose();
          _isPreloading = false;
          _preloadedNativeSliderAd = null;
          isPreloadedNativeSliderAdLoaded.value = false;
          // Retry sau 3 giây nếu có mạng
          Future.delayed(const Duration(seconds: 3), () {
            if (NetworkService.to.isConnected.value &&
                !isPreloadedNativeSliderAdLoaded.value &&
                !_isPreloading) {
              print('🔄 Retrying Native Slider Ad preload...');
              _preloadNativeSliderAd();
            }
          });
        },
      ),
    );

    // QUAN TRỌNG: Gán ad trước khi gọi load để đảm bảo field không null
    _preloadedNativeSliderAd = ad;
    ad.load();
  }

  NativeAd? get preloadedNativeSliderAd => _preloadedNativeSliderAd;

  // Listen to network changes để retry preload ad khi mạng được khôi phục
  void _listenToNetworkChanges() {
    if (!Get.isRegistered<NetworkService>()) return;

    _networkWorker = ever(NetworkService.to.isConnected, (bool isConnected) {
      final remoteConfig = RemoteConfigService.shared;

      // Nếu mạng được bật lại và ad chưa loaded, thì preload ngay
      if (isConnected &&
          remoteConfig.adsEnabled &&
          remoteConfig.nativeSliderEnabled &&
          !isPreloadedNativeSliderAdLoaded.value &&
          _preloadedNativeSliderAd == null) {
        print('🌐 Network restored, retrying Native Slider Ad preload...');
        _preloadNativeSliderAd();
      }
    });
  }

  @override
  void onClose() {
    _networkWorker?.dispose();
    _preloadedNativeSliderAd?.dispose();
    super.onClose();
  }
}

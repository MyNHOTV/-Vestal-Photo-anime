import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/ads/app_open_manager.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:get/get.dart';
import 'ads/interstitial_manager.dart';
import 'ads/rewarded_manager.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Stream để thông báo khi một quảng cáo toàn màn hình đã đóng.
  final _onAdClosedController = StreamController<void>.broadcast();
  Stream<void> get onAdClosed => _onAdClosedController.stream;

  final RemoteConfigService _remoteConfig = RemoteConfigService.shared;

  late final InterstitialManager _interstitialManager;
  late final RewardedManager _rewardedManager;
  // late final RewardedInterstitialManager _rewardedInterstitialManager;
  late final AppOpenManager _appOpenManager;

  bool _isInitialized = false;
  // Cờ để theo dõi nếu app resume trong khi một quảng cáo toàn màn hình đang hiển thị.
  bool _resumedDuringAd = false;
  bool get resumedDuringAd => _resumedDuringAd;
  void setResumedDuringAd(bool value) {
    debugPrint("🚩 AdService flag 'resumedDuringAd' set to: $value");
    _resumedDuringAd = value;
  }

  // Cờ để theo dõi nếu quảng cáo vừa mới đóng
  bool _adJustClosed = false;
  bool get adJustClosed => _adJustClosed;
  void markAdJustClosed() {
    debugPrint("🚩 AdService: Marked ad as just closed.");
    _adJustClosed = true;
    Future.delayed(const Duration(seconds: 2), () {
      _adJustClosed = false;
      _onAdClosedController.add(null); // Phát tín hiệu ad đã đóng
      debugPrint("🚩 AdService: Reset ad just closed flag.");
    });
  }

  // Cờ để theo dõi nếu Native Full Screen Ad đang hiển thị
  bool _isNativeFullScreenAdShowing = false;
  bool get isNativeFullScreenAdShowing => _isNativeFullScreenAdShowing;
  void setNativeFullScreenAdShowing(bool value) {
    _isNativeFullScreenAdShowing = value;
    debugPrint("🚩 AdService: Native Full Screen Ad showing: $value");
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interstitialManager = InterstitialManager(_remoteConfig, this);
      _rewardedManager = RewardedManager(_remoteConfig, this);
      _appOpenManager = AppOpenManager(_remoteConfig, this);
      _isInitialized = true;
      debugPrint('AdService initialized and managers loaded.');
    } catch (e) {
      // Reset flag nếu khởi tạo thất bại
      _isInitialized = false;
      rethrow;
    }
  }

  void dispose() {
    _onAdClosedController.close();
  }

  // ================= Interstitial =================

  Future<void> loadInterstitial({
    String? type,
    required VoidCallback onComplete,
  }) async {
    // Auto-initialize nếu chưa được khởi tạo
    if (!_isInitialized) {
      await initialize();
    }
    if (!RemoteConfigService.shared.adsEnabled) {
      onComplete.call();
      debugPrint('⚠️ Ads disabled');
      return;
    }

    await _interstitialManager.loadAd(
      type: type,
      onComplete: onComplete,
      context: Get.context!,
    );
  }

  Future<void> showInterstitial(
    String type, {
    VoidCallback? onComplete,
    VoidCallback? onRewarded,
  }) async {
    // Auto-initialize nếu chưa được khởi tạo
    if (!_isInitialized) {
      await initialize();
    }
    if (!RemoteConfigService.shared.adsEnabled) {
      onComplete?.call();
      debugPrint('⚠️ Ads disabled');
      return;
    }

    await _interstitialManager.showAd(type, onComplete: onComplete);
  }

  // ================= Rewarded =================

  Future<void> loadRewarded({
    String? type,
    VoidCallback? onComplete,
  }) async {
    // Auto-initialize nếu chưa được khởi tạo
    if (!_isInitialized) {
      await initialize();
    }

    await _rewardedManager.loadAd(
      type: type,
      onComplete: onComplete,
      context: Get.context!,
    );
  }

  bool canShowRewarded() {
    if (!_isInitialized) {
      return false;
    }
    return _rewardedManager.canShowAd();
  }

  Future<void> showRewarded({
    required VoidCallback onRewarded,
    VoidCallback? onComplete,
  }) async {
    // Auto-initialize nếu chưa được khởi tạo
    if (!_isInitialized) {
      await initialize();
    }

    await _rewardedManager.showAd(
      onRewarded: onRewarded,
      onComplete: onComplete,
    );
  }

  // ================= AppOpen =================

  Future<void> loadAppOpen(
    String type, {
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
    bool showLoading = true,
  }) async {
    // Auto-initialize nếu chưa được khởi tạo
    if (!_isInitialized) {
      await initialize();
    }

    if (_isNativeFullScreenAdShowing) {
      debugPrint("⚠️ Native full screen ad is showing, skip AppOpen.");
      onFailed?.call();
      return;
    }
    await _appOpenManager.loadAd(
      type,
      context: Get.context!,
      onLoaded: onLoaded,
      onFailed: onFailed,
      showLoading: showLoading,
    );
  }

  bool get isShowingFullScreenAd {
    if (!_isInitialized) {
      return false;
    }
    try {
      return _interstitialManager.isShowingAd ||
          _rewardedManager.isShowingAd ||
          _appOpenManager.isShowingAd;
    } catch (e) {
      debugPrint('⚠️ Error checking full screen ad status: $e');
      return false;
    }
  }

  Future<void> showAppOpen(String type, {VoidCallback? onComplete}) async {
    // Auto-initialize nếu chưa được khởi tạo
    if (!_isInitialized) {
      await initialize();
    }

    if (isShowingFullScreenAd) {
      debugPrint("⚠️ Full screen ad is showing, skip AppOpen.");
      onComplete?.call();
      return;
    }

    await _appOpenManager.showAd(type, onComplete: onComplete);
  }

  void resetAppOpenRetryCount() {
    if (!_isInitialized) {
      return;
    }
    _appOpenManager.resetRetryCount();
  }

  Future<void> retryAppOpenIfPending() async {
    if (!_isInitialized) {
      return;
    }
    await _appOpenManager.retryLoadIfPending();
  }

  bool get isAppOpenPendingRetry {
    if (!_isInitialized) return false;
    return _appOpenManager.isPendingRetry;
  }
}

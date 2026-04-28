import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:get/get.dart';

class AdNetworkHelper {
  static Future<bool> hasNetworkConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        debugPrint('⚠️ No internet connection');
        return false;
      }
      // Ping google.com to ensure actual internet access
      final lookup = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      debugPrint('⚠️ Internet check failed');
      return false;
    }
  }
}

class AdUIHelper {
  static OverlayEntry? _whiteOverlay;
  static Future<void> showLoadingDialog() async {
    if (Get.context!.mounted) {
      try {
        showDialog(
          context: Get.context!,
          barrierDismissible: false,
          barrierColor: Colors.white,
          builder: (_) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.colorAE8CF5,
                ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    'Ad is loading...',
                    style: TextStyle(
                      color: AppColors.colorAE8CF5.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        debugPrint("⚠️ Failed to show loading dialog: $e");
      }
    }
  }

  static void hideLoadingDialog() {
    if (Get.context!.mounted && Navigator.canPop(Get.context!)) {
      Navigator.pop(Get.context!);
    }
  }

  /// Hiển thị overlay màu trắng toàn màn hình
  static void showWhiteOverlay() {
    if (_whiteOverlay != null) {
      debugPrint("⚠️ White overlay already showing");
      return;
    }

    final context = Get.key.currentContext ?? Get.overlayContext ?? Get.context;
    if (context == null) {
      debugPrint("⚠️ Cannot show white overlay - context is null");
      return;
    }

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) {
      debugPrint("⚠️ Cannot show white overlay - overlay is null");
      return;
    }

    _whiteOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
      ),
    );

    overlay.insert(_whiteOverlay!);
  }

  /// Ẩn overlay màu trắng
  static void hideWhiteOverlay() {
    if (_whiteOverlay == null) {
      return;
    }

    try {
      _whiteOverlay!.remove();
      _whiteOverlay = null;
    } catch (e) {
      _whiteOverlay = null;
    }
  }
}

class AdRetryHelper {
  static void handleRetry({
    required int retryCount,
    required int maxRetry,
    required Future<void> Function() loader,
    Duration initialDelay = const Duration(seconds: 5),
  }) {
    if (retryCount >= maxRetry) return;
    final delay = initialDelay * (1 << (retryCount - 1));
    Future.delayed(delay, loader);
  }
}

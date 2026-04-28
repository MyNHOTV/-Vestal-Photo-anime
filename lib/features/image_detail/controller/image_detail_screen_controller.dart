import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/image_picker_service.dart';
import 'package:flutter_quick_base/core/services/permission_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/confirm_watch_ad_dialog.dart';
import 'package:flutter_quick_base/core/widgets/download_option_bottom_sheet.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/export_constants.dart';
import '../../../core/services/image_save_service.dart';
import '../../image_generation/data/datasources/aspect_ratio_data_source.dart';
import '../../image_generation/domain/entities/generated_image.dart';
import '../../image_generation/presentation/controllers/image_generation_controller.dart';

class ImageDetailScreenController extends GetxController {
  ImageDetailScreenController();

  // GeneratedImage? image;

  // Observable để theo dõi trạng thái favorite
  final RxBool isFavorite = false.obs;

  // Aspect ratio của ảnh - lấy từ image hoặc mặc định
  final RxString aspectRatio = '1:1'.obs;

  // Giữ tham chiếu đến image hiện tại
  late GeneratedImage image;
  final genController = Get.find<ImageGenerationController>();

  // Track if image is saved
  final RxBool _isSaved = false.obs;

  bool get isImageSaved => _isSaved.value;

  // Track watermark visibility
  final RxBool showWatermark = true.obs;

  // Toast state
  final RxString toastMessage = ''.obs;
  final RxString toastType = 'success'.obs; // 'success' or 'error'
  final RxBool showToast = false.obs;
  Timer? _toastTimer;

  @override
  void onInit() {
    super.onInit();
    // getdữ liệu ban đầu
    if (Get.arguments != null) {
      image = Get.arguments as GeneratedImage;
    }
    // Favorite ban đầu lấy từ image, mặc định là false nếu null
    isFavorite.value = false;

    // Lấy aspect ratio từ image, nếu không có thì dùng mặc định
    aspectRatio.value = image.aspectRatio ??
        AspectRatioDataSource.getDefault()?.aspectRatio ??
        '1:1';
  }

  void markAsSaved() {
    _isSaved.value = true;
  }

  Future<void> handleBackIfNotSaved(BuildContext context) async {
    if (!isImageSaved) {
      await ConfirmWatchAdDialog.show(
        context: Get.context!,
        adCount: 1,
        typeImage: TypeImage.limitToday,
        title: tr('photo_not_saved_continue'),
        confirmText: tr('continue'),
        cancelText: tr('cancel'),
        onConfirm: () {
          Navigator.pop(context, true);
          final genController = Get.find<ImageGenerationController>();
          genController.resetToInitialState();
          Get.offAllNamed(AppRoutes.mainTabar);
        },
        onCancel: () => Navigator.pop(context, false),
      );
    } else {
      final genController = Get.find<ImageGenerationController>();
      genController.resetToInitialState();
      Get.offAllNamed(AppRoutes.mainTabar);
    }
  }

  Future<bool> canProceedToNewImage(BuildContext context) async {
    if (!isImageSaved) {
      final shouldProceed = await ConfirmWatchAdDialog.show(
        context: context,
        adCount: 1,
        typeImage: TypeImage.limitToday,
        title: tr('photo_not_saved_continue'),
        confirmText: tr('continue'),
        cancelText: tr('cancel'),
        onConfirm: () {},
      );
      return shouldProceed == true;
    }
    return true;
  }

  /// Download image với bottom sheet chọn option
  Future<void> downloadImageWithOption(BuildContext context) async {
    final hasPermission =
        await PermissionService.checkLibraryPermissionAndRequest(
      context,
      onPermissionDenied: () {
        // Hiển thị banner notification giống save success thay vì toast overlay
        showToastMessage(tr('gallery_permission_required'), type: 'error');
      },
    );
    if (!hasPermission) {
      return;
    }
    if (!RemoteConfigService.shared.adsEnabled ||
        (!RemoteConfigService.shared.rewardSave1Enabled &&
            !RemoteConfigService.shared.rewardSave3Enabled)) {
      Get.dialog(
        const Center(
          child: SpinKitFadingCircle(
            color: AppColors.disableColorText,
            size: 80,
          ),
        ),
        barrierDismissible: false,
      );

      final saveService = ImageSaveService.shared;
      String? savedPath;

      savedPath = await saveService.saveImageWithWatermark(
        imagePath: image.imagePath,
        context: context,
      );

      if (savedPath != null) {
        print('✅ Ảnh đã được save: $savedPath');
        try {
          final genController = Get.find<ImageGenerationController>();

          print('📸 Đang lưu vào history...');
          await genController.saveToHistoryAfterDownload(
            originalImage: image,
            localPath: savedPath,
          );
          await Future.delayed(const Duration(milliseconds: 300));
          await genController.loadHistory(refresh: true);

          print('✅ Đã lưu vào history thành công!');
          print('✅ History count: ${genController.history.length}');

          markAsSaved(); // Đánh dấu đã save
        } catch (historyError) {
          print('❌ Lỗi khi lưu vào history: $historyError');
          // Vẫn show success vì ảnh đã được save vào gallery
        }
      } else {
        print('❌ Lỗi: savedPath là null');
        Get.back(); // hide loading
        showToastMessage(tr('failed_to_save'), type: 'error');
        return;
      }
      Get.back(); // hide loading
      showToastMessage(tr('save_successfully'), type: 'success');
    } else {
      // Show bottom sheet chọn option
      await DownloadOptionBottomSheet.show(
        context: context,
        onWithWatermark: () async {
          AnalyticsService.shared.actionSaveWtm();
          await _downloadWithWatermark(context);
        },
        onWithoutWatermark: () async {
          AnalyticsService.shared.actionSaveNoWtm();
          await _downloadWithoutWatermark(context);
        },
      );
    }
  }

  Future<void> _downloadWithWatermark(BuildContext context) async {
    // Free - không cần show dialog, không cần xem ad
    await _watchAdsAndDownload(
        context: context, withWatermark: true, adCount: 0);
  }

  Future<void> _downloadWithoutWatermark(BuildContext context) async {
    // Show dialog xác nhận xem 1 ad
    await ConfirmWatchAdDialog.show(
      context: context,
      adCount: 1, // Luôn là 1 ad
      onConfirm: () async {
        await _watchAdsAndDownload(
            context: context, withWatermark: false, adCount: 1);
      },
    );
  }

  Future<void> _watchAdsAndDownload({
    required BuildContext context,
    required bool withWatermark,
    required int adCount,
  }) async {
    try {
      bool adsCompleted = false;
      if (withWatermark) {
        // Free - không cần xem ad
        adsCompleted = true;
      } else {
        // Không watermark - xem 1 reward ad
        AnalyticsService.shared.rewardAdSaveLoad();
        final completer = Completer<bool>();

        await AdService().loadRewarded(
          type: 'reward_save_1',
          onComplete: () async {
            AnalyticsService.shared.rewardAdSaveImp();
            bool isRewarded = false;
            await AdService().showRewarded(
              onRewarded: () {
                AnalyticsService.shared.rewardAdSaveReward();
                isRewarded = true;
              },
              onComplete: () {
                if (!completer.isCompleted) completer.complete(isRewarded);
              },
            );
          },
        );

        adsCompleted = await completer.future;
        if (!adsCompleted) {
          AnalyticsService.shared.rewardAdSaveFail();
          Get.back();
          return;
        }
      }
      Get.dialog(
        const Center(
          child: SpinKitFadingCircle(
            color: AppColors.disableColorText,
            size: 80,
          ),
        ),
        barrierDismissible: false,
      );

      final saveService = ImageSaveService.shared;
      String? savedPath;

      if (withWatermark) {
        savedPath = await saveService.saveImageWithWatermark(
          imagePath: image.imagePath,
          context: context,
        );
      } else {
        savedPath = await saveService.saveImageWithoutWatermark(
          imagePath: image.imagePath,
        );
      }

      if (savedPath != null) {
        print('✅ Ảnh đã được save: $savedPath');
        try {
          final genController = Get.find<ImageGenerationController>();

          print('📸 Đang lưu vào history...');
          await genController.saveToHistoryAfterDownload(
            originalImage: image,
            localPath: savedPath,
          );
          await Future.delayed(const Duration(milliseconds: 300));
          await genController.loadHistory(refresh: true);

          print('✅ Đã lưu vào history thành công!');
          print('✅ History count: ${genController.history.length}');

          markAsSaved(); // Đánh dấu đã save
        } catch (historyError) {
          print('❌ Lỗi khi lưu vào history: $historyError');
          // Vẫn show success vì ảnh đã được save vào gallery
        }
      } else {
        print('❌ Lỗi: savedPath là null');
        Get.back(); // hide loading
        showToastMessage(tr('failed_to_save'), type: 'error');
        return;
      }
      Get.back(); // hide loading
      showToastMessage(tr('save_successfully'), type: 'success');
    } catch (e) {
      print('❌ Lỗi khi download: $e');
      Get.back(); // hide loading
      showToastMessage(tr('failed_to_save'), type: 'error');
    }
  }

  /// Share ảnh
  Future<void> shareImageWithOption(BuildContext context) async {
    // Show bottom sheet chọn option
    if (!RemoteConfigService.shared.adsEnabled ||
        (!RemoteConfigService.shared.rewardShare1Enabled &&
            !RemoteConfigService.shared.rewardShare3Enabled)) {
      Get.dialog(
        const Center(
          child: SpinKitFadingCircle(
            color: AppColors.disableColorText,
            size: 80,
          ),
        ),
        barrierDismissible: false,
      );
      ImagePickerService.shared.setSharing(true);
      final saveService = ImageSaveService.shared;
      File? shareFile;

      shareFile = await saveService.shareImageWithWatermark(
        imagePath: image.imagePath,
        context: context,
      );

      if (shareFile == null || !await shareFile.exists()) {
        print('❌ Lỗi: shareFile là null hoặc không tồn tại');
        showToastMessage(tr('failed_to_share'), type: 'error');
        Future.delayed(const Duration(milliseconds: 500), () {
          ImagePickerService.shared.setSharing(false);
        });
        return;
      }

      // Share file
      final result = await Share.shareXFiles(
        [XFile(shareFile.path)],
        text: tr('share'),
      );

      if (await shareFile.exists()) {
        await shareFile.delete();
      }
      Get.back(); // hide loading
      // Reset flag sau một chút delay để app resume có thể check được
      Future.delayed(const Duration(milliseconds: 500), () {
        ImagePickerService.shared.setSharing(false);
      });
      if (result.status == ShareResultStatus.success) {
        showToastMessage(tr('shared_successfully'), type: 'success');
      } else if (result.status == ShareResultStatus.dismissed) {
      } else {
        showToastMessage(tr('failed_to_share'), type: 'error');
      }
    } else {
      await DownloadOptionBottomSheet.show(
        context: context,
        onWithWatermark: () async {
          AnalyticsService.shared.actionShareWtm();
          await _shareWithWatermark(context);
        },
        onWithoutWatermark: () async {
          AnalyticsService.shared.actionShareNoWtm();
          await _shareWithoutWatermark(context);
        },
        headerTitle: tr('share_image'),
        withWatermarkTitle: tr('share_with_watermark'),
        withoutWatermarkTitle: tr('share_without_watermark'),
        showWithWatermark: RemoteConfigService.shared.adsEnabled &&
            RemoteConfigService.shared.rewardShare1Enabled,
        showWithoutWatermark: RemoteConfigService.shared.adsEnabled &&
            RemoteConfigService.shared.rewardShare3Enabled,
      );
    }
  }

  Future<void> _shareWithWatermark(BuildContext context) async {
    // Free - không cần show dialog, không cần xem ad
    await _watchAdsAndShare(context: context, withWatermark: true, adCount: 0);
  }

  Future<void> _shareWithoutWatermark(BuildContext context) async {
    // Show dialog xác nhận xem 1 ad
    await ConfirmWatchAdDialog.show(
      context: context,
      adCount: 1, // Luôn là 1 ad
      title: tr('watch_video_to_share'),
      onConfirm: () async {
        await _watchAdsAndShare(
            context: context, withWatermark: false, adCount: 1);
      },
    );
  }

  Future<void> _watchAdsAndShare({
    required BuildContext context,
    required bool withWatermark,
    required int adCount,
  }) async {
    try {
      ImagePickerService.shared.setSharing(true);
      // Show reward ads
      bool adsCompleted = false;
      if (withWatermark) {
        // Free - không cần xem ad
        adsCompleted = true;
      } else {
        // Không watermark - xem 1 reward ad
        AnalyticsService.shared.rewardAdShareLoad();
        final completer = Completer<bool>();

        await AdService().loadRewarded(
          type: 'reward_share_1',
          onComplete: () async {
            AnalyticsService.shared.rewardAdShareImp();
            bool isRewarded = false;
            await AdService().showRewarded(
              onRewarded: () {
                AnalyticsService.shared.rewardAdShareReward();
                isRewarded = true;
              },
              onComplete: () {
                if (!completer.isCompleted) completer.complete(isRewarded);
              },
            );
          },
        );

        adsCompleted = await completer.future;
        if (!adsCompleted) {
          AnalyticsService.shared.rewardAdShareFail();
          Future.delayed(const Duration(milliseconds: 500), () {
            ImagePickerService.shared.setSharing(false);
          });
          return;
        }
      }
      Get.dialog(
        const Center(
          child: SpinKitFadingCircle(
            color: AppColors.disableColorText,
            size: 80,
          ),
        ),
        barrierDismissible: false,
      );
      final saveService = ImageSaveService.shared;
      File? shareFile;

      if (withWatermark) {
        shareFile = await saveService.shareImageWithWatermark(
          imagePath: image.imagePath,
          context: context,
        );
      } else {
        shareFile = await saveService.shareImageWithoutWatermark(
          imagePath: image.imagePath,
        );
      }
      if (shareFile == null || !await shareFile.exists()) {
        print('❌ Lỗi: shareFile là null hoặc không tồn tại');
        showToastMessage(tr('failed_to_share'), type: 'error');
        Future.delayed(const Duration(milliseconds: 500), () {
          ImagePickerService.shared.setSharing(false);
        });
        return;
      }

      // Share file
      final result = await Share.shareXFiles(
        [XFile(shareFile.path)],
        text: tr('share'),
      );

      if (await shareFile.exists()) {
        await shareFile.delete();
      }
      Get.back(); // hide loading
      Future.delayed(const Duration(milliseconds: 500), () {
        ImagePickerService.shared.setSharing(false);
      });
      if (result.status == ShareResultStatus.success) {
        showToastMessage(tr('shared_successfully'), type: 'success');
      } else if (result.status == ShareResultStatus.dismissed) {
      } else {
        showToastMessage(tr('failed_to_share'), type: 'error');
      }
    } catch (e) {
      Get.back(); // hide loading
      print('❌ Lỗi khi share: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _showToast(tr('failed_to_share'), isError: true);
      Future.delayed(const Duration(milliseconds: 500), () {
        ImagePickerService.shared.setSharing(false);
      });
    }
  }

  Future<void> shareImage(BuildContext context) async {
    await shareImageWithOption(context);
  }

  double _getAspectRatioValue() {
    final parts = aspectRatio.value.split(':');
    if (parts.length == 2) {
      final width = double.tryParse(parts[0]);
      final height = double.tryParse(parts[1]);
      if (width != null && height != null && height != 0) {
        return width / height;
      }
    }
    return 1.0; // Default 1:1
  }

  double get aspectRatioValue => _getAspectRatioValue();

  void _showToast(String message, {bool isError = false, String? type}) {
    toastMessage.value = message;
    // Nếu có type được truyền vào, dùng type đó, nếu không thì dựa vào isError
    if (type != null) {
      toastType.value = type;
    } else {
      toastType.value = isError ? 'error' : 'success';
    }
    showToast.value = true;

    // Cancel existing timer if any
    _toastTimer?.cancel();

    // Auto hide after 3 seconds
    _toastTimer = Timer(const Duration(seconds: 3), () {
      showToast.value = false;
    });
  }

  // Public method để hiển thị toast từ bên ngoài
  void showToastMessage(String message, {bool isError = false, String? type}) {
    _showToast(message, isError: isError, type: type);
  }

  @override
  void onClose() {
    _toastTimer?.cancel();
    super.onClose();
  }
}

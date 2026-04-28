import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_coin.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/utils/export_extensions.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:get/get.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/network/errors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/daily_generation_service.dart';
import '../../../../core/services/firebase_storage_service.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/widgets/confirm_watch_ad_dialog.dart';
import '../../domain/entities/generated_image.dart';
import '../../domain/usecases/image_generation_usecase.dart';

class ImageGenerationController extends GetxController {
  ImageGenerationController({
    required ImageGenerationUsecase imageGenerationUsecase,
  }) : _imageGenerationUsecase = imageGenerationUsecase;

  final ImageGenerationUsecase _imageGenerationUsecase;

  final RxBool isGenerating = false.obs;
  final Rx<AppError?> error = Rx<AppError?>(null);
  final Rx<AppError?> historyError = Rx<AppError?>(null);
  final Rx<AppError?> favoritesError = Rx<AppError?>(null);

  final RxList<GeneratedImage> _latestGenerated = <GeneratedImage>[].obs;
  final RxList<GeneratedImage> history = <GeneratedImage>[].obs;
  final RxList<GeneratedImage> favorites = <GeneratedImage>[].obs;

  final Rx<ImageStyleModel?> selectedStyle = Rx<ImageStyleModel?>(null);
  final RxList<ImageStyleModel> imageStyles = <ImageStyleModel>[].obs;

  /// Danh sách các style đã chọn (hiển thị trong horizontal widget)
  final RxList<ImageStyleModel> selectedStyles = <ImageStyleModel>[].obs;

  /// Aspect ratio đã chọn (mặc định: "1:1")
  final RxString selectedAspectRatio = '1:1'.obs;

  /// URL ảnh đã chọn từ Firebase Storage (nếu có)
  final RxString selectedImageUrl = ''.obs;

  // Lưu URL ảnh cũ để xóa khi thay thế
  String? _previousImageUrl;

  /// Local file path của ảnh đã chọn (nếu có)
  final RxString selectedImagePath = ''.obs;

  // Lưu URL ảnh đã upload để xóa sau khi generate
  String? _uploadedImageUrl;

  // Biến tạm để lưu ảnh input khi vào màn detail (để regenerate)
  String? _tempInputImagePath;

  /// Prompt text đã nhập
  final RxString promptText = ''.obs;

  /// Kiểm tra có thể generate không (không cần prompt nữa)
  bool get canGenerate => true; // Luôn cho phép generate

  /// Trạng thái prompt có hợp lệ không (không cần validation nữa)
  final RxBool isValidPrompt = true.obs; // Luôn true

  void updateValidPrompt(bool isValid) {
    // Không cần validate nữa, luôn true
    isValidPrompt.value = true;
  }

  TextEditingController promptController = TextEditingController();

  //get SurpriseMe method
  void setSaveMeMethod() {
    promptController.text = RemoteConfigService.shared.surpriseMe;
    promptText.value = promptController.text;
  }

  final RxBool isLoadingImageThumb = false.obs;

  // Fake upload state
  final RxBool isFakeUploading = false.obs;
  final RxDouble fakeUploadProgress = 0.0.obs;
  final RxString previousRoute = ''.obs; // 'home' hoặc 'listStyle'

  final RxList<ImageStyleModel> previousListStyleStyles =
      <ImageStyleModel>[].obs;
  final RxString previousListStyleGroupName = ''.obs;

  void setPreviousRoute(String route) {
    previousRoute.value = route;
  }

  void setPreviousListStyleData({
    required List<ImageStyleModel> styles,
    required String groupName,
  }) {
    previousListStyleStyles.value = styles;
    previousListStyleGroupName.value = groupName;
  }

  @override
  void onInit() {
    super.onInit(); // Load styles
    _loadStyles();

    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final preSelectedStyle = args['style'] as ImageStyleModel?;
      if (preSelectedStyle != null) {
        selectedStyle.value = preSelectedStyle;
      }
    }
    // Listen to Remote Config changes
    ever(RemoteConfigService.shared.reverseStylesOrder, (bool shouldShuffle) {
      _loadStyles();
    });

    // Khởi tạo aspect ratio mặc định là 1:1
    if (selectedAspectRatio.value.isEmpty) {
      selectedAspectRatio.value = '1:1';
    }

    Future.microtask(() {
      loadHistory(refresh: true);
    });
  }

  @override
  void onReady() {
    // Kiểm tra nếu có style được truyền từ arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final preSelectedStyle = args['style'] as ImageStyleModel?;
      if (preSelectedStyle != null) {
        selectedStyle.value = preSelectedStyle;
      }
      // Nếu đi từ màn generate, tự động chọn phần tử đầu tiên
      final fromGenerate = args['fromGenerate'] as bool? ?? false;
      if (fromGenerate &&
          selectedStyle.value == null &&
          imageStyles.isNotEmpty) {
        selectedStyle.value = imageStyles.first;
      }
    }
    loadHistory(refresh: true);
    super.onReady();
  }

  void _loadStyles() {
    final styles = HomeDataSource.getImageStyles();

    if (RemoteConfigService.shared.reverseStylesOrder.value) {
      final shuffledStyles = List<ImageStyleModel>.from(styles);
      shuffledStyles.shuffle();
      imageStyles.value = shuffledStyles;
    } else {
      imageStyles.value = styles;
    }
    // Tự động chọn phần tử đầu tiên nếu chưa có style nào được chọn và đi từ generate
    final args = Get.arguments;
    final fromGenerate = args != null &&
        args is Map<String, dynamic> &&
        (args['fromGenerate'] as bool? ?? false);

    if (fromGenerate && selectedStyle.value == null && imageStyles.isNotEmpty) {
      selectedStyle.value = imageStyles.first;
    }
  }

  void updateStyleFromArguments() {
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final preSelectedStyle = args['style'] as ImageStyleModel?;
      if (preSelectedStyle != null) {
        selectedStyle.value = preSelectedStyle;
        // Reset về step style khi có style mới
        currentStep.value = GenerationStep.style;
      }
      // Nếu đi từ màn generate, tự động chọn phần tử đầu tiên
      final fromGenerate = args['fromGenerate'] as bool? ?? false;
      if (fromGenerate &&
          selectedStyle.value == null &&
          imageStyles.isNotEmpty) {
        selectedStyle.value = imageStyles.first;
      }
    }
  }

  @override
  void onClose() {
    resetToInitialState();
    super.onClose();
  }

  /// Reset tất cả trạng thái về ban đầu
  void resetToInitialState() {
    // Reset step về ban đầu
    currentStep.value = GenerationStep.style;

    // Reset style selection
    selectedStyle.value = null;
    selectedStyles.clear();

    // Reset image selections
    selectedImagePath.value = '';
    selectedImageUrl.value = '';
    _previousImageUrl = null;
    _uploadedImageUrl = null;
    _tempInputImagePath = null;

    // Reset aspect ratio về mặc định
    selectedAspectRatio.value = '1:1';

    // Reset prompt
    promptText.value = '';
    isValidPrompt.value = false;
    promptController.clear();

    // Reset errors
    error.value = null;

    // Reset step về ban đầu
    currentStep.value = GenerationStep.style;

    // Reset edit mode
    _exitEditMode();

    // Reset generating state (nếu đang generate thì giữ nguyên, nhưng thường thì không cần)
    isGenerating.value =
        false; // Có thể không cần reset vì khi back thì không còn generate nữa
  }

  void selectStyle(ImageStyleModel style) {
    selectedStyle.value = style;
    _checkEditModeChanges();
  }

  void addOrSelectStyle(ImageStyleModel style) {
    // Check xem style đã có trong danh sách đã chọn chưa (theo name)
    final existingIndex = selectedStyles
        .indexWhere((s) => s.name.toLowerCase() == style.name.toLowerCase());

    if (existingIndex >= 0) {
      // Đã có trong danh sách, chỉ select
      selectedStyle.value = selectedStyles[existingIndex];
    } else {
      // Chưa có, thêm vào đầu danh sách
      selectedStyles.insert(0, style);
      selectedStyle.value = style;
    }
  }

  /// Chọn aspect ratio
  void selectAspectRatio(String aspectRatio) {
    selectedAspectRatio.value = aspectRatio;
    _checkEditModeChanges();
  }

  /// Convert aspect ratio từ "1:1" sang "1x1" để gửi API
  String? get sizeForApi {
    if (selectedAspectRatio.value.isEmpty) return null;
    return selectedAspectRatio.value.replaceAll(':', 'x');
  }

  Future<void> selectImage(BuildContext context) async {
    try {
      // Hiển thị bottom sheet chọn nguồn ảnh
      final file =
          await ImagePickerService.shared.pickImageFromGallery(context);
      if (file == null) return;

      // Bắt đầu fake upload progress
      isFakeUploading.value = true;
      fakeUploadProgress.value = 0.0;

      // Simulate fake upload progress
      await _simulateFakeUpload();

      selectedImagePath.value = file.path;
      isFakeUploading.value = false;
      fakeUploadProgress.value = 0.0;

      _checkEditModeChanges();
    } catch (e) {
      selectedImagePath.value = '';
      isFakeUploading.value = false;
      fakeUploadProgress.value = 0.0;
      context.showErrorToast(
          tr('error_selecting_image', namedArgs: {'error': e.toString()}));
    }
  }

  /// Helper method để xóa ảnh từ Firebase
  Future<void> _deleteImageFromFirebase(String url) async {
    try {
      final storageService = FirebaseStorageService.shared;
      await storageService.deleteImage(url);
      print('Đã xóa ảnh từ Firebase: $url');
    } catch (e) {
      print('Lỗi khi xóa ảnh từ Firebase: $e');
      // Không throw error để không ảnh hưởng đến flow chính
    }
  }

  /// Xóa ảnh đã chọn
  void clearSelectedImage() async {
    selectedImagePath.value = '';
    selectedImageUrl.value = '';
    _previousImageUrl = null;
    isFakeUploading.value = false;
    fakeUploadProgress.value = 0.0;
    _checkEditModeChanges();
  }

  /// Cập nhật prompt text
  void updatePromptText(String text) {
    promptText.value = text;
  }

  GeneratedImage? get latestGenerated =>
      _latestGenerated.isNotEmpty ? _latestGenerated.first : null;

  List<GeneratedImage> get generatedImages => _latestGenerated;

  Future<void> fakeDetailGenerate() async {
    await DailyGenerationService.shared.useGeneration();
    print(caculatedCost);
    final GeneratedImage data = GeneratedImage(
        id: 'fake_id_123',
        prompt: 'A beautiful anime',
        userPrompt: "A beautiful anime userForm",
        imagePath:
            // //1:1
            // 'https://webstatic.aiproxy.vip/output/20251128/26058/1ecd019d-f716-49ed-8ef6-0399680a50ea.png',
            //16:9
            'https://bizyair-prod.oss-cn-shanghai.aliyuncs.com/outputs%2F0cf1de5a-2a5f-476a-858d-437107b0b9ea_e6183dcecfab103e32b6e4ea80fb7371_ComfyUI_aefab3a4_00001_.png?OSSAccessKeyId=LTAI5tPza7RAEKed35dCML5U&Expires=1768296779&Signature=%2BPB1sBbvily9Rvqv9LmyY0mkYeA%3D',
        isFavorite: false,
        createdAt: DateTime.now(),
        styleId: selectedStyle.value?.id,
        aspectRatio: selectedAspectRatio.value);
    Get.offNamed(AppRoutes.imageDetail, arguments: data);
  }

  Future<void> prepareGeneration() async {
    if (isGenerating.value) return;

    // Kiểm tra giới hạn generate hàng ngày
    await DailyGenerationService.shared.checkAndResetDailyCount();
    if (DailyGenerationService.shared.hasReachedLimit) {
      // Hiển thị dialog thông báo hết lượt
      _showDailyLimitDialog();
      return;
    }

    // Kiểm tra mạng trước khi generate
    if (Get.isRegistered<NetworkService>()) {
      final hasNetwork = await NetworkService.to.checkNetworkForInAppFunction();
      if (!hasNetwork) {
        debugPrint('🌐 No network, blocking generation function');
        return;
      }
    }

    isGenerating.value = true;
    error.value = null;
    // Navigate to loading screen
    AdService().loadInterstitial(
      type: 'inter_processing',
      onComplete: () {
        AdService().showInterstitial(
          'inter_processing',
          onComplete: () async {
            await Future.delayed(const Duration(milliseconds: 100));
            Get.toNamed(AppRoutes.imageGenerating);
          },
        );
      },
    );
  }

  /// Generate ngay lập tức với reward ad
  Future<void> prepareImmediateGeneration() async {
    if (isGenerating.value) return;

    // Kiểm tra mạng
    if (Get.isRegistered<NetworkService>()) {
      final hasNetwork = await NetworkService.to.checkNetworkForInAppFunction();
      if (!hasNetwork) {
        debugPrint('🌐 No network, blocking generation function');
        return;
      }
    }

    // Hiển thị dialog xác nhận xem reward ad
    _showRewardAdDialog();
  }

  /// Hiển thị dialog thông báo hết lượt generate
  void _showDailyLimitDialog() {
    final adCount = RemoteConfigService.shared.adCountDailyLimitGenerate;
    ConfirmWatchAdDialog.show(
      context: Get.context!,
      adCount: adCount,
      typeImage: TypeImage.limitToday,
      title: tr('you_have_reached_today_limit_title'),
      content: tr('you_have_reached_today_limit_message'),
      onConfirm: () async {
        AnalyticsService.shared.actionGenerateLimit();
        await _watchRewardAdAndGenerate(adCount: adCount);
      },
    );
  }

  /// Hiển thị dialog xác nhận xem reward ad
  void _showRewardAdDialog() async {
    // Check if reward quick generate is enabled
    if (!RemoteConfigService.shared.rewardQuickGenerateEnabled &&
        !RemoteConfigService.shared.adsEnabled) {
      // If disabled, proceed directly (or handle as normal generation)
      isGenerating.value = true;
      error.value = null;
      Get.toNamed(AppRoutes.imageGenerating);
      return;
    }

    final adCount = RemoteConfigService
        .shared.adCountDailyLimitGenerate; // Quick generate only needs 1 ad
    await ConfirmWatchAdDialog.show(
      context: Get.context!,
      adCount: adCount,
      currentCount: 0,
      title: tr('watch_video_to_generate_message'),
      onConfirm: () async {
        await _watchRewardAdAndGenerate(adCount: adCount);
      },
    );
  }

  /// Xem reward ad và generate
  Future<void> _watchRewardAdAndGenerate({required int adCount}) async {
    try {
      final completer = Completer<bool>();

      await AdService().loadRewarded(
        type: 'reward_quick_generate',
        onComplete: () async {
          bool isRewarded = false;
          await AdService().showRewarded(
            onRewarded: () {
              isRewarded = true;
              // Thêm 1 lượt generate (optional, if daily limit logic applies)
              DailyGenerationService.shared.addExtraGeneration();
            },
            onComplete: () {
              if (!completer.isCompleted) completer.complete(isRewarded);
            },
          );
        },
      );

      final rewarded = await completer.future;
      if (rewarded) {
        // Tiếp tục generate
        isGenerating.value = true;
        error.value = null;
        Get.toNamed(
          AppRoutes.imageGenerating,
          arguments: {'fastMode': true},
        );
      } else {
        // User closed ad early or failed to show
        // Stay on Summary screen (do nothing)
      }
    } catch (e) {
      debugPrint('Error watching reward ad: $e');
    }
  }

  Future<void> executeGenerateAPI() async {
    if (!isGenerating.value) return;
    try {
      List<String>? imageUrls;
      String? uploadedImageUrl;

      String? imagePathToUpload;
      if (selectedImagePath.value.isNotEmpty) {
        imagePathToUpload = selectedImagePath.value;
      }

      // Upload ảnh nếu có
      if (imagePathToUpload != null && imagePathToUpload.isNotEmpty) {
        try {
          final storageService = FirebaseStorageService.shared;
          final uploadedUrl = await storageService.uploadImageAndGetUrl(
            filePath: imagePathToUpload,
            folder: 'input_images',
          );

          if (uploadedUrl != null) {
            imageUrls = [uploadedUrl];
            uploadedImageUrl = uploadedUrl;
          } else {
            error.value = AppError.unknown(
              message: 'Không thể upload ảnh lên Firebase Storage',
            );
            isGenerating.value = false;
            return;
          }
        } catch (e) {
          error.value = AppError.unknown(
            message:
                tr('error_uploading_image', namedArgs: {'error': e.toString()}),
          );
          isGenerating.value = false;
          return;
        }
      }

      // Tạo prompt
      var finalPrompt = promptText.value.trim();
      final styleName = selectedStyle.value?.description ?? '';
      if (imagePathToUpload == null || imagePathToUpload.isEmpty) {
        finalPrompt = tr('art_prompt_no_image', namedArgs: {
          'user_prompt': promptText.value,
          'style_prompt': styleName
        });
      } else {
        finalPrompt = tr('art_prompt_no_image', namedArgs: {
          'user_prompt': promptText.value,
          'style_prompt': styleName
        });
      }

      final finalSize = sizeForApi;
      AnalyticsService.shared.actionStyleCall(styleName);
      // Gọi API
      final response = await _imageGenerationUsecase.generateImage(
        model: AppStrings.modelNanoBanana,
        prompt: finalPrompt,
        userPrompt: promptText.value,
        imageUrls: imageUrls != null && imageUrls.isNotEmpty ? imageUrls : null,
        size: finalSize,
        aspectRatio: selectedAspectRatio.value,
        styleId: selectedStyle.value?.id,
        existingId: null,
      );

      await response.fold(
        (err) async {
          try {
            error.value = err;
            _latestGenerated.clear();
            isGenerating.value = false;
            if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
              try {
                await _deleteImageFromFirebase(uploadedImageUrl);
              } catch (e) {
                print('Error deleting uploaded image: $e');
              }
            }
          } catch (e) {
            print('Error handling API error: $e');
            isGenerating.value = false;
          }
        },
        (data) async {
          try {
            _latestGenerated.assignAll(data);
            isGenerating.value = false;
            if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
              try {
                await _deleteImageFromFirebase(uploadedImageUrl);
              } catch (e) {
                print('Error deleting uploaded image after success: $e');
              }
            }
            if (selectedImagePath.value.isNotEmpty) {
              _tempInputImagePath = selectedImagePath.value;
            }
            selectedImagePath.value = '';
            _uploadedImageUrl = null;
          } catch (e) {
            print('Error handling API success: $e');
            isGenerating.value = false;
          }
        },
      );
    } catch (e) {
      print('Unexpected error in executeGenerateAPI: $e');
      error.value = AppError.unknown(
        message: 'Lỗi không mong đợi: ${e.toString()}',
      );
      isGenerating.value = false;
    }
  }

  Future<void> generate({
    String model = 'gpt-image-1',
    String prompt = 'Gen an anime image',
    String? imagePath,
    String? size,
    String? existingId,
  }) async {
    if (isGenerating.value) return;

    // Kiểm tra mạng trước khi generate
    if (Get.isRegistered<NetworkService>()) {
      final hasNetwork = await NetworkService.to.checkNetworkForInAppFunction();
      if (!hasNetwork) {
        debugPrint('🌐 No network, blocking generate function');
        return;
      }
    }

    isGenerating.value = true;
    error.value = null;

    // Nếu không có size được truyền vào, dùng size từ selectedAspectRatio
    final finalSize = size ?? sizeForApi;

    // Navigate to loading screen
    Get.toNamed(AppRoutes.imageGenerating);

    List<String>? imageUrls;
    String? uploadedImageUrl; // Lưu URL ảnh mới upload để xóa sau

    // Nếu có selectedImageUrl, dùng URL đó (đã upload rồi)
    // Xác định ảnh cần upload
    String? imagePathToUpload;
    if (selectedImagePath.value.isNotEmpty) {
      imagePathToUpload = selectedImagePath.value;
    } else if (imagePath != null && imagePath.isNotEmpty) {
      imagePathToUpload = imagePath;
    }

    // Nếu có ảnh local, upload lên Firebase Storage
    if (imagePathToUpload != null && imagePathToUpload.isNotEmpty) {
      try {
        final storageService = FirebaseStorageService.shared;
        final uploadedUrl = await storageService.uploadImageAndGetUrl(
          filePath: imagePathToUpload,
          folder: 'input_images',
        );

        if (uploadedUrl != null) {
          imageUrls = [uploadedUrl];
          uploadedImageUrl = uploadedUrl; // Lưu để xóa sau
        } else {
          error.value = AppError.unknown(
            message: 'Không thể upload ảnh lên Firebase Storage',
          );
          isGenerating.value = false;
          Get.back(); // Quay lại màn trước
          return;
        }
      } catch (e) {
        error.value = AppError.unknown(
          message:
              tr('error_uploading_image', namedArgs: {'error': e.toString()}),
        );
        isGenerating.value = false;
        Get.back(); // Quay lại màn trước
        return;
      }
    }

    // // Dùng prompt từ parameter hoặc từ controller

    var finalPrompt = promptText.value.trim();
    final styleName = selectedStyles.isNotEmpty
        ? selectedStyles.map((e) => e.name).first
        : '';
    if (imagePathToUpload == null || imagePathToUpload.isEmpty) {
      finalPrompt = tr('art_prompt_no_image', namedArgs: {
        'user_prompt': promptText.value,
        'style_prompt': styleName
      });
    } else {
      finalPrompt = tr('art_prompt_with_image', namedArgs: {
        'user_prompt': promptText.value,
        'style_prompt': styleName
      });
    }
    AnalyticsService.shared.actionStyleCall(styleName);
    final response = await _imageGenerationUsecase.generateImage(
      model: AppStrings.modelNanoBanana,
      prompt: finalPrompt,
      userPrompt: promptText.value,
      imageUrls: imageUrls != null && imageUrls.isNotEmpty ? imageUrls : null,
      size: finalSize,
      aspectRatio: selectedAspectRatio.value,
      styleId: selectedStyle.value?.id,
      existingId: existingId,
    );

    await response.fold(
      (err) async {
        try {
          error.value = err;
          _latestGenerated.clear();
          isGenerating.value = false;
          if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
            try {
              await _deleteImageFromFirebase(uploadedImageUrl);
            } catch (e) {
              print('Error deleting uploaded image: $e');
            }
          }
        } catch (e) {
          print('Error handling API error: $e');
          isGenerating.value = false;
        }
      },
      (data) async {
        try {
          _latestGenerated.assignAll(data);
          isGenerating.value = false;
          if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
            try {
              await _deleteImageFromFirebase(uploadedImageUrl);
            } catch (e) {
              print('Error deleting uploaded image after success: $e');
            }
          }
          if (selectedImagePath.value.isNotEmpty) {
            _tempInputImagePath = selectedImagePath.value;
          }
          selectedImagePath.value = '';
          _uploadedImageUrl = null;
        } catch (e) {
          print('Error handling API success: $e');
          isGenerating.value = false;
        }
      },
    );
  }

  /// Lấy ảnh input tạm thời (để regenerate)
  String? get tempInputImagePath => _tempInputImagePath;

  /// Clear ảnh input tạm thời
  void clearTempInputImagePath() {
    _tempInputImagePath = null;
  }

  int get caculatedCost {
    if (selectedImagePath.value != '') {
      return AppCoins.coinGenerate + AppCoins.coinWithGenImage;
    }
    return AppCoins.coinGenerate;
  }

  Future<void> loadHistory({
    int offset = 0,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (refresh) {
      history.clear();
    }

    final response = await _imageGenerationUsecase.getGeneratedHistory(
      offset: offset,
      limit: limit,
    );

    response.fold(
      (err) => historyError.value = err,
      (data) {
        historyError.value = null;
        if (refresh) {
          history.assignAll(data);
        } else {
          history.addAll(data);
        }
      },
    );
  }

  Future<void> loadFavorites({
    int offset = 0,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (refresh) {
      favorites.clear();
    }

    final response = await _imageGenerationUsecase.getFavoriteGeneratedImages(
      offset: offset,
      limit: limit,
    );

    response.fold(
      (err) => favoritesError.value = err,
      (data) {
        favoritesError.value = null;
        if (refresh) {
          favorites.assignAll(data);
        } else {
          favorites.addAll(data);
        }
      },
    );
  }

  Future<void> deleteImage(String id) async {
    final response = await _imageGenerationUsecase.deleteGeneratedImage(id);

    response.fold(
      (err) => error.value = err,
      (_) async {
        error.value = null;
        _latestGenerated.removeWhere((element) => element.id == id);
        history.removeWhere((element) => element.id == id);
        favorites.removeWhere((element) => element.id == id);
        await loadHistory(refresh: true);
      },
    );
  }

  void _updateCollectionsWith(GeneratedImage updated) {
    void updateList(RxList<GeneratedImage> list) {
      final index = list.indexWhere((element) => element.id == updated.id);
      if (index != -1) {
        list[index] = updated;
      }
    }

    updateList(_latestGenerated);
    updateList(history);
    updateList(favorites);

    if (updated.isFavorite ?? false) {
      if (!favorites.any((element) => element.id == updated.id)) {
        favorites.insert(0, updated);
      }
    } else {
      favorites.removeWhere((element) => element.id == updated.id);
    }
  }

  Future<void> saveToHistoryAfterDownload({
    required GeneratedImage originalImage,
    required String localPath,
  }) async {
    print('📸 saveToHistoryAfterDownload: Bắt đầu...');
    print('📸 Local path: $localPath');
    print('📸 Prompt: ${originalImage.prompt}');
    print('📸 Aspect ratio: ${originalImage.aspectRatio}');
    print('📸 Style ID: ${originalImage.styleId}');
    print('📸 Original ID: ${originalImage.id}');

    final file = File(localPath);
    final fileExists = await file.exists();
    print('📸 File exists: $fileExists');

    if (!fileExists) {
      error.value = AppError.unknown(message: 'File không tồn tại: $localPath');
      return;
    }

    final response =
        await _imageGenerationUsecase.saveImageToHistoryAfterDownload(
      localPath: localPath,
      prompt: originalImage.prompt,
      userPrompt: originalImage.userPrompt,
      createdAt: originalImage.createdAt ?? DateTime.now(),
      aspectRatio: originalImage.aspectRatio,
      styleId: originalImage.styleId,
      existingId: null,
    );

    await response.fold(
      (err) async {
        error.value = err;
        throw Exception('Failed to save to history: ${err.message}');
      },
      (savedImage) async {
        error.value = null;
        print('✅ Đã lưu vào history thành công!');
        print('✅ Saved image ID: ${savedImage.id}');
        print('✅ Saved image path: ${savedImage.imagePath}');
        _updateCollectionsWith(savedImage);
        await Future.delayed(const Duration(milliseconds: 200));

        await loadHistory(refresh: true);

        final historyIds = await _imageGenerationUsecase.getGeneratedHistory(
            offset: 0, limit: 20);
        historyIds.fold(
          (err) => print('❌ Lỗi khi check history: ${err.message}'),
          (data) => print('📚 History từ storage: ${data.length} items'),
        );
      },
    );
  }

  // Edit mode tracking
  final RxBool isEditMode = false.obs;
  GenerationStep? _previousStepInEditMode;

  //TODO: Logic new screen
  final Rx<GenerationStep> currentStep = GenerationStep.style.obs;

// Store initial values when entering edit mode to detect changes
  String? _initialAspectRatioInEdit;
  int? _initialStyleIdInEdit;
  String? _initialImagePathInEdit;
  final RxBool _hasChangedInEditMode = false.obs;

  // Navigation methods
  void nextStep() {
    // If in edit mode, go back to generate step
    if (isEditMode.value && _previousStepInEditMode != null) {
      currentStep.value = _previousStepInEditMode!;
      _exitEditMode();
      return;
    }
    switch (currentStep.value) {
      case GenerationStep.style:
        if (selectedStyle.value != null) {
          currentStep.value = GenerationStep.image;
        }
        break;
      case GenerationStep.image:
        // Bỏ qua step ratio, chuyển thẳng sang generate
        currentStep.value = GenerationStep.generate;
        break;
      case GenerationStep.generate:
        prepareGeneration();
        // fakeDetailGenerate();
        break;
    }
  }

  void previousStep() {
    switch (currentStep.value) {
      case GenerationStep.image:
        currentStep.value = GenerationStep.style;
        break;
      case GenerationStep.generate:
        // Quay lại từ generate về image (bỏ qua ratio)
        currentStep.value = GenerationStep.image;
        break;
      case GenerationStep.style:
        // Quay lại màn trước
        Get.back();
        break;
    }
  }

  // Check continue step
  bool get canContinueStep {
    // if (isEditMode.value) {
    if (currentStep.value == GenerationStep.image) {
      return true; // Image step always enabled in edit mode
    }
    //   return _hasChangedInEditMode.value;
    // }
    switch (currentStep.value) {
      case GenerationStep.style:
        return selectedStyle.value != null;
      case GenerationStep.image:
        return true; // Có thể skip
      case GenerationStep.generate:
        return canGenerate;
    }
  }

  // Get subtitle
  String get stepSubtitle {
    switch (currentStep.value) {
      case GenerationStep.style:
        return tr('choose_one_style_which_you_like_best');
      case GenerationStep.image:
        return tr('upload_your_image');
      case GenerationStep.generate:
        return tr('describe_what_you_like_to_create');
    }
  }

  Future<void> _simulateFakeUpload() async {
    const duration = Duration(milliseconds: 200);
    const steps = 50;
    final stepDuration =
        Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(stepDuration);
      fakeUploadProgress.value = i / steps;
    }
  }

  // void openAspectRatioSelection() {
  //   _enterEditMode(GenerationStep.ratio);
  //   currentStep.value = GenerationStep.ratio;
  // }

  void openStyleSelection() {
    _enterEditMode(GenerationStep.style);
    currentStep.value = GenerationStep.style;
  }

  void openImageSelection() {
    _enterEditMode(GenerationStep.image);
    currentStep.value = GenerationStep.image;
  }

  void _enterEditMode(GenerationStep targetStep) {
    // Only enter edit mode if coming from generate step
    if (currentStep.value == GenerationStep.generate) {
      isEditMode.value = true;
      _previousStepInEditMode = GenerationStep.generate;
      _hasChangedInEditMode.value = false;

      // Store initial values
      _initialAspectRatioInEdit = selectedAspectRatio.value;
      _initialStyleIdInEdit = selectedStyle.value?.id;
      _initialImagePathInEdit = selectedImagePath.value;
    }
  }

  void _exitEditMode() {
    isEditMode.value = false;
    _previousStepInEditMode = null;
    _hasChangedInEditMode.value = false;
    _initialAspectRatioInEdit = null;
    _initialStyleIdInEdit = null;
    _initialImagePathInEdit = null;
  }

  void _checkEditModeChanges() {
    if (!isEditMode.value) return;

    bool hasChanged = false;

    switch (currentStep.value) {
      case GenerationStep.style:
        hasChanged = _initialStyleIdInEdit != selectedStyle.value?.id;
        break;
      case GenerationStep.image:
        hasChanged = _initialImagePathInEdit != selectedImagePath.value;
        break;
      default:
        break;
    }

    _hasChangedInEditMode.value = hasChanged;
  }
}

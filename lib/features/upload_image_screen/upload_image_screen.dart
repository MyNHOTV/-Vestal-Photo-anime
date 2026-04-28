import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/image_picker_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/utils/export_extensions.dart';
import 'package:flutter_quick_base/core/widgets/app_progress_bar.dart';
import 'package:flutter_quick_base/core/widgets/appbar/custom_transparent_appbar.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/core/widgets/dotted_border_wrapper.dart';
import 'package:flutter_quick_base/core/widgets/loading_widget.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_2_floor_wrapper.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/export_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  State<UploadImageScreen> createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  late ImageGenerationController _genController;

  @override
  void initState() {
    super.initState();
    // Track khi màn hình hiển thị
    AnalyticsService.shared.screenUploadImageShow();
    // Get controller
    _genController = Get.find<ImageGenerationController>();

    // Nhận style từ arguments và set vào controller
    final args = Get.arguments;
    if (args != null && args is ImageStyleModel) {
      _genController.selectStyle(args);
    } else if (args != null && args is Map<String, dynamic>) {
      final style = args['style'] as ImageStyleModel?;
      if (style != null) {
        _genController.selectStyle(style);
      }
    }
  }

  Future<void> _selectImage() async {
    AnalyticsService.shared.actionSelectImageClick();
    try {
      final file =
          await ImagePickerService.shared.pickImageFromGallery(context);
      if (file == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Simulate fake upload progress
      await _simulateFakeUpload();
      _genController.selectedImagePath.value = file.path;
      _genController.isFakeUploading.value = false;
      _genController.fakeUploadProgress.value = 0.0;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    } catch (e) {
      _genController.selectedImagePath.value = '';
      _genController.isFakeUploading.value = false;
      _genController.fakeUploadProgress.value = 0.0;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      // context.showErrorToast(
      //     tr('error_selecting_image', namedArgs: {'error': e.toString()}));
    }
  }

  Future<void> _simulateFakeUpload() async {
    const duration = Duration(milliseconds: 200);
    const steps = 50;
    final stepDuration =
        Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 0; i <= steps; i++) {
      await Future.delayed(stepDuration);
      if (mounted) {
        setState(() {
          _uploadProgress = i / steps;
        });
      }
    }
  }

  void _clearSelectedImage() {
    _genController.clearSelectedImage();
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _genController.clearSelectedImage();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: CustomTransparentAppBar(
          title: tr('add_your_image'),
          nextButtonText: tr('next'),
          onBackTap: () {
            // Clear image khi back từ app bar
            _genController.clearSelectedImage();
            Get.back();
          },
          onNextTap: () {
            // Get selected image path if any
            final imagePath = _genController.selectedImagePath.value;

            // Get selected style - đảm bảo lấy đúng style từ controller
            final genController = Get.find<ImageGenerationController>();
            final style = genController.selectedStyle.value;

            // Nếu không có style trong controller, thử lấy từ arguments
            if (style == null) {
              final args = Get.arguments;
              if (args != null && args is ImageStyleModel) {
                genController.selectStyle(args);
                final styleId = args.id;
                Get.toNamed(
                  AppRoutes.generation,
                  arguments: {
                    'uploadedImagePath': imagePath,
                    'selectedStyleId': styleId,
                  },
                );
                return;
              }
            }

            final styleId = style?.id;

            if (styleId == null) {
              // Nếu không có style, có thể show error hoặc return
              return;
            }

            Get.toNamed(
              AppRoutes.generation,
              arguments: {
                'uploadedImagePath': imagePath,
                'selectedStyleId': styleId,
              },
            );
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spacingM),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Obx(() => _UploadImageBox(
                      imagePath: _genController.selectedImagePath.value,
                      isUploading:
                          _genController.isFakeUploading.value || _isUploading,
                      uploadProgress: _genController.isFakeUploading.value
                          ? _genController.fakeUploadProgress.value
                          : _uploadProgress,
                      onTap: _selectImage,
                      onClear: _clearSelectedImage,
                    )),
              ),
              const SizedBox(height: AppSizes.spacingM),
              // Text mô tả nhỏ bên dưới
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(
                  children: [
                    SvgIcon(name: 'ic_info'),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tr('upload_an_image_for_accurate_results_or_skip_to_continue'),
                        style: kBricolageRegularStyle.copyWith(
                          fontSize: 11,
                          color: AppColors.color727885,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              //ADS HERE
              const SizedBox(height: AppSizes.spacingM),
              // Native Ad Widget
              Spacer(),
              Obx(() {
                // Ẩn native ad nếu mất mạng
                if (Get.isRegistered<NetworkService>()) {
                  if (!NetworkService.to.isConnected.value) {
                    return const SizedBox.shrink();
                  }
                }

                if (!RemoteConfigService.shared.adsEnabled) {
                  return const SizedBox.shrink();
                }
                final bool hasImage =
                    _genController.selectedImagePath.value.isNotEmpty;
                // Nếu đã chọn ảnh thì button màu accent, chưa chọn thì màu xám
                return NativeAd2FloorWrapper(
                  factoryId: 'native_medium_image_top_2',
                  key: Key(
                    hasImage
                        ? 'native_upload_image_selected'
                        : 'native_upload_image',
                  ),
                  primaryUniqueKey: 'native_upload_image',
                  fallbackUniqueKey: 'native_upload_image',
                  enable2Floor: false,
                  buttonColor: hasImage
                      ? DynamicThemeService.shared.getActiveColorADS()
                      : AppColors.colorA9A9A9,
                  adBackgroundColor:
                      DynamicThemeService.shared.getActiveColorADS(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadImageBox extends StatefulWidget {
  const _UploadImageBox({
    required this.imagePath,
    required this.isUploading,
    required this.uploadProgress,
    required this.onTap,
    this.onClear,
  });

  final String imagePath;
  final bool isUploading;
  final double uploadProgress;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  State<_UploadImageBox> createState() => _UploadImageBoxState();
}

class _UploadImageBoxState extends State<_UploadImageBox> {
  bool _hasLoggedAnalytics = false;
  String? _previousImagePath;
  @override
  void didUpdateWidget(_UploadImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only log analytics when imagePath actually changes
    if (widget.imagePath != oldWidget.imagePath) {
      _hasLoggedAnalytics = false;
      _previousImagePath = oldWidget.imagePath;
    }
  }

  void _logAnalytics() {
    if (_hasLoggedAnalytics) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.imagePath.isNotEmpty) {
        AnalyticsService.shared.actionUploadImageBackWithImage();
      } else {
        AnalyticsService.shared.actionUploadImageBackWithoutImage();
      }
      _hasLoggedAnalytics = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logAnalytics();
    final borderColor = AppColors.color400FA7;
    final hasImage = widget.imagePath.isNotEmpty && !widget.isUploading;

    return GestureDetector(
      onTap: widget.isUploading ? null : (hasImage ? null : widget.onTap),
      child: Container(
        height: MediaQuery.of(context).size.height / 2.5,
        width: double.infinity,
        decoration: hasImage
            ? null
            : const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icons/img_pick_image.png'),
                  fit: BoxFit.fill,
                ),
              ),
        child: DottedBorderWrapper(
          // padding: EdgeInsets.symmetric(horizontal: 24.0),
          borderColor: borderColor,
          borderRadius: 25,
          child: Stack(
            children: [
              // Hiển thị ảnh đã chọn
              if (hasImage)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: LoadingSpinKitFading(
                      imageUrl: widget.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),

              // Hiển thị placeholder khi chưa có ảnh
              if (!hasImage && !widget.isUploading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSizes.spacingL),
                      // Icon upload
                      Container(
                        padding: const EdgeInsets.all(14),
                        child: const SvgIcon(name: 'ic_upload_image'),
                      ),
                      Text(
                        tr('upload_image'),
                        style: kBricolageBoldStyle.copyWith(
                          fontSize: 18,
                          color: borderColor,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                    ],
                  ),
                ),

              // Hiển thị progress khi đang upload
              if (widget.isUploading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: AppProgressBar(
                          progress: widget.uploadProgress,
                          height: 8.0,
                          backgroundColor: Colors.white,
                          gradient: const LinearGradient(colors: [
                            AppColors.color6657F0,
                            AppColors.color6657F0,
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

              // Nút xóa ảnh khi đã có ảnh
              if (hasImage && widget.onClear != null)
                Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        widget.onClear!();
                      },
                      child: SvgIcon(name: 'ic_close_image'),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

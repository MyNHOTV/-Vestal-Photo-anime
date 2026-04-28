import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/extensions/context_extensions.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/image_picker_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/export_widgets.dart';
import 'package:flutter_quick_base/core/widgets/grid_background.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import '../../../../core/constants/export_constants.dart';

class EditImageScreen extends StatefulWidget {
  const EditImageScreen({super.key});

  @override
  State<EditImageScreen> createState() => _EditImageScreenState();
}

class _EditImageScreenState extends State<EditImageScreen> {
  final ImageGenerationController controller =
      Get.find<ImageGenerationController>();
  String _initialImagePath = '';
  String _tempImagePath =
      ''; // Temporary path, only update controller when confirm
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initialImagePath = controller.selectedImagePath.value;
    _tempImagePath = _initialImagePath;
  }

  @override
  void dispose() {
    if (!_isConfirmed && _tempImagePath != _initialImagePath) {
      if (_initialImagePath.isEmpty) {
        controller.selectedImagePath.value = '';
      } else {
        controller.selectedImagePath.value = _initialImagePath;
      }
    }
    super.dispose();
  }

  Future<void> _selectImage(BuildContext context) async {
    try {
      final file = await ImagePickerService.shared.pickImageFromCamera(context);
      if (file == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Simulate fake upload progress
      await _simulateFakeUpload();

      setState(() {
        _tempImagePath = file.path;
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _tempImagePath = '';
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      context.showErrorToast(
          tr('error_selecting_image', namedArgs: {'error': e.toString()}));
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
    setState(() {
      _tempImagePath = '';
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _tempImagePath.isNotEmpty;
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: AppColors.colorBlack,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(
              child: SizedBox.shrink(),
            ),
          ),
          AbsorbPointer(
            absorbing: _isUploading,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SimpleAppBar(
                    title: tr('edit_your_image'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSizes.spacingM,
                        right: AppSizes.spacingM,
                        bottom: AppSizes.spacingS),
                    child: Text(
                      tr('upload_your_image'),
                      style: kTextHeadingStyle,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height / 6,
                        left: AppSizes.spacingM,
                        right: AppSizes.spacingM,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!hasImage && !_isUploading)
                            _buildUploadPlaceholder(context)
                          else if (_isUploading)
                            _buildUploadingState(context)
                          else
                            _buildUploadedImage(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AbsorbPointer(
                  absorbing: _isUploading,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 20.0),
                        child: AppPrimaryButton(
                          title: tr('confirm'),
                          state: StateButton.active,
                          onTap: () {
                            _isConfirmed = true;
                            if (_tempImagePath != _initialImagePath) {
                              controller.selectedImagePath.value =
                                  _tempImagePath;
                            }
                            Get.back();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  if (!RemoteConfigService.shared.bannerChangeImageEnabled) {
                    return const SizedBox.shrink();
                  }
                  return const CollapsibleBannerAdWidget(
                    placement: 'banner_change_image',
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState(BuildContext context) {
    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        radius: Radius.circular(16),
        dashPattern: [8, 4],
        strokeWidth: 2,
        color: AppColors.surface,
        padding: EdgeInsets.all(16),
      ),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height / 1.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(
                name: "ic_generate_image_pick",
                color: DynamicThemeService.shared.getPrimaryAccentColor(),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                tr('upload_image_for_accurate_results_or_skip'),
                style: kTextRegularStyle.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingS),
              AppProgressBar(
                progress: _uploadProgress,
                height: 8.0,
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context) {
    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        radius: Radius.circular(16),
        dashPattern: [8, 4],
        strokeWidth: 2,
        color: AppColors.surface,
        padding: EdgeInsets.all(16),
      ),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height / 1.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(
                name: "ic_generate_image_pick",
                color: DynamicThemeService.shared.getPrimaryAccentColor(),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                tr('upload_image_for_accurate_results_or_skip'),
                style: kTextRegularStyle.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingS),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 8),
                child: AppPrimaryButton(
                  title: tr('open_gallery'),
                  onTap: () => _selectImage(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedImage(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height / 1.7,
      child: Stack(
        children: [
          LoadingSpinKitFading(
            imageUrl: _tempImagePath,
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 1.7,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ArtItemWidget(
              badgeHeight: 44,
              onTap: _clearSelectedImage,
              icon: const SvgIcon(name: "ic_delete"),
            ),
          ),
        ],
      ),
    );
  }
}

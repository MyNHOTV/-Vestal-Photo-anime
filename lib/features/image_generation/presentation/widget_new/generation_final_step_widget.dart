import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:flutter_quick_base/features/image_generation/data/datasources/aspect_ratio_data_source.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/widgets/export_widgets.dart';

class GenerationFinalStepWidget extends StatefulWidget {
  final ImageGenerationController controller;

  const GenerationFinalStepWidget({
    super.key,
    required this.controller,
  });

  @override
  State<GenerationFinalStepWidget> createState() =>
      _GenerationFinalStepWidgetState();
}

class _GenerationFinalStepWidgetState extends State<GenerationFinalStepWidget> {
  late TextEditingController _promptController;
  late ScrollController _scrollController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializePromptController();
  }

  void _initializePromptController() {
    _promptController = widget.controller.promptController;

    try {
      _promptController.removeListener(_onPromptChanged);
    } catch (e) {}

    try {
      _promptController.addListener(_onPromptChanged);
    } catch (e) {
      // Nếu controller đã bị dispose, tạo lại controller mới
      widget.controller.promptController = TextEditingController();
      _promptController = widget.controller.promptController;
      _promptController.addListener(_onPromptChanged);
    }
  }

  void _onPromptChanged() {
    if (_isDisposed || !mounted) return;

    try {
      final text = _promptController.text;
      final textTrimmed = text.trim();
      // Không cần validate nữa, luôn cho phép
      widget.controller.updateValidPrompt(true);
      widget.controller.updatePromptText(textTrimmed);
    } catch (e) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _promptController.removeListener(_onPromptChanged);
    } catch (e) {}
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPromptSection(),
              if (widget.controller.selectedImagePath.value.isNotEmpty)
                _buildUploadImageSection(
                  onTapEdit: () {
                    AnalyticsService.shared.actionChangeImage();
                    Get.toNamed(AppRoutes.editImage);
                  },
                )
              else
                _buildUploadNoImageSection(
                  onTapEdit: () {
                    AnalyticsService.shared.actionChangeImage();
                    Get.toNamed(AppRoutes.editImage);
                  },
                ),
              const SizedBox(height: AppSizes.spacingM),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Style & Aspect Ratio Section
                    Text(
                      tr('style'),
                      style: kTextHeadingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingS),

                    Row(
                      children: [
                        _buildStyleCard(
                            styleId: widget.controller.selectedStyle.value?.id,
                            onTapEdit: () {
                              AnalyticsService.shared.actionChangeStyle();
                              if (mounted) {
                                Get.toNamed(AppRoutes.editStyle);
                              }
                            }),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 4)
            ],
          ),
        ));
  }

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.color29171E,
            border: Border.all(color: AppColors.color595959, width: 1),
          ),
          child: RawScrollbar(
            // controller: _scrollController,
            radius: const Radius.circular(16),
            trackVisibility: true,
            // thumbVisibility: true,
            child: TextField(
              controller: _promptController,
              maxLines: 3, // Giảm từ 5 xuống 3
              minLines: 3, // Thêm minLines để cố định 3 dòng
              // maxLength: RemoteConfigService.shared.maxLengthGenerate,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                  hintText: tr('enter_prompt_optional'), // Placeholder mới
                  counterStyle: kTextMediumtStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: AppColors.colorA9A9A9),
                  hintStyle:
                      kTextDisableStyle.copyWith(fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.color29171E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.color29171E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  fillColor: AppColors.color29171E,
                  contentPadding:
                      const EdgeInsets.only(left: 16, right: 8, bottom: 16)),
              cursorColor: AppColors.background,
            ),
          ),
        ),

        // const SizedBox(height: AppSizes.spacingM),
      ],
    );
  }

  Widget _buildUploadImageSection({required Function()? onTapEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('upload_image'),
            style: kTextHeadingStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSizes.spacingM),
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(Get.context!).size.height / 5,
            child: Stack(
              children: [
                LoadingSpinKitFading(
                  imageUrl: widget.controller.selectedImagePath.value,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ArtItemWidget(
                    badgeHeight: 24,
                    icon: const SvgIcon(name: 'ic_edit'),
                    backgroundColor:
                        DynamicThemeService.shared.getPrimaryAccentColor(),
                    onTap: () async {
                      // Check network trước khi navigate
                      if (Get.isRegistered<NetworkService>()) {
                        final hasNetwork = await NetworkService.to
                            .checkNetworkForInAppFunction();
                        if (!hasNetwork) {
                          debugPrint(
                              '🌐 No network, blocking generation final step edit image');
                          return;
                        }
                        // Có mạng, tiếp tục navigate
                        if (onTapEdit != null) {
                          onTapEdit();
                        }
                      } else {
                        // Fallback nếu NetworkService chưa sẵn sàng
                        if (onTapEdit != null) {
                          onTapEdit();
                        }
                      }
                    },
                  ),
                ),
                // Positioned(
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadNoImageSection({required Function()? onTapEdit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('upload_image'),
            style: kTextHeadingStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Container(
            width: double.infinity,
            height: MediaQuery.of(Get.context!).size.height / 5,
            decoration: BoxDecoration(
                color: AppColors.color29171E,
                borderRadius: BorderRadius.circular(16.0)),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SvgIcon(name: 'ic_no_image'),
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        tr('no_images'),
                        style: kTextRegularStyle.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ArtItemWidget(
                    badgeHeight: 24,
                    icon: const SvgIcon(name: 'ic_edit'),
                    backgroundColor:
                        DynamicThemeService.shared.getPrimaryAccentColor(),
                    onTap: () async {
                      // Check network trước khi navigate
                      if (Get.isRegistered<NetworkService>()) {
                        final hasNetwork = await NetworkService.to
                            .checkNetworkForInAppFunction();
                        if (!hasNetwork) {
                          debugPrint(
                              '🌐 No network, blocking generation final step edit image');
                          return;
                        }
                        // Có mạng, tiếp tục navigate
                        if (onTapEdit != null) {
                          onTapEdit();
                        }
                      } else {
                        // Fallback nếu NetworkService chưa sẵn sàng
                        if (onTapEdit != null) {
                          onTapEdit();
                        }
                      }
                    },
                  ),
                ),
                // Positioned(
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(
      {required int? styleId, required Function() onTapEdit}) {
    final styles = HomeDataSource.getImageStyles();
    final style = styles.firstWhere(
      (s) => s.id == styleId,
      orElse: () => styles.first,
    );

    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                    border: Border.all(
                      color: AppColors.color29171E,
                      width: 6,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    // Ưu tiên imageUrl (từ API) trước, nếu không có thì dùng imageAsset (từ assets)
                    child: style.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: style.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildStylePlaceholder(),
                            errorWidget: (context, url, error) =>
                                // Nếu load imageUrl lỗi, fallback về imageAsset
                                style.imageAsset != null
                                    ? Image.asset(
                                        style.imageAsset!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildStylePlaceholder(),
                                      )
                                    : _buildStylePlaceholder(),
                            maxWidthDiskCache: 2048,
                            maxHeightDiskCache: 2048,
                          )
                        : style.imageAsset != null
                            ? Image.asset(
                                style.imageAsset!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildStylePlaceholder(),
                              )
                            : _buildStylePlaceholder(),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: ArtItemWidget(
                    badgeHeight: 24,
                    icon: const SvgIcon(name: 'ic_edit'),
                    backgroundColor:
                        DynamicThemeService.shared.getPrimaryAccentColor(),
                    onTap: () async {
                      final hasNet = await NetworkService.to
                          .checkNetworkForInAppFunction();
                      if (!hasNet) return;
                      onTapEdit();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            style.name,
            style: kTextSmallStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStylePlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildAspectRatioCard(
      {required String aspectRatio, required Function() onTapEdit}) {
    final aspectRatios = AspectRatioDataSource.getAspectRatios();
    final selectedRatio = aspectRatios.firstWhere(
      (ratio) => ratio.aspectRatio == aspectRatio,
      orElse: () => aspectRatios.first,
    );

    return SizedBox(
      height: 120,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.color29171E,
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                  child: Center(
                    child: Container(
                      width: selectedRatio.iconWidth + 36,
                      height: selectedRatio.iconHeight + 36,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: ArtItemWidget(
                    badgeHeight: 24,
                    icon: const SvgIcon(name: 'ic_edit'),
                    backgroundColor:
                        DynamicThemeService.shared.getPrimaryAccentColor(),
                    onTap: () async {
                      // Check network trước khi navigate
                      if (Get.isRegistered<NetworkService>()) {
                        final hasNetwork = await NetworkService.to
                            .checkNetworkForInAppFunction();
                        if (!hasNetwork) {
                          debugPrint(
                              '🌐 No network, blocking generation final step edit aspect ratio');
                          return;
                        }
                        // Có mạng, tiếp tục navigate
                        onTapEdit();
                      } else {
                        // Fallback nếu NetworkService chưa sẵn sàng
                        onTapEdit();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            tr(selectedRatio.i18nKey),
            style: kTextSmallStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

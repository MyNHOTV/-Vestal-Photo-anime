import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/image_picker_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/appbar/custom_transparent_appbar.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/art_item_widget.dart';
import 'package:flutter_quick_base/core/widgets/loading_widget.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_group_model.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';

class GenerationScreen extends StatefulWidget {
  final String? uploadedImagePath;
  final int? selectedStyleId;

  const GenerationScreen({
    super.key,
    this.uploadedImagePath,
    this.selectedStyleId,
  });

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  late ImageGenerationController _controller;
  late TextEditingController _promptController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ImageGenerationController>();
    _promptController = _controller.promptController;

    AnalyticsService.shared.screenSummaryShow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set uploaded image if provided
      if (widget.uploadedImagePath != null) {
        _controller.selectedImagePath.value = widget.uploadedImagePath!;
      }

      // Set selected style if provided
      if (widget.selectedStyleId != null &&
          _controller.selectedStyle.value == null) {
        final styles = HomeDataSource.getImageStyles();
        final style = styles.firstWhere(
          (s) => s.id == widget.selectedStyleId,
          orElse: () => styles.first,
        );
        _controller.selectStyle(style);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:
                        AssetImage('assets/icons/image_generation_screen.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomTransparentAppBar(
            title: tr('generation'),
            showNext: false,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          tr('your_combination'),
                          style: kBricolageBoldStyle.copyWith(
                            fontSize: 16,
                            color: AppColors.color121212,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingM),

                        // Two images side by side
                        _buildImageCombination(),
                        const SizedBox(height: AppSizes.spacingL),

                        // Expandable text input
                        _buildExpandablePromptInput(),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons and ad
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCombination() {
    return Row(
      children: [
        // Left image - Style
        Expanded(
          child: _buildStyleImage(),
        ),
        const SizedBox(width: AppSizes.spacingXS),
        // Right image - Uploaded image
        Expanded(
          child: _buildUploadedImage(),
        ),
      ],
    );
  }

  Widget _buildStyleImage() {
    return Obx(() {
      final style = _controller.selectedStyle.value;
      if (style == null) {
        return _buildPlaceholderImage(
          icon: Icons.style,
          onTap: () => _navigateToStyleSelection(),
        );
      }

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              border: Border.all(
                color: AppColors.colorD7DAE1,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: style.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: style.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildImagePlaceholder(),
                        errorWidget: (context, url, error) =>
                            style.imageAsset != null
                                ? Image.asset(
                                    style.imageAsset!,
                                    fit: BoxFit.cover,
                                  )
                                : _buildImagePlaceholder(),
                      )
                    : style.imageAsset != null
                        ? Image.asset(
                            style.imageAsset!,
                            fit: BoxFit.cover,
                          )
                        : _buildImagePlaceholder(),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ArtItemWidget(
              border: Border.all(
                color: AppColors.colorD7DAE1,
                width: 1,
              ),
              badgeHeight: 27,
              icon: const SvgIcon(
                name: 'ic_refresh',
                color: AppColors.colorBlack,
              ),
              backgroundColor: AppColors.surface,
              onTap: () => _navigateToStyleSelection(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUploadedImage() {
    return Obx(() {
      final imagePath = _controller.selectedImagePath.value;
      if (imagePath.isEmpty) {
        return _buildPlaceholderImage(
          icon: Icons.image,
          onTap: () => _navigateToImageSelection(),
        );
      }

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppColors.colorD7DAE1,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: LoadingSpinKitFading(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  imageUrl: imagePath,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ArtItemWidget(
              border: Border.all(
                color: AppColors.colorD7DAE1,
                width: 1,
              ),
              badgeHeight: 27,
              icon: const SvgIcon(
                name: 'ic_refresh',
                color: AppColors.colorBlack,
              ),
              backgroundColor: AppColors.surface,
              onTap: () => _navigateToImageSelection(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPlaceholderImage({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: AppColors.colorD7DAE1,
                  width: 1,
                ),
              ),
              child: const ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Center(
                    child: SvgIcon(name: 'ic_no_image'),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: ArtItemWidget(
                border: Border.all(
                  color: AppColors.colorD7DAE1,
                  width: 1,
                ),
                badgeHeight: 27,
                icon: const SvgIcon(
                  name: 'ic_refresh',
                  color: AppColors.colorBlack,
                ),
                backgroundColor: AppColors.surface,
                onTap: () => _navigateToImageSelection(),
              ),
            ),
          ],
        ));
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.color29171E,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildExpandablePromptInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        // border: Border.all(color: AppColors.color595959, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and expand button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const SvgIcon(
                    name: 'ic_my_creation_active',
                    color: AppColors.color7259F1,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      tr('describe_the_result_you_want'),
                      style: kBricolageRegularStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.color121212,
                      ),
                    ),
                  ),
                  _isExpanded
                      ? const SvgIcon(name: 'ic_top')
                      : const SvgIcon(name: 'ic_bottom'),
                ],
              ),
            ),
          ),

          // Text input area (shown when expanded)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: TextField(
                controller: _promptController,
                maxLines: 4,
                minLines: 3,
                style: kBricolageRegularStyle.copyWith(
                    fontSize: 12, color: AppColors.color121212),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: tr('hint_style_prompt'),
                  hintStyle: kBricolageRegularStyle.copyWith(
                      fontSize: 12, color: AppColors.color727885),
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.colorF4F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.colorF4F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  fillColor: AppColors.colorF4F5F5,
                  contentPadding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 12, top: 12),
                ),
                cursorColor: AppColors.color121212,
                onChanged: (text) {
                  _controller.updatePromptText(text.trim());
                },
              ),
            ),

          // Footer hint
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Row(
                children: [
                  const SvgIcon(name: 'ic_info'),
                  const SizedBox(width: 4),
                  Text(
                    tr('prompt_is_not_required'),
                    style: kBricolageRegularStyle.copyWith(
                      fontSize: 11,
                      color: AppColors.color727885,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Buttons
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingM,
            vertical: AppSizes.spacingM,
          ),
          child: Row(
            children: [
              // Generate button
              Expanded(
                child: AppPrimaryButton(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.colorAE8CF5,
                  title: tr('generate'),
                  state: StateButton.active,
                  onTap: () {
                    AnalyticsService.shared.actionGenerateClick();
                    _controller.prepareGeneration();
                    // _controller.fakeDetailGenerate();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Quick Generate button
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppPrimaryButton(
                      borderRadius: BorderRadius.circular(12),
                      title: tr('quick_generate'),
                      state: StateButton.active,
                      onTap: () {
                        AnalyticsService.shared.actionQuickGenerateClick();
                        _controller.prepareImmediateGeneration();
                      },
                    ),
                    Positioned(
                      top: -10,
                      right: 5,
                      child: Container(
                        height: 28,
                        width: 28,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            // color: Colors.yellow,
                            borderRadius: BorderRadius.circular(4),
                            image: const DecorationImage(
                                image: AssetImage(
                                    'assets/icons/img_watch_ads.png'))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToStyleSelection() async {
    AnalyticsService.shared.actionChangeStyleClick();
    final hasNetwork = await NetworkService.to.checkNetworkForInAppFunction();
    if (!hasNetwork) return;

    // Lấy style hiện tại và tìm group của nó
    final currentStyle = _controller.selectedStyle.value;
    if (currentStyle == null) {
      Get.toNamed(AppRoutes.listStyle, arguments: {
        'isView': false,
        'fromGeneration': true,
      });
      return;
    }

    // Tìm group chứa style hiện tại
    final groups = HomeDataSource.getImageStyleGroups();
    ImageStyleGroupModel? currentGroup;
    for (var group in groups) {
      if (group.styles.any((s) => s.id == currentStyle.id)) {
        currentGroup = group;
        break;
      }
    }

    // Nếu không tìm thấy group, dùng tất cả styles
    final stylesToShow = currentGroup?.styles ?? _controller.imageStyles.value;
    final groupName = currentGroup?.name ?? tr('image_style');

    Get.toNamed(AppRoutes.listStyle, arguments: {
      'isView': false,
      'fromGeneration': true,
      'styles': stylesToShow,
      'groupName': groupName,
      'initialSelectedIndex':
          stylesToShow.indexWhere((s) => s.id == currentStyle.id),
    });
  }

  Future<void> _navigateToImageSelection() async {
    AnalyticsService.shared.actionChangeImageClick();
    final hasNetwork = await NetworkService.to.checkNetworkForInAppFunction();
    if (!hasNetwork) return;

    // Pick ảnh từ library
    try {
      final file =
          await ImagePickerService.shared.pickImageFromGallery(context);
      if (file == null) {
        AnalyticsService.shared.actionUploadImageBackWithoutImage();
        return;
      }
      _controller.selectedImagePath.value = file.path;

      AnalyticsService.shared.actionUploadImageBackWithImage();
    } catch (e) {}
  }
}

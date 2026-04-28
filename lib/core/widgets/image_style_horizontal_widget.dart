import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/widgets/text_more_widget.dart';
import '../../features/home/data/model/image_style_model.dart';

class ImageStyleHorizontalWidget extends StatefulWidget {
  const ImageStyleHorizontalWidget({
    super.key,
    required this.styles,
    this.selectedStyleId,
    this.onStyleSelected,
    this.onMoreStyleTap,
  });

  final List<ImageStyleModel> styles;
  final int? selectedStyleId;
  final Function(ImageStyleModel)? onStyleSelected;
  final VoidCallback? onMoreStyleTap;

  @override
  State<ImageStyleHorizontalWidget> createState() =>
      _ImageStyleHorizontalWidgetState();
}

class _ImageStyleHorizontalWidgetState
    extends State<ImageStyleHorizontalWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll đến item được chọn sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void didUpdateWidget(ImageStyleHorizontalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll đến item mới khi selectedStyleId thay đổi
    if (oldWidget.selectedStyleId != widget.selectedStyleId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (widget.selectedStyleId == null || !_scrollController.hasClients) {
      return;
    }

    // Tìm index của item được chọn
    final selectedIndex = widget.styles.indexWhere(
      (style) => style.id == widget.selectedStyleId,
    );

    if (selectedIndex >= 0) {
      // Tính toán vị trí scroll
      // Mỗi item có width = 100 + margin left (12) + margin right (12) = 124
      const itemWidth = 100.0;
      const itemMargin = AppSizes.spacingS; // 12
      const totalItemWidth = itemWidth + (itemMargin * 2);

      // Scroll đến vị trí item, căn giữa màn hình
      final screenWidth = MediaQuery.of(context).size.width;
      final scrollPosition = (selectedIndex * totalItemWidth) -
          (screenWidth / 2) +
          (totalItemWidth / 2);

      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.spacingM),
          child: TextMoreWidget(
            onMoreStyleTap: widget.onMoreStyleTap,
          ),
        ),
        const SizedBox(height: AppSizes.spacingXS),
        SizedBox(
          height: 120,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingS),
            itemCount: widget.styles.length,
            itemBuilder: (context, index) {
              final style = widget.styles[index];
              final isSelected = style.id == widget.selectedStyleId;
              return _buildStyleCard(style, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCard(ImageStyleModel style, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onStyleSelected?.call(style),
      child: Container(
        width: 100,
        height: 84,
        margin: const EdgeInsets.only(
            right: AppSizes.spacingS, left: AppSizes.spacingS),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  border: isSelected
                      ? Border.all(
                          width: 2,
                          color: Colors.transparent,
                        )
                      : null,
                  // Gradient border khi selected
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: DynamicThemeService.shared
                              .getSecondaryButtonGradientColors(),
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                    border: Border.all(
                      color: AppColors.color29171E,
                      width: 6,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    child: style.imageAsset != null
                        ? Image.asset(
                            style.imageAsset!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : style.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: style.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildPlaceholder(),
                                errorWidget: (context, url, error) =>
                                    _buildPlaceholder(),
                                maxWidthDiskCache: 2048,
                                maxHeightDiskCache: 2048,
                              )
                            : _buildPlaceholder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingXS),
            Text(
              style.name,
              style: kTextRegularStyle.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}

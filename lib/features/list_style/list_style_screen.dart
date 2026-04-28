import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/appbar/custom_transparent_appbar.dart';
import 'package:flutter_quick_base/core/widgets/style_selection_dialog.dart';
import 'package:flutter_quick_base/core/widgets/trending_style_grid_widget.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_group_model.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:flutter_quick_base/features/home/presentation/controller/home_controller.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';

class ListStyleScreen extends StatefulWidget {
  const ListStyleScreen({
    super.key,
    this.isView = true,
    this.onStyleSelected,
    this.styles,
    this.initialSelectedIndex,
    this.groupName,
    this.fromGeneration = false,
  });

  final bool? isView;
  final Function(ImageStyleModel)? onStyleSelected;
  final List<ImageStyleModel>? styles;
  final int? initialSelectedIndex;
  final String? groupName;
  final bool fromGeneration;

  @override
  State<ListStyleScreen> createState() => _ListStyleScreenState();
}

class _ListStyleScreenState extends State<ListStyleScreen> {
  int? _selectedStyleId;

  @override
  void initState() {
    super.initState();
    if (widget.isView != true && widget.initialSelectedIndex != null) {
      final index = widget.initialSelectedIndex!;
      if (index >= 0 && index < (widget.styles ?? []).length) {
        _selectedStyleId = (widget.styles ?? [])[index].id;
      }
    }
    // Nếu từ GenerationScreen, lấy style hiện tại từ controller
    if (widget.fromGeneration) {
      final genController = Get.find<ImageGenerationController>();
      final currentStyle = genController.selectedStyle.value;
      if (currentStyle != null) {
        _selectedStyleId = currentStyle.id;
      }
    }
    AnalyticsService.shared.screenChooseStyleShow();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.fromGeneration && widget.isView == false;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomTransparentAppBar(
        colors: AppColors.surface,
        title: widget.groupName ?? tr('image_style'),
        showNext: widget.isView != true, // Hiện dấu tích khi isView = false
        nextIcon: widget.isView != true ? 'ic_check' : null,
        backIcon: isEditMode ? 'ic_close' : null,
        onNextTap: widget.isView != true ? _handleAccept : null,
        onBackTap: () async {
          final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
          if (!hasNet) return;
          if (mounted) Get.back();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
            bottom: AppSizes.bottomNavBarHeight + AppSizes.buttonHeightS,
            top: AppSizes.spacingM),
        child: _buildGridView(),
      ),
    );
  }

  // Grid view cho cả 2 case - đều dùng 2 cột
  Widget _buildGridView() {
    if (widget.fromGeneration) {
      // Case từ GenerationScreen - có dấu tích (isView = false)
      final genController = Get.find<ImageGenerationController>();
      final currentStyle = genController.selectedStyle.value;
      List<ImageStyleModel> stylesToShow;
      // Nếu có widget.styles được truyền vào, ưu tiên dùng nó (đã là group rồi)
      if (widget.styles != null && widget.styles!.isNotEmpty) {
        stylesToShow = widget.styles!;
      } else if (currentStyle != null) {
        // Tìm group chứa style hiện tại
        final groups = HomeDataSource.getImageStyleGroups();
        ImageStyleGroupModel? currentGroup;

        for (var group in groups) {
          if (group.styles.any((s) => s.id == currentStyle.id)) {
            currentGroup = group;
            break;
          }
        }

        // Lấy styles từ group, nếu không tìm thấy thì fallback về allStyles
        if (currentGroup != null && currentGroup.styles.isNotEmpty) {
          stylesToShow = currentGroup.styles;
        } else {
          // Fallback về allStyles nếu không tìm thấy group
          stylesToShow = genController.imageStyles.value;
        }
      } else {
        // Nếu không có style hiện tại, dùng allStyles
        stylesToShow = genController.imageStyles.value;
      }
      return TrendingStyleGridWidget(
        styles: stylesToShow, // Ưu tiên widget.styles nếu có
        selectedStyleId: widget.isView == false ? _selectedStyleId : null,
        crossAxisCount: 2, // Grid 2 cột
        onStyleSelected: widget.isView == false
            ? (style) {
                // Chỉ update selected khi isView = false
                setState(() {
                  _selectedStyleId = style.id;
                });
              }
            : (style) {
                // Nếu isView = true thì navigate ngay (nhưng case này không nên xảy ra từ GenerationScreen)
                AnalyticsService.shared.styleClick(style.name);
                genController.selectStyle(style);
                Get.back();
              },
        maxItems: stylesToShow.length,
      );
    } else {
      // Case từ Home - dùng styles từ group (widget.styles)
      return TrendingStyleGridWidget(
        styles: widget.styles ?? [], // Lấy từ group đã truyền vào
        crossAxisCount: 2, // Grid 2 cột
        onStyleSelected: (style) {
          AnalyticsService.shared.styleClick(style.name);

          // Show dialog giống như ở màn home
          StyleSelectionDialog.show(
            context: context,
            style: style,
            onCancel: () {
              Navigator.of(context).pop();
            },
            onConfirm: () {
              Navigator.of(context).pop();
              // Set selected style và navigate to upload image
              final homeController = Get.find<HomeController>();
              homeController.selectedStyle.value = style;
              final genController = Get.find<ImageGenerationController>();
              genController.setPreviousRoute('listStyle');
              genController.setPreviousListStyleData(
                  styles: widget.styles ?? [],
                  groupName: widget.groupName ?? tr('image_style'));
              Get.toNamed(
                AppRoutes.uploadImage,
                arguments: style,
              );
            },
          );
        },
        maxItems: (widget.styles ?? []).length,
      );
    }
  }

  String _getSelectedStyleName() {
    if (_selectedStyleId == null) return widget.groupName ?? tr('image_style');

    final selectedStyle = (widget.styles ?? []).firstWhere(
      (style) => style.id == _selectedStyleId,
      orElse: () {
        if (widget.fromGeneration) {
          final genController = Get.find<ImageGenerationController>();
          final allStyles = genController.imageStyles.value;
          return allStyles.firstWhere(
            (style) => style.id == _selectedStyleId,
            orElse: () => allStyles.first,
          );
        }
        return (widget.styles ?? []).first;
      },
    );

    return selectedStyle.name;
  }

  // Handle accept button (dấu tích)
  void _handleAccept() {
    if (_selectedStyleId == null) return; // Không làm gì nếu chưa chọn

    final selectedStyle = (widget.styles ?? []).firstWhere(
      (style) => style.id == _selectedStyleId,
      orElse: () {
        // Nếu không tìm thấy trong widget.styles, tìm trong controller
        if (widget.fromGeneration) {
          final genController = Get.find<ImageGenerationController>();
          final allStyles = genController.imageStyles.value;
          return allStyles.firstWhere(
            (style) => style.id == _selectedStyleId,
            orElse: () => allStyles.first,
          );
        }
        return (widget.styles ?? []).first;
      },
    );

    if (widget.onStyleSelected != null) {
      widget.onStyleSelected!(selectedStyle);
      Navigator.of(context).pop(selectedStyle);
    } else if (widget.fromGeneration) {
      // Update style trong controller
      final genController = Get.find<ImageGenerationController>();
      genController.selectStyle(selectedStyle);
      Navigator.of(context).pop(selectedStyle);
    } else {
      Navigator.of(context).pop(selectedStyle);
    }
  }
}

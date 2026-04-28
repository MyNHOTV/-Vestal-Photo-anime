import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/cached_image_widget.dart';
import 'package:flutter_quick_base/core/widgets/grid_background.dart';
import 'package:flutter_quick_base/core/widgets/simple_app_bar.dart';
import 'package:flutter_quick_base/features/image_generation/domain/entities/generated_image.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';
import '../../../../features/home/presentation/widget/home_library_widget.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ImageGenerationController>();

    // Load history khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadHistory(refresh: true);
      AnalyticsService.shared.screenHistoryShow();
    });

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.colorBlack,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(
              child: SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SimpleAppBar(
                  title: tr('history'),
                ),
                Expanded(
                  child: Obx(() {
                    final history = controller.history;
                    if (history.isEmpty) {
                      return _buildEmptyState();
                    }

                    final uiBlocks = _createUIBlocks(history);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: AppSizes.spacingM,
                        right: AppSizes.spacingM,
                        top: AppSizes.spacingS,
                        bottom: 70, // Add padding for banner
                      ),
                      child: Column(
                        children: uiBlocks.map((block) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.spacingS,
                            ),
                            child: _buildUIBlock(block),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (!RemoteConfigService.shared.bannerHistoryEnabled) {
          return const SizedBox.shrink();
        }
        return const CollapsibleBannerAdWidget(
          placement: 'banner_history',
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SvgIcon(name: "ic_empty_library"),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            tr('no_images'),
            style:
                kTextRegularStyle.copyWith(color: AppColors.disableColorText),
          ),
        ],
      ),
    );
  }

  // Copy logic từ HomeLibraryWidget
  List<UIBlock> _createUIBlocks(List<GeneratedImage> history) {
    final blocks = <UIBlock>[];
    final random = Random();

    if (history.isEmpty) {
      return blocks;
    }

    // Không giới hạn số lượng images trong history screen
    final displayImages = history.toList();

    // Tạo danh sách items chỉ chứa images
    final allItems = <_ItemData>[];
    for (var image in displayImages) {
      allItems.add(_ItemData.image(image));
    }

    int itemIndex = 0;
    final blockTypes = [
      UIBlockType.block1,
      UIBlockType.block2,
      UIBlockType.block3,
      UIBlockType.block4
    ];

    // Tạo các block từ images
    final imageBlocks = <UIBlock>[];
    while (itemIndex < allItems.length) {
      final remainingItems = allItems.length - itemIndex;

      UIBlockType selectedBlockType = _selectOptimalBlockType(
        allItems,
        itemIndex,
        remainingItems,
        blockTypes,
        random,
      );

      List<BlockItem> blockItems =
          _createBlockItems(selectedBlockType, allItems, itemIndex);

      if (blockItems.isNotEmpty) {
        imageBlocks.add(UIBlock(type: selectedBlockType, items: blockItems));
        itemIndex += blockItems.length;
      } else {
        itemIndex++;
      }
    }

    // Chèn ads vào sau block thứ 1, 3, 5, 7... (index 0, 2, 4, 6...)
    for (int i = 0; i < imageBlocks.length; i++) {
      blocks.add(imageBlocks[i]);
      if (i % 2 == 0) {
        // Tạo block quảng cáo
        blocks.add(UIBlock(
          type: UIBlockType.block1,
          items: [
            BlockItem.ad(
              adIndex: 0, // Index không quan trọng lắm với native ad widget mới
              crossAxisCellCount: 3,
              mainAxisCellCount: 1.6,
            )
          ],
        ));
      }
    }

    return blocks;
  }

  UIBlockType _selectOptimalBlockType(
    List<_ItemData> allItems,
    int startIndex,
    int remainingItems,
    List<UIBlockType> blockTypes,
    Random random,
  ) {
    if (remainingItems == 1) {
      return UIBlockType.block1;
    } else if (remainingItems == 2) {
      bool canUseBlock2 = true;
      for (int i = 0; i < 2 && (startIndex + i) < allItems.length; i++) {
        if (allItems[startIndex + i].type == GridItemType.ad) {
          canUseBlock2 = false;
          break;
        }
      }
      return canUseBlock2 ? UIBlockType.block2 : UIBlockType.block1;
    } else if (remainingItems >= 3) {
      final availableBlocks = <UIBlockType>[];

      if (remainingItems >= 2) {
        bool canUseBlock2 = true;
        for (int i = 0; i < 2 && (startIndex + i) < allItems.length; i++) {
          if (allItems[startIndex + i].type == GridItemType.ad) {
            canUseBlock2 = false;
            break;
          }
        }
        if (canUseBlock2) {
          availableBlocks.add(UIBlockType.block2);
        }
      }

      if (remainingItems >= 3) {
        bool canUseBlock3 = true;
        for (int i = 0; i < 3 && (startIndex + i) < allItems.length; i++) {
          if (allItems[startIndex + i].type == GridItemType.ad) {
            canUseBlock3 = false;
            break;
          }
        }
        if (canUseBlock3) {
          availableBlocks.add(UIBlockType.block3);
          availableBlocks.add(UIBlockType.block3);
        }
      }

      if (remainingItems >= 3) {
        bool canUseBlock4 = true;
        for (int i = 0; i < 3 && (startIndex + i) < allItems.length; i++) {
          if (allItems[startIndex + i].type == GridItemType.ad) {
            canUseBlock4 = false;
            break;
          }
        }
        if (canUseBlock4) {
          availableBlocks.add(UIBlockType.block4);
          availableBlocks.add(UIBlockType.block4);
        }
      }

      availableBlocks.add(UIBlockType.block1);

      if (availableBlocks.isNotEmpty) {
        return availableBlocks[random.nextInt(availableBlocks.length)];
      }
    }

    return UIBlockType.block1;
  }

  List<BlockItem> _createBlockItems(
    UIBlockType blockType,
    List<_ItemData> allItems,
    int startIndex,
  ) {
    final blockItems = <BlockItem>[];

    switch (blockType) {
      case UIBlockType.block1:
        if (startIndex < allItems.length) {
          final item = allItems[startIndex];
          if (item.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item.image!,
              crossAxisCellCount: 3,
              mainAxisCellCount: 1.6,
            ));
          } else {
            blockItems.add(BlockItem.ad(
              adIndex: item.adIndex!,
              crossAxisCellCount: 3,
              mainAxisCellCount: 1.6,
            ));
          }
        }
        break;

      case UIBlockType.block2:
        for (int i = 0; i < 2 && (startIndex + i) < allItems.length; i++) {
          final item = allItems[startIndex + i];
          if (item.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item.image!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 2.0,
            ));
          } else {
            blockItems.add(BlockItem.ad(
              adIndex: item.adIndex!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 2.0,
            ));
          }
        }
        break;

      case UIBlockType.block3:
        if ((startIndex + 2) >= allItems.length) {
          break;
        }
        for (int i = 0; i < 2 && (startIndex + i) < allItems.length; i++) {
          final item = allItems[startIndex + i];
          if (item.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item.image!,
              crossAxisCellCount: 1,
              mainAxisCellCount: 1.5,
            ));
          } else {
            blockItems.add(BlockItem.ad(
              adIndex: item.adIndex!,
              crossAxisCellCount: 1,
              mainAxisCellCount: 1.5,
            ));
          }
        }
        if ((startIndex + 2) < allItems.length) {
          final item3 = allItems[startIndex + 2];
          if (item3.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item3.image!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 3.0,
            ));
          } else {
            blockItems.add(BlockItem.ad(
              adIndex: item3.adIndex!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 3.0,
            ));
          }
        }
        break;

      case UIBlockType.block4:
        if (startIndex < allItems.length) {
          final item1 = allItems[startIndex];
          if (item1.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item1.image!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 2.0,
            ));
          } else {
            blockItems.add(BlockItem.ad(
              adIndex: item1.adIndex!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 2.0,
            ));
          }
        }
        for (int i = 1; i < 3 && (startIndex + i) < allItems.length; i++) {
          final item = allItems[startIndex + i];
          if (item.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item.image!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 1.0,
            ));
          } else {
            blockItems.add(BlockItem.ad(
              adIndex: item.adIndex!,
              crossAxisCellCount: 2,
              mainAxisCellCount: 1.0,
            ));
          }
        }
        break;
    }

    return blockItems;
  }

  Widget _buildUIBlock(UIBlock block) {
    switch (block.type) {
      case UIBlockType.block1:
        if (block.items.isEmpty) return const SizedBox.shrink();

        final item = block.items[0];

        if (item.itemType == GridItemType.ad) {
          return _buildAdItem(item.adIndex!);
        }

        return SizedBox(
          width: double.infinity,
          height: 200,
          child: _buildImageItem(
            item.image!.imagePath,
            item.image!.aspectRatio,
            item.image!,
          ),
        );

      case UIBlockType.block2:
        if (block.items.length < 2) return const SizedBox.shrink();
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSizes.spacingS / 2),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: block.items[0].itemType == GridItemType.image
                      ? _buildImageItem(
                          block.items[0].image!.imagePath,
                          block.items[0].image!.aspectRatio,
                          block.items[0].image!,
                        )
                      : _buildAdItem(block.items[0].adIndex!),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSizes.spacingS / 2),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: block.items[1].itemType == GridItemType.image
                      ? _buildImageItem(
                          block.items[1].image!.imagePath,
                          block.items[1].image!.aspectRatio,
                          block.items[1].image!,
                        )
                      : _buildAdItem(block.items[1].adIndex!),
                ),
              ),
            ),
          ],
        );

      case UIBlockType.block3:
        if (block.items.length < 3) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.spacingS / 2,
                      right: AppSizes.spacingS / 2,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: block.items[0].itemType == GridItemType.image
                          ? _buildImageItem(
                              block.items[0].image!.imagePath,
                              block.items[0].image!.aspectRatio,
                              block.items[0].image!,
                            )
                          : _buildAdItem(block.items[0].adIndex!),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSizes.spacingS / 2,
                      right: AppSizes.spacingS / 2,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.8,
                      child: block.items[1].itemType == GridItemType.image
                          ? _buildImageItem(
                              block.items[1].image!.imagePath,
                              block.items[1].image!.aspectRatio,
                              block.items[1].image!,
                            )
                          : _buildAdItem(block.items[1].adIndex!),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSizes.spacingS / 2),
                child: AspectRatio(
                  aspectRatio: 0.7,
                  child: block.items[2].itemType == GridItemType.image
                      ? _buildImageItem(
                          block.items[2].image!.imagePath,
                          block.items[2].image!.aspectRatio,
                          block.items[2].image!,
                        )
                      : _buildAdItem(block.items[2].adIndex!),
                ),
              ),
            ),
          ],
        );

      case UIBlockType.block4:
        if (block.items.length < 3) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSizes.spacingS / 2),
                child: AspectRatio(
                  aspectRatio: 0.7,
                  child: block.items[0].itemType == GridItemType.image
                      ? _buildImageItem(
                          block.items[0].image!.imagePath,
                          block.items[0].image!.aspectRatio,
                          block.items[0].image!,
                        )
                      : _buildAdItem(block.items[0].adIndex!),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.spacingS / 2,
                      left: AppSizes.spacingS / 2,
                    ),
                    child: AspectRatio(
                      aspectRatio: 2.1,
                      child: block.items[1].itemType == GridItemType.image
                          ? _buildImageItem(
                              block.items[1].image!.imagePath,
                              block.items[1].image!.aspectRatio,
                              block.items[1].image!,
                            )
                          : _buildAdItem(block.items[1].adIndex!),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSizes.spacingS / 2,
                      left: AppSizes.spacingS / 2,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: block.items[2].itemType == GridItemType.image
                          ? _buildImageItem(
                              block.items[2].image!.imagePath,
                              block.items[2].image!.aspectRatio,
                              block.items[2].image!,
                            )
                          : _buildAdItem(block.items[2].adIndex!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildImageItem(
    String imagePath,
    String? aspectRatio,
    GeneratedImage image,
  ) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.historyDetail, arguments: image);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: CachedImageWidget(
          imagePath: imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: _buildPlaceholder(),
          errorWidget: _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildAdItem(int adIndex) {
    return Obx(() {
      if (!RemoteConfigService.shared.adsEnabled &&
          !RemoteConfigService.shared.nativeHistoryEnabled) {
        return const SizedBox.shrink();
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: NativeAdWidget(
          uniqueKey: 'native_history',
          factoryId: 'native_small_image_top',
          backgroundColor: Colors.white,
          margin: const EdgeInsets.only(
              left: AppSizes.spacingM,
              right: AppSizes.spacingM,
              bottom: AppSizes.spacingM),
          padding: EdgeInsets.zero,
          height: 210,
          buttonColor: DynamicThemeService.shared.getPrimaryAccentColor(),
          adBackgroundColor: DynamicThemeService.shared.getPrimaryAccentColor(),
        ),
      );
    });
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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

class _ItemData {
  final GridItemType type;
  final GeneratedImage? image;
  final int? adIndex;

  _ItemData.image(this.image)
      : type = GridItemType.image,
        adIndex = null;

  _ItemData.ad(this.adIndex)
      : type = GridItemType.ad,
        image = null;
}

import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/cached_image_widget.dart';
import 'package:flutter_quick_base/core/widgets/text_more_widget.dart';
import 'package:flutter_quick_base/features/image_generation/domain/entities/generated_image.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';

// Enum để phân biệt item type
enum GridItemType {
  image,
  ad,
}

// Model cho UI Block - mỗi block có layout cố định
class UIBlock {
  final UIBlockType type;
  final List<BlockItem> items; // Danh sách items trong block này

  UIBlock({
    required this.type,
    required this.items,
  });
}

// Enum cho 4 loại UI blocks
enum UIBlockType {
  block1, // 1 ảnh lớn vertical (2 cột x 2 hàng)
  block2, // 2 ảnh nhỏ (1 cột x 1 hàng mỗi ảnh)
  block3, // 3 ảnh (1 ảnh lớn + 2 ảnh nhỏ)
  block4, // 4 ảnh grid (2x2)
}

// Model cho item trong block
class BlockItem {
  final GridItemType itemType;
  final GeneratedImage? image;
  final int? adIndex;
  final int crossAxisCellCount; // Số cột chiếm
  final double mainAxisCellCount; // Số hàng chiếm

  BlockItem.image({
    required this.image,
    required this.crossAxisCellCount,
    required this.mainAxisCellCount,
  })  : itemType = GridItemType.image,
        adIndex = null;

  BlockItem.ad({
    required this.adIndex,
    required this.crossAxisCellCount,
    required this.mainAxisCellCount,
  })  : itemType = GridItemType.ad,
        image = null;
}

class HomeLibraryWidget extends StatelessWidget {
  const HomeLibraryWidget(
      {super.key, this.onMoreStyleTap, required this.controller});

  final VoidCallback? onMoreStyleTap;
  final ImageGenerationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.spacingM),
          child: TextMoreWidget(
            title: tr('history'),
            onMoreStyleTap: onMoreStyleTap,
          ),
        ),
        const SizedBox(height: AppSizes.spacingS),
        Obx(() {
          final history = controller.history;
          if (history.isEmpty) {
            return _buildEmptyState();
          }

          // Tạo danh sách UI blocks với layout random
          final uiBlocks = _createUIBlocks(history);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
            child: Column(
              children: uiBlocks.map((block) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
                  child: _buildUIBlock(block),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: AppSizes.bottomNavBarHeight),
      ],
    );
  }

  /// Tạo danh sách UI blocks từ history
  /// Mỗi block sẽ random chọn 1 trong 4 layout cố định
  /// Ads được chèn sau các block lẻ (1, 3, 5, 7...)
  /// Tối đa 20 phần tử hiển thị
  List<UIBlock> _createUIBlocks(List<GeneratedImage> history) {
    final blocks = <UIBlock>[];
    final random = Random();

    // Giới hạn tối đa 20 phần tử
    const int maxDisplayItems = 20;

    if (history.isEmpty) {
      return blocks;
    }

    // Ưu tiên hiển thị images trước, giới hạn số lượng images
    final displayImageCount = min(history.length, maxDisplayItems);
    final displayImages = history.take(displayImageCount).toList();

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
              adIndex: 0,
              crossAxisCellCount: 3,
              mainAxisCellCount: 1.6,
            )
          ],
        ));
      }
    }

    return blocks;
  }

  /// Chọn block type tối ưu dựa trên số items còn lại
  UIBlockType _selectOptimalBlockType(
    List<_ItemData> allItems,
    int startIndex,
    int remainingItems,
    List<UIBlockType> blockTypes,
    Random random,
  ) {
    // Nếu còn ít items, ưu tiên block đơn giản
    if (remainingItems == 1) {
      return UIBlockType.block1;
    } else if (remainingItems == 2) {
      // Kiểm tra xem 2 items có phải là images không (block2 không chứa quảng cáo)
      bool canUseBlock2 = true;
      for (int i = 0; i < 2 && (startIndex + i) < allItems.length; i++) {
        if (allItems[startIndex + i].type == GridItemType.ad) {
          canUseBlock2 = false;
          break;
        }
      }
      return canUseBlock2 ? UIBlockType.block2 : UIBlockType.block1;
    } else if (remainingItems == 3) {
      // Kiểm tra xem có đủ 3 items liên tiếp không có quảng cáo không
      bool canUseBlock3 = true;
      bool canUseBlock4 = true;
      for (int i = 0; i < 3 && (startIndex + i) < allItems.length; i++) {
        if (allItems[startIndex + i].type == GridItemType.ad) {
          canUseBlock3 = false;
          canUseBlock4 = false;
          break;
        }
      }
      // Random chọn giữa block3 và block4 nếu có thể
      if (canUseBlock3 && canUseBlock4) {
        return random.nextBool() ? UIBlockType.block3 : UIBlockType.block4;
      } else if (canUseBlock3) {
        return UIBlockType.block3;
      } else if (canUseBlock4) {
        return UIBlockType.block4;
      } else {
        // Nếu có quảng cáo, dùng block1
        return UIBlockType.block1;
      }
    } else if (remainingItems >= 4) {
      // Với nhiều items, kiểm tra các block có thể dùng
      final availableBlocks = <UIBlockType>[];

      // Kiểm tra block2 (cần 2 items, không có quảng cáo)
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

      // Kiểm tra block3 (cần 3 items, không có quảng cáo)
      // Ưu tiên block3 - thêm nhiều lần vào danh sách để tăng xác suất
      if (remainingItems >= 3) {
        bool canUseBlock3 = true;
        for (int i = 0; i < 3 && (startIndex + i) < allItems.length; i++) {
          if (allItems[startIndex + i].type == GridItemType.ad) {
            canUseBlock3 = false;
            break;
          }
        }
        if (canUseBlock3) {
          // Thêm block3 nhiều lần để tăng xác suất được chọn
          availableBlocks.add(UIBlockType.block3);
          availableBlocks.add(UIBlockType.block3);
          availableBlocks.add(UIBlockType.block3);
        }
      }

      // Kiểm tra block4 (cần 3 items, không có quảng cáo)
      // Ưu tiên block4 - thêm nhiều lần vào danh sách để tăng xác suất
      if (remainingItems >= 3) {
        bool canUseBlock4 = true;
        for (int i = 0; i < 3 && (startIndex + i) < allItems.length; i++) {
          if (allItems[startIndex + i].type == GridItemType.ad) {
            canUseBlock4 = false;
            break;
          }
        }
        if (canUseBlock4) {
          // Thêm block4 nhiều lần để tăng xác suất được chọn
          availableBlocks.add(UIBlockType.block4);
          availableBlocks.add(UIBlockType.block4);
          availableBlocks.add(UIBlockType.block4);
        }
      }

      // Luôn có thể dùng block1 (nhưng ít ưu tiên hơn)
      availableBlocks.add(UIBlockType.block1);

      // Random chọn từ các block có thể dùng
      // Block3 và block4 sẽ có xác suất cao hơn vì xuất hiện nhiều lần
      if (availableBlocks.isNotEmpty) {
        return availableBlocks[random.nextInt(availableBlocks.length)];
      }
    }

    // Fallback: dùng block1
    return UIBlockType.block1;
  }

  /// Build một UI block với layout fix cứng
  Widget _buildUIBlock(UIBlock block) {
    switch (block.type) {
      case UIBlockType.block1:
        if (block.items.isEmpty) return const SizedBox.shrink();

        final item = block.items[0];

        if (item.itemType == GridItemType.ad) {
          // Trả UI quảng cáo riêng không bị cứng height
          return Obx(() {
            if (!RemoteConfigService.shared.adsEnabled) {
              return const SizedBox.shrink();
            }
            return _buildAdItem(item.adIndex!);
          });
        }

        // Còn lại là image mới dùng 200
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
        // Block 2: 2 ảnh nằm ngang (cạnh nhau, bằng nhau)
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
                      : Obx(() {
                          if (!RemoteConfigService.shared.adsEnabled) {
                            return const SizedBox.shrink();
                          }
                          return _buildAdItem(block.items[0].adIndex!);
                        }),
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
                      : Obx(() {
                          if (!RemoteConfigService.shared.adsEnabled) {
                            return const SizedBox.shrink();
                          }
                          return _buildAdItem(block.items[1].adIndex!);
                        }),
                ),
              ),
            ),
          ],
        );

      case UIBlockType.block3:
        // Block 3: 3 ảnh (1 ảnh lớn bên phải + 2 ảnh nhỏ bên trái)
        if (block.items.length < 3) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2 ảnh nhỏ bên trái
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
                          : Obx(() {
                              if (!RemoteConfigService.shared.adsEnabled) {
                                return const SizedBox.shrink();
                              }
                              return _buildAdItem(block.items[0].adIndex!);
                            }),
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
                          : Obx(() {
                              if (!RemoteConfigService.shared.adsEnabled) {
                                return const SizedBox.shrink();
                              }
                              return _buildAdItem(block.items[1].adIndex!);
                            }),
                    ),
                  ),
                ],
              ),
            ),
            // 1 ảnh lớn bên phải
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSizes.spacingS / 2),
                child: AspectRatio(
                  aspectRatio: 0.7, // Chiều cao gấp đôi chiều rộng
                  child: block.items[2].itemType == GridItemType.image
                      ? _buildImageItem(
                          block.items[2].image!.imagePath,
                          block.items[2].image!.aspectRatio,
                          block.items[2].image!,
                        )
                      : Obx(() {
                          if (!RemoteConfigService.shared.adsEnabled) {
                            return const SizedBox.shrink();
                          }
                          return _buildAdItem(block.items[2].adIndex!);
                        }),
                ),
              ),
            ),
          ],
        );

      case UIBlockType.block4:
        // Block 4: 3 ảnh (1 ảnh lớn bên trái + 2 ảnh nhỏ bên phải)
        if (block.items.length < 3) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 ảnh lớn bên trái
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSizes.spacingS / 2),
                child: AspectRatio(
                  aspectRatio: 0.7, // Chiều cao gấp đôi chiều rộng
                  child: block.items[0].itemType == GridItemType.image
                      ? _buildImageItem(
                          block.items[0].image!.imagePath,
                          block.items[0].image!.aspectRatio,
                          block.items[0].image!,
                        )
                      : Obx(() {
                          if (!RemoteConfigService.shared.adsEnabled) {
                            return const SizedBox.shrink();
                          }
                          return _buildAdItem(block.items[0].adIndex!);
                        }),
                ),
              ),
            ),
            // 2 ảnh nhỏ bên phải
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
                          : Obx(() {
                              if (!RemoteConfigService.shared.adsEnabled) {
                                return const SizedBox.shrink();
                              }
                              return _buildAdItem(block.items[1].adIndex!);
                            }),
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
                          : Obx(() {
                              if (!RemoteConfigService.shared.adsEnabled) {
                                return const SizedBox.shrink();
                              }
                              return _buildAdItem(block.items[2].adIndex!);
                            }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  /// Tạo items cho một block dựa trên type
  List<BlockItem> _createBlockItems(
    UIBlockType blockType,
    List<_ItemData> allItems,
    int startIndex,
  ) {
    final blockItems = <BlockItem>[];

    switch (blockType) {
      case UIBlockType.block1:
        // Block 1: 1 ảnh lớn full ngang màn hình
        if (startIndex < allItems.length) {
          final item = allItems[startIndex];
          if (item.type == GridItemType.image) {
            blockItems.add(BlockItem.image(
              image: item.image!,
              crossAxisCellCount: 3, // Không dùng nữa nhưng giữ để consistency
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
        // Block 2: 2 ảnh nằm ngang (cạnh nhau, bằng nhau)
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
        // Block 3: 3 ảnh (1 ảnh lớn bên phải + 2 ảnh nhỏ bên trái)
        // Thứ tự trong block.items: [ảnh nhỏ 1, ảnh nhỏ 2, ảnh lớn]
        // UI hiển thị: items[0] và items[1] bên trái, items[2] bên phải
        if ((startIndex + 2) >= allItems.length) {
          // Nếu không đủ 3 items, không tạo block này
          break;
        }

        // 2 ảnh nhỏ bên trái (lấy từ startIndex và startIndex + 1)
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

        // Ảnh lớn bên phải (lấy từ startIndex + 2)
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
        // Block 4: 3 ảnh (1 ảnh lớn bên trái + 2 ảnh nhỏ bên phải)
        // Thứ tự: ảnh lớn trước, 2 ảnh nhỏ sau
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
        // 2 ảnh nhỏ
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

  /// Build image item
  Widget _buildImageItem(
      String imagePath, String? aspectRatio, GeneratedImage image) {
    return GestureDetector(
      onTap: () async {
        final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
        if (!hasNet) return;
        final result =
            await Get.toNamed(AppRoutes.historyDetail, arguments: image);

        if (result == true) {
          controller.loadHistory(refresh: true);
        }
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

  /// Build ad item
  Widget _buildAdItem(int adIndex) {
    return Obx(() {
      if (!RemoteConfigService.shared.adsEnabled &&
          !RemoteConfigService.shared.nativeHistoryEnabled) {
        return const SizedBox.shrink();
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: NativeAdWidget(
          key: Key('native_history_$adIndex'),
          uniqueKey: 'native_history',
          factoryId: 'native_small_image_top',
          margin: const EdgeInsets.only(
              left: AppSizes.spacingM,
              right: AppSizes.spacingM,
              bottom: AppSizes.spacingM),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          buttonColor: DynamicThemeService.shared.getPrimaryAccentColor(),
          adBackgroundColor: DynamicThemeService.shared.getPrimaryAccentColor(),
          height: 210,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXL),
      child: Center(
        child: Column(
          children: [
            const SvgIcon(name: "ic_empty_library"),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              tr('no_images'),
              style:
                  kTextRegularStyle.copyWith(color: AppColors.disableColorText),
            ),
            const SizedBox(height: AppSizes.bottomNavBarHeight),
          ],
        ),
      ),
    );
  }
}

// Helper class để lưu trữ item data
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

List<GeneratedImage> _getFakeHistory() {
  return [
    GeneratedImage(
      id: 'fake_1',
      prompt: 'Anime girl with pink hair',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/400/600?random=1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      aspectRatio: '3:4',
    ),
    GeneratedImage(
      id: 'fake_2',
      prompt: 'Beautiful landscape',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/600/400?random=2',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      aspectRatio: '16:9',
    ),
    GeneratedImage(
      id: 'fake_3',
      prompt: 'Cute cat',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/400/400?random=3',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      aspectRatio: '1:1',
    ),
    GeneratedImage(
      id: 'fake_4',
      prompt: 'Sunset view',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/500/700?random=4',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      aspectRatio: '9:16',
    ),
    GeneratedImage(
      id: 'fake_5',
      prompt: 'City at night',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/600/500?random=5',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      aspectRatio: '4:3',
    ),
    GeneratedImage(
      id: 'fake_6',
      prompt: 'Mountain range',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/400/600?random=6',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      aspectRatio: '3:4',
    ),
    GeneratedImage(
      id: 'fake_7',
      prompt: 'Ocean waves',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/600/400?random=7',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      aspectRatio: '16:9',
    ),
    GeneratedImage(
      id: 'fake_8',
      prompt: 'Forest path',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/400/400?random=8',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      aspectRatio: '1:1',
    ),
    GeneratedImage(
      id: 'fake_9',
      prompt: 'Flower field',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/500/800?random=9',
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
      aspectRatio: '9:16',
    ),
    GeneratedImage(
      id: 'fake_10',
      prompt: 'Desert scene',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/600/450?random=10',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      aspectRatio: '4:3',
    ),
    GeneratedImage(
      id: 'fake_11',
      prompt: 'Snow mountain',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/400/600?random=11',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      aspectRatio: '3:4',
    ),
    GeneratedImage(
      id: 'fake_12',
      prompt: 'Tropical beach',
      userPrompt: 'Anime girl with pink hair',
      imagePath: 'https://picsum.photos/700/400?random=12',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      aspectRatio: '16:9',
    ),
  ];
}

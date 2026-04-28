import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';

class BottomNavItem {
  final String iconName;
  final String? activeIconName;
  final String label;
  final Color? selectedColor;
  final Color? unselectedColor;

  const BottomNavItem({
    required this.iconName,
    this.activeIconName,
    required this.label,
    this.selectedColor,
    this.unselectedColor,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<BottomNavItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? defaultSelectedColor;
  final Color? defaultUnselectedColor;
  final double height;
  final bool showIndicator;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.defaultSelectedColor,
    this.defaultUnselectedColor,
    this.height = 70,
    this.showIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.color322E34.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          )),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => _buildNavItem(
            index: index,
            item: items[index],
            isSelected: selectedIndex == index,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required BottomNavItem item,
    required bool isSelected,
  }) {
    final iconName = isSelected && item.activeIconName != null
        ? item.activeIconName!
        : item.iconName;
    final isFirst = index == 0;
    final isLast = index == items.length - 1;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isSelected && showIndicator
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.colorE9E6FE, AppColors.surface])
                    : const LinearGradient(colors: [
                        Colors.white,
                        Colors.white,
                      ]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isFirst ? 8 : 0),
                  topRight: Radius.circular(isLast ? 8 : 0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgIcon(
                    name: iconName,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: kTextRegularStyle.copyWith(
                        color: isSelected ? AppColors.color250DEF : null),
                  ),
                ],
              ),
            ),
            if (isSelected && showIndicator)
              Positioned(
                top: 0,
                left: 10,
                right: 10,
                child: LayoutBuilder(builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: constraints.maxWidth / 1.6,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.color796AF7,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(26),
                          bottomRight: Radius.circular(26),
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/salomon_bottom_bar_widget.dart';
// import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: AppSizes.bottomNavBarHeight,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: AppColors.color231B1D),
        child: SalomonBottomBar(
          currentIndex: currentIndex,
          onTap: onTap,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(.85),
          itemPadding: const EdgeInsets.symmetric(horizontal: 0),
          backgroundColor: Colors.transparent,
          items: [
            SalomonBottomBarItem(
              icon: const SvgIcon(name: "ic_home"),
              title: Text(
                tr('home'),
                style: kTextButtonStyle,
              ),
              selectedColor: AppColors.background,
            ),
            SalomonBottomBarItem(
              icon: const SvgIcon(name: "ic_generate_ai"),
              title: Text(
                tr('generate'),
                style: kTextButtonStyle,
              ),
              selectedColor: AppColors.background,
            ),
            SalomonBottomBarItem(
              icon: const SvgIcon(name: "ic_libary"),
              title: Text(
                tr('gallery'),
                style: kTextButtonStyle,
              ),
              selectedColor: AppColors.background,
            ),
            SalomonBottomBarItem(
              icon: const SvgIcon(name: "ic_person"),
              title: Text(
                tr('profile'),
                style: kTextButtonStyle,
              ),
              selectedColor: AppColors.background,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveNavItem extends StatelessWidget {
  const _ActiveNavItem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1000),
        gradient: const LinearGradient(
          colors: [
            AppColors.colorA30049,
            AppColors.colorFF18BA,
            AppColors.colorE037B3,
            AppColors.colorAD01C3,
            AppColors.color600088,
          ],
        ),
      ),
      child: child,
    );
  }
}

class _InactiveNavItem extends StatelessWidget {
  const _InactiveNavItem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(.12), width: 2),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

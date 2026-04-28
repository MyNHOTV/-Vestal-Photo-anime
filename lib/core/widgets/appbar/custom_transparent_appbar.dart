import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';

class CustomTransparentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomTransparentAppBar(
      {super.key,
      required this.title,
      this.nextButtonText,
      this.nextIcon,
      this.nextIconSize,
      this.nextIconColor,
      this.onNextTap,
      this.onBackTap,
      this.showNext = true,
      this.colors,
      this.backIcon});

  final String title;
  final String? nextButtonText;
  final String? nextIcon; // Icon name cho SvgIcon
  final double? nextIconSize; // Size cho nextIcon (width và height)
  final Color? nextIconColor; // Màu cho nextIcon
  final VoidCallback? onNextTap;
  final VoidCallback? onBackTap;
  final bool showNext;
  final Color? colors;
  final String? backIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors ?? Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
              top: AppSizes.spacingM,
              left: AppSizes.spacingM,
              right: AppSizes.spacingM,
              bottom: AppSizes.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button - circular white with shadow
              GestureDetector(
                onTap: () async {
                  final hasNet =
                      await NetworkService.to.checkNetworkForInAppFunction();
                  if (!hasNet) return;

                  if (onBackTap != null) {
                    onBackTap!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: backIcon != null
                    ? SvgIcon(
                        height: 16,
                        width: 16,
                        name: backIcon ?? 'ic_close',
                        color: AppColors.colorBlack,
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: SvgIcon(
                            name: 'ic_back',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
              ),

              // Title - bold black text
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: kBricolageBoldStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.color121212,
                  ),
                ),
              ),

              // Next button - có thể là text hoặc icon
              if (showNext)
                GestureDetector(
                  onTap: () async {
                    final hasNet =
                        await NetworkService.to.checkNetworkForInAppFunction();
                    if (!hasNet) return;

                    if (onNextTap != null) {
                      onNextTap!();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: nextIcon != null
                        ? SvgIcon(
                            height: nextIconSize ?? 16,
                            width: nextIconSize ?? 16,
                            name: nextIcon!,
                            color: nextIconColor ?? AppColors.color400FA7,
                          )
                        : Text(
                            nextButtonText ?? tr('next'),
                            style: kBricolageBoldStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.color400FA7, // Purple color
                            ),
                          ),
                  ),
                )
              else
                const SizedBox(width: 24), // Spacing when no next button
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

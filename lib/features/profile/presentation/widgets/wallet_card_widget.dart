import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/export_constants.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/widgets/app_button.dart';

/// Widget hiển thị wallet card với coins và nút upgrade
class WalletCardWidget extends StatelessWidget {
  const WalletCardWidget({
    super.key,
    required this.coins,
    this.onUpgradeTap,
  });

  final int coins;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.color600088,
            AppColors.colorAD01C3,
            AppColors.colorE037B3,
          ],
        ),
      ),
      child: Row(
        children: [
          // Left side - Coins info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('your_wallet'),
                  style: kTextSmallStyle.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      coins.formatNumber,
                      style: kTextHeadingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingXS),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tr('coins'),
                        style: kTextRegularStyle.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingM),
                AppPrimaryButton(
                  title: tr('upgrade_plan'),
                  height: 36,
                  width: double.infinity,
                  onTap: onUpgradeTap ?? () {},
                ),
              ],
            ),
          ),
          // Right side - Wallet icon (3D effect)
          const SizedBox(width: AppSizes.spacingL),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Wallet icon placeholder
                Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                // Profile picture badge
                Positioned(
                  bottom: -5,
                  right: -5,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      color: Colors.grey.shade300,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

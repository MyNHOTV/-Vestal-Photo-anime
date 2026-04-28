import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';

import '../constants/export_constants.dart';

class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar({
    super.key,
    this.titleKey,
    this.title,
    this.leading,
    this.showLeading = true,
    this.actions,
    this.showActions = true,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0,
    this.onLeadingTap,
  });

  final String? titleKey;
  final String? title;
  final Widget? leading;
  final bool showLeading;
  final List<Widget>? actions;
  final bool showActions;
  final Color backgroundColor;
  final double elevation;
  final Function? onLeadingTap;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title ?? (titleKey != null ? tr(titleKey!) : ''),
        style: kTextHeadingStyle.copyWith(),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor,
      scrolledUnderElevation: 0,
      elevation: elevation,
      leading: showLeading
          ? GestureDetector(
              onTap: () async {
                final hasNet =
                    await NetworkService.to.checkNetworkForInAppFunction();
                if (!hasNet) return;

                if (onLeadingTap != null) {
                  onLeadingTap!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, top: 10, bottom: 10, right: 10),
                child: (leading ?? const SvgIcon(name: 'ic_arrow_left')),
              ),
            )
          : null,
      actions: showActions ? (actions ?? []) : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

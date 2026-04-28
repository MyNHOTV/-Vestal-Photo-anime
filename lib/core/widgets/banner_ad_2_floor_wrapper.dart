import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';
import 'package:get/get.dart';

class BannerAd2FloorWrapper extends StatefulWidget {
  final String placement;
  final bool is2FloorEnabled;
  final bool isNormalEnabled;
  final bool isCollapsible;

  const BannerAd2FloorWrapper({
    super.key,
    required this.placement,
    required this.is2FloorEnabled,
    required this.isNormalEnabled,
    this.isCollapsible = false,
  });

  @override
  State<BannerAd2FloorWrapper> createState() => _BannerAd2FloorWrapperState();
}

class _BannerAd2FloorWrapperState extends State<BannerAd2FloorWrapper> {
  bool _show2Floor = true;

  @override
  void initState() {
    super.initState();
    _show2Floor = widget.is2FloorEnabled;
  }

  void _handle2FloorFailed() {
    if (widget.isNormalEnabled) {
      debugPrint(
          "🔀 [Banner-${widget.placement}] 🛑 HIGH FLOOR 2F FAILED. Starting Waterfall Fallback to Normal Floor...");
      if (mounted) {
        setState(() {
          _show2Floor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!RemoteConfigService.shared.adsEnabled) {
        return const SizedBox.shrink();
      }

      if (!_show2Floor && !widget.isNormalEnabled) {
        return const SizedBox.shrink();
      }

      return CollapsibleBannerAdWidget(
        key: Key("${widget.placement}_${_show2Floor ? '2floor' : 'normal'}"),
        placement: widget.placement,
        useHighFloor: _show2Floor,
        isCollapsible: widget.isCollapsible,
        onAdFailed: _show2Floor ? _handle2FloorFailed : null,
      );
    });
  }
}

/// Simple convenience wrapper that fetches flags automatically
class BannerAdWrapper extends StatelessWidget {
  final String placement;
  final bool isCollapsible;
  const BannerAdWrapper(
      {super.key, required this.placement, this.isCollapsible = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() => BannerAd2FloorWrapper(
          placement: placement,
          isCollapsible: isCollapsible,
          is2FloorEnabled:
              RemoteConfigService.shared.isBannerHighFloorEnabled(placement),
          isNormalEnabled:
              RemoteConfigService.shared.isBannerNormalEnabled(placement),
        ));
  }
}

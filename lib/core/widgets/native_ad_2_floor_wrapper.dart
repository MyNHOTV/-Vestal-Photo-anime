import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAd2FloorWrapper extends StatefulWidget {
  final String primaryUniqueKey;
  final String fallbackUniqueKey;
  final bool enable2Floor;
  final Function(bool)? onLoadingChanged;
  final String? factoryId;
  final Color? backgroundColor;
  final bool? hasBorder;
  final double? height;
  final Color? buttonColor; // Màu button tùy chỉnh
  final Color? adBackgroundColor;
  final Color? titleColor; // Màu title/headline
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  final NativeAd? preloadedAd;
  final bool? isAdLoaded;
  final Function()? onAdFailed;

  const NativeAd2FloorWrapper({
    super.key,
    required this.primaryUniqueKey,
    required this.fallbackUniqueKey,
    required this.enable2Floor,
    this.onLoadingChanged,
    this.factoryId,
    this.backgroundColor,
    this.hasBorder,
    this.height,
    this.buttonColor,
    this.adBackgroundColor,
    this.titleColor,
    this.preloadedAd,
    this.isAdLoaded,
    this.onAdFailed,
    this.padding,
    this.margin,
  });

  @override
  State<NativeAd2FloorWrapper> createState() => _NativeAd2FloorWrapperState();
}

class _NativeAd2FloorWrapperState extends State<NativeAd2FloorWrapper> {
  bool _show2Floor = true;

  @override
  void initState() {
    super.initState();
    // Whether to attempt the 2-floor placement first (remote config driven)
    _show2Floor = widget.enable2Floor;
  }

  void _handle2FloorFailed() {
    debugPrint(
        "🔀 [Native-${widget.primaryUniqueKey}] 🛑 HIGH FLOOR 2F FAILED. Starting Waterfall Fallback to ${widget.fallbackUniqueKey}...");
    if (mounted) {
      setState(() {
        _show2Floor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_show2Floor) {
      debugPrint(
          "🚀 [Native-${widget.primaryUniqueKey}] ATTEMPTING HIGH FLOOR (2F)");
      return NativeAdWidget(
        key: Key(widget.primaryUniqueKey),
        uniqueKey: widget.primaryUniqueKey,
        factoryId: widget.factoryId ?? 'native_medium_image_top_2',
        backgroundColor: widget.backgroundColor ?? const Color(0xFFF7F7F7),
        hasBorder: widget.hasBorder ?? true,
        buttonColor: widget.buttonColor,
        adBackgroundColor: widget.adBackgroundColor,
        titleColor: widget.titleColor,
        onAdFailed: _handle2FloorFailed,
        onLoadingChanged: widget.onLoadingChanged,
        height: widget.height ?? 320,
        preloadedAd: widget.preloadedAd,
        isPreloadedAdLoaded: widget.isAdLoaded,
        padding: widget.padding,
        margin: widget.margin,
      );
    }

    return NativeAdWidget(
      key: Key(widget.fallbackUniqueKey),
      uniqueKey: widget.fallbackUniqueKey,
      factoryId: widget.factoryId ?? 'native_medium_image_top_2',
      backgroundColor: widget.backgroundColor ?? const Color(0xFFF7F7F7),
      hasBorder: widget.hasBorder ?? true,
      buttonColor: widget.buttonColor,
      adBackgroundColor: widget.adBackgroundColor,
      titleColor: widget.titleColor,
      onLoadingChanged: widget.onLoadingChanged,
      height: widget.height ?? 320,
      preloadedAd: widget.preloadedAd,
      isPreloadedAdLoaded: widget.isAdLoaded,
      onAdFailed: widget.onAdFailed,
      padding: widget.padding,
      margin: widget.margin,
    );
  }
}

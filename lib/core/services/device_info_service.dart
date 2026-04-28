import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Model chứa thông tin thiết bị
class DeviceInfo {
  final String platform; // android, ios
  final String deviceModel;
  final String deviceManufacturer;
  final String osVersion;
  final String osVersionCode;
  final String appVersion;
  final String appBuildNumber;
  final String appPackageName;
  final String? deviceId;
  final String? deviceBrand;

  DeviceInfo({
    required this.platform,
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.osVersion,
    required this.osVersionCode,
    required this.appVersion,
    required this.appBuildNumber,
    required this.appPackageName,
    this.deviceId,
    this.deviceBrand,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'device_model': deviceModel,
      'device_manufacturer': deviceManufacturer,
      'os_version': osVersion,
      'os_version_code': osVersionCode,
      'app_version': appVersion,
      'app_build_number': appBuildNumber,
      'app_package_name': appPackageName,
      if (deviceId != null) 'device_id': deviceId,
      if (deviceBrand != null) 'device_brand': deviceBrand,
    };
  }
}

/// Service để lấy thông tin thiết bị
class DeviceInfoService {
  DeviceInfoService._internal();
  static final DeviceInfoService shared = DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  DeviceInfo? _cachedDeviceInfo;

  /// Lấy thông tin thiết bị (có cache)
  Future<DeviceInfo> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        _cachedDeviceInfo = DeviceInfo(
          platform: 'android',
          deviceModel: androidInfo.model,
          deviceManufacturer: androidInfo.manufacturer,
          osVersion: androidInfo.version.release ?? 'Unknown',
          osVersionCode: androidInfo.version.sdkInt?.toString() ?? 'Unknown',
          appVersion: packageInfo.version,
          appBuildNumber: packageInfo.buildNumber,
          appPackageName: packageInfo.packageName,
          deviceId: androidInfo.id,
          deviceBrand: androidInfo.brand,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        _cachedDeviceInfo = DeviceInfo(
          platform: 'ios',
          deviceModel: iosInfo.utsname.machine ?? 'Unknown',
          deviceManufacturer: 'Apple',
          osVersion: iosInfo.systemVersion,
          osVersionCode:
              iosInfo.systemVersion, // iOS không có SDK version riêng
          appVersion: packageInfo.version,
          appBuildNumber: packageInfo.buildNumber,
          appPackageName: packageInfo.packageName,
          deviceId: iosInfo.identifierForVendor,
          deviceBrand: 'Apple',
        );
      } else {
        // Fallback cho platform khác
        _cachedDeviceInfo = DeviceInfo(
          platform: Platform.operatingSystem,
          deviceModel: 'Unknown',
          deviceManufacturer: 'Unknown',
          osVersion: Platform.operatingSystemVersion,
          osVersionCode: Platform.operatingSystemVersion,
          appVersion: packageInfo.version,
          appBuildNumber: packageInfo.buildNumber,
          appPackageName: packageInfo.packageName,
        );
      }

      return _cachedDeviceInfo!;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device info: $e');
      }

      // Return default device info nếu có lỗi
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedDeviceInfo = DeviceInfo(
        platform: Platform.operatingSystem,
        deviceModel: 'Unknown',
        deviceManufacturer: 'Unknown',
        osVersion: Platform.operatingSystemVersion,
        osVersionCode: Platform.operatingSystemVersion,
        appVersion: packageInfo.version,
        appBuildNumber: packageInfo.buildNumber,
        appPackageName: packageInfo.packageName,
      );
      return _cachedDeviceInfo!;
    }
  }

  /// Reset cache (nếu cần refresh)
  void clearCache() {
    _cachedDeviceInfo = null;
  }
}

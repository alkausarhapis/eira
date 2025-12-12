import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_block_model.dart';

class NativeBlockService {
  static const MethodChannel _channel = MethodChannel('com.eira/native_block');

  Future<List<InstalledAppModel>> getInstalledUserApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getInstalledUserApps',
      );
      return result
          .map((app) => InstalledAppModel.fromMap(app as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
      return [];
    }
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final result = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      return result as Uint8List?;
    } catch (e) {
      debugPrint('Error getting app icon: $e');
      return null;
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        'requestOverlayPermission',
      );
      return result;
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
      return false;
    }
  }

  Future<bool> requestAccessibilitySettings() async {
    try {
      final bool result = await _channel.invokeMethod(
        'requestAccessibilitySettings',
      );
      return result;
    } catch (e) {
      debugPrint('Error requesting accessibility settings: $e');
      return false;
    }
  }

  Future<bool> requestUsageStatsPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        'requestUsageStatsPermission',
      );
      return result;
    } catch (e) {
      debugPrint('Error requesting usage stats permission: $e');
      return false;
    }
  }

  Future<bool> startBlock({
    required String packageName,
    required String appName,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('startBlock', {
        'packageName': packageName,
        'appName': appName,
      });
      return result;
    } catch (e) {
      debugPrint('Error starting block: $e');
      return false;
    }
  }

  Future<bool> stopBlock(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod('stopBlock', {
        'packageName': packageName,
      });
      return result;
    } catch (e) {
      debugPrint('Error stopping block: $e');
      return false;
    }
  }

  Future<Map<String, bool>> getPermissionsStatus() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getPermissionsStatus',
      );
      return {
        'overlayGranted': result['overlayGranted'] as bool,
        'accessibilityGranted': result['accessibilityGranted'] as bool,
        'usageStatsGranted': result['usageStatsGranted'] as bool,
      };
    } catch (e) {
      debugPrint('Error getting permissions status: $e');
      return {
        'overlayGranted': false,
        'accessibilityGranted': false,
        'usageStatsGranted': false,
      };
    }
  }

  Future<int> getUsageStats({
    required String packageName,
    required int fromTimestamp,
    required int toTimestamp,
  }) async {
    try {
      final int result = await _channel.invokeMethod('getUsageStats', {
        'packageName': packageName,
        'fromTimestamp': fromTimestamp,
        'toTimestamp': toTimestamp,
      });
      return result;
    } catch (e) {
      debugPrint('Error getting usage stats: $e');
      return 0;
    }
  }
}

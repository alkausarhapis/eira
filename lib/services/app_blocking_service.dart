import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppBlockingService {
  static const MethodChannel _channel = MethodChannel('com.eira/native_block');

  /// Updates the list of blocked apps in the Accessibility Service
  /// This should be called whenever blocked apps change
  Future<void> setBlockedApps(List<String> packageNames) async {
    try {
      await _channel.invokeMethod('setBlockedApps', {
        'packageNames': packageNames,
      });
      debugPrint('✅ Updated blocked apps: ${packageNames.length} apps');
    } catch (e) {
      debugPrint('❌ Error setting blocked apps: $e');
      rethrow;
    }
  }

  /// Checks if the Accessibility Service is enabled
  Future<bool> isAccessibilityEnabled() async {
    try {
      // Check if accessibility permission is granted
      final Map<String, dynamic> permissions =
          await _channel.invokeMapMethod('getPermissionsStatus') ?? {};
      final bool isEnabled = permissions['accessibility'] ?? false;
      return isEnabled;
    } catch (e) {
      debugPrint('❌ Error checking accessibility: $e');
      return false;
    }
  }

  /// Opens Android Accessibility Settings
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('requestAccessibilitySettings');
    } catch (e) {
      debugPrint('❌ Error opening accessibility settings: $e');
      rethrow;
    }
  }
}

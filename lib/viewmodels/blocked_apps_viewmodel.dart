import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_block_model.dart';
import '../services/app_blocking_service.dart';
import '../services/blocked_apps_database.dart';
import '../services/native_block_service.dart';

class BlockedAppsViewModel extends ChangeNotifier {
  final NativeBlockService _nativeService = NativeBlockService();
  final AppBlockingService _blockingService = AppBlockingService();
  final BlockedAppsDatabase _database = BlockedAppsDatabase.instance;

  List<InstalledAppModel> _installedApps = [];
  List<BlockedAppModel> _blockedApps = [];
  final Map<String, Uint8List> _iconCache = {};
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, bool> _permissions = {
    'overlayGranted': false,
    'accessibilityGranted': false,
    'usageStatsGranted': false,
  };

  List<InstalledAppModel> get installedApps {
    if (_searchQuery.isEmpty) return _installedApps;
    return _installedApps
        .where(
          (app) =>
              app.appName.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<BlockedAppModel> get blockedApps => _blockedApps;
  bool get isLoading => _isLoading;
  Map<String, bool> get permissions => _permissions;
  bool get hasAllPermissions =>
      _permissions['overlayGranted'] == true &&
      _permissions['accessibilityGranted'] == true &&
      _permissions['usageStatsGranted'] == true;

  String get searchQuery => _searchQuery;

  Uint8List? getAppIcon(String packageName) => _iconCache[packageName];

  Future<void> loadInstalledApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      _installedApps = await _nativeService.getInstalledUserApps();
      await loadBlockedApps();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading apps: $e');
    }
  }

  Future<void> loadAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) return;

    try {
      final iconBytes = await _nativeService.getAppIcon(packageName);
      if (iconBytes != null) {
        _iconCache[packageName] = iconBytes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading icon: $e');
    }
  }

  Future<void> loadBlockedApps() async {
    try {
      // Clean up expired blocks first
      await _database.cleanupExpiredBlocks();

      // Load from sqflite database
      _blockedApps = await _database.getBlockedApps();

      // Update Accessibility Service with current blocked apps list
      final packageNames = _blockedApps.map((app) => app.packageName).toList();
      await _blockingService.setBlockedApps(packageNames);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading blocked apps: $e');
    }
  }

  Future<bool> blockApp({
    required String packageName,
    required String appName,
    required Duration blockDuration,
  }) async {
    try {
      final now = DateTime.now();
      final unblockTime = now.add(blockDuration);

      // Create blocked app model
      final blockedApp = BlockedAppModel(
        packageName: packageName,
        appName: appName,
        blockedUntil: unblockTime.millisecondsSinceEpoch,
        timeSpentSnapshot: 0,
        isBlocked: true,
        blockDurationMillis: blockDuration.inMilliseconds,
      );

      // Save to database
      await _database.insertBlockedApp(blockedApp);

      // Start native blocking service
      final success = await _nativeService.startBlock(
        packageName: packageName,
        appName: appName,
      );

      if (success) {
        await loadBlockedApps(); // This also updates Accessibility Service
      }

      return success;
    } catch (e) {
      debugPrint('Error blocking app: $e');
      return false;
    }
  }

  Future<bool> unblockApp(String packageName) async {
    try {
      // Delete from database
      await _database.deleteBlockedApp(packageName);

      // Stop native blocking service
      final success = await _nativeService.stopBlock(packageName);

      if (success) {
        await loadBlockedApps(); // This also updates Accessibility Service
      }

      return success;
    } catch (e) {
      debugPrint('Error unblocking app: $e');
      return false;
    }
  }

  BlockedAppModel? getBlockedAppInfo(String packageName) {
    try {
      return _blockedApps.firstWhere((app) => app.packageName == packageName);
    } catch (e) {
      return null;
    }
  }

  bool isAppBlocked(String packageName) {
    final blockedApp = getBlockedAppInfo(packageName);
    return blockedApp?.isActive ?? false;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    try {
      final allPermissions = await _nativeService.getPermissionsStatus();
      _permissions = {
        'overlayGranted': allPermissions['overlayGranted'] ?? false,
        'accessibilityGranted': allPermissions['accessibilityGranted'] ?? false,
        'usageStatsGranted': allPermissions['usageStatsGranted'] ?? false,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> requestAccessibilityPermission() async {
    await _nativeService.requestAccessibilitySettings();
    await Future.delayed(const Duration(seconds: 1));
    await checkPermissions();
  }

  Future<void> requestUsageStatsPermission() async {
    await _nativeService.requestUsageStatsPermission();
    await Future.delayed(const Duration(seconds: 1));
    await checkPermissions();
  }

  Future<void> requestOverlayPermission() async {
    await _nativeService.requestOverlayPermission();
    await Future.delayed(const Duration(seconds: 1));
    await checkPermissions();
  }
}

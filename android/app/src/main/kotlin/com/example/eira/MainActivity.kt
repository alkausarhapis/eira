package com.example.eira

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.eira.utils.AppManager
import com.example.eira.utils.PreferencesManager
import com.example.eira.utils.FocusModeOverlayManager
import com.example.eira.service.BlockOverlayService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eira/native_block"
    private lateinit var appManager: AppManager
    private lateinit var prefsManager: PreferencesManager
    private var focusModeOverlay: FocusModeOverlayManager? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        appManager = AppManager(applicationContext)
        prefsManager = PreferencesManager(applicationContext)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledUserApps" -> {
                    coroutineScope.launch {
                        try {
                            val apps = appManager.getInstalledUserApps()
                            withContext(Dispatchers.Main) {
                                result.success(apps.map { app ->
                                    mapOf(
                                        "packageName" to app.packageName,
                                        "appName" to app.appName,
                                        "totalTimeMillis" to app.totalTimeMillis
                                    )
                                })
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ERROR", e.message, null)
                            }
                        }
                    }
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        coroutineScope.launch {
                            try {
                                val icon = appManager.getAppIcon(packageName)
                                withContext(Dispatchers.Main) {
                                    result.success(icon)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "requestAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(true)
                }
                "requestUsageStatsPermission" -> {
                    openUsageStatsSettings()
                    result.success(true)
                }
                "setBlockedApps" -> {
                    @Suppress("UNCHECKED_CAST")
                    val packageNames = call.argument<List<String>>("packageNames")
                    if (packageNames != null) {
                        // Update static variable for immediate effect
                        com.example.eira.service.AppBlockAccessibilityService.blockedApps = packageNames.toSet()
                        android.util.Log.d("MainActivity", "Set blocked apps: ${packageNames.size} apps")
                        android.util.Log.d("MainActivity", "Blocked apps list: $packageNames")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageNames required", null)
                    }
                }
                "startBlock" -> {
                    val packageName = call.argument<String>("packageName")
                    val appName = call.argument<String>("appName")
                    
                    android.util.Log.d("MainActivity", "startBlock called: packageName=$packageName, appName=$appName")
                    
                    if (packageName != null && appName != null) {
                        // Store blocked app info in SharedPreferences
                        prefsManager.addBlockedApp(packageName, appName)
                        android.util.Log.d("MainActivity", "Added $packageName to blocked apps list")
                        
                        // Verify it was added
                        val blockedApps = prefsManager.getBlockedApps()
                        android.util.Log.d("MainActivity", "Current blocked apps: $blockedApps")
                        
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName and appName are required", null)
                    }
                }
                "stopBlock" -> {
                    val packageName = call.argument<String>("packageName")
                    
                    if (packageName != null) {
                        // Remove from SharedPreferences
                        prefsManager.removeBlockedApp(packageName)
                        
                        // Stop overlay service if running
                        val intent = Intent(applicationContext, BlockOverlayService::class.java)
                        applicationContext.stopService(intent)
                        
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                "getPermissionsStatus" -> {
                    val permissions = mapOf(
                        "overlayGranted" to canDrawOverlays(),
                        "accessibilityGranted" to isAccessibilityServiceEnabled(),
                        "usageStatsGranted" to hasUsageStatsPermission()
                    )
                    result.success(permissions)
                }
                "startFocusMode" -> {
                    if (focusModeOverlay == null) {
                        focusModeOverlay = FocusModeOverlayManager(applicationContext)
                    }
                    focusModeOverlay?.show {
                        // Callback when user stops focus mode
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                            .invokeMethod("onFocusModeStop", null)
                    }
                    result.success(true)
                }
                "stopFocusMode" -> {
                    focusModeOverlay?.hide()
                    result.success(true)
                }
                "getUsageStats" -> {
                    val packageName = call.argument<String>("packageName")
                    val days = call.argument<Int>("days") ?: 1
                    
                    if (packageName != null) {
                        val endTime = System.currentTimeMillis()
                        val startTime = endTime - (days.toLong() * 24 * 60 * 60 * 1000)
                        val usageTime = appManager.getUsageStats(packageName, startTime, endTime)
                        result.success(usageTime)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestOverlayPermission() {
        if (!canDrawOverlays()) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to general settings if specific intent fails
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
    }

    private fun openAccessibilitySettings() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback
            val intent = Intent(android.provider.Settings.ACTION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }

    private fun openUsageStatsSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback - try to open app details settings
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (ex: Exception) {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "${packageName}/${packageName}.service.AppBlockAccessibilityService"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(service) == true
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}

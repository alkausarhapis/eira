package com.example.eira.service

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.eira.model.BlockedAppData
import com.example.eira.utils.AppUsageStatsManager
import com.example.eira.utils.BlockOverlayManager
import org.json.JSONArray
import org.json.JSONObject

class AppBlockAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AppBlockService"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val BLOCKED_APPS_KEY = "flutter.blockedApps"
        private const val CHECK_INTERVAL_MS = 10000L // Check every 10 seconds
        var blockedApps: Map<String, BlockedAppData> = emptyMap()
        var isServiceRunning = false
        
        private var instance: AppBlockAccessibilityService? = null
        
        fun forceReload() {
            instance?.loadBlockedApps()
            Log.d(TAG, "🔄 Force reload triggered")
        }
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var lastBlockedPackage: String? = null
    private var lastBlockTime: Long = 0
    private lateinit var sharedPreferences: SharedPreferences
    private var blockingOverlay: BlockOverlayManager? = null
    private lateinit var usageStatsManager: AppUsageStatsManager
    private val warningShown = mutableSetOf<String>()
    
    // Periodic check runnable
    private val periodicCheckRunnable = object : Runnable {
        override fun run() {
            checkAllBlockedApps()
            handler.postDelayed(this, CHECK_INTERVAL_MS)
        }
    }
    
    // Listen for changes to blocked apps list
    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == BLOCKED_APPS_KEY) {
            Log.d(TAG, "SharedPreferences changed, reloading blocked apps")
            loadBlockedApps()
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "Service onCreate() called")
        
        // Initialize SharedPreferences early
        sharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        // Initialize managers
        usageStatsManager = AppUsageStatsManager(this)
        
        // Load blocked apps immediately
        loadBlockedApps()
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        
        Log.d(TAG, "Accessibility Service connected")
        
        // Register preference listener
        sharedPreferences.registerOnSharedPreferenceChangeListener(prefsListener)
        
        // Initialize overlay manager
        blockingOverlay = BlockOverlayManager(this)
        
        // Load blocked apps again to ensure we have latest data
        loadBlockedApps()
        
        // Start periodic checking
        handler.post(periodicCheckRunnable)
        
        Log.d(TAG, "Service fully initialized with ${blockedApps.size} blocked apps")
    }
    
    private fun loadBlockedApps() {
        try {
            // Read from SharedPreferences (Flutter format)
            val blockedAppsJson = sharedPreferences.getString(BLOCKED_APPS_KEY, null)
            Log.d(TAG, "📖 Reading from SharedPreferences: $blockedAppsJson")
            
            if (blockedAppsJson != null && blockedAppsJson.isNotEmpty()) {
                // Parse JSON array of blocked app objects
                val jsonArray = JSONArray(blockedAppsJson)
                val appsMap = mutableMapOf<String, BlockedAppData>()
                
                for (i in 0 until jsonArray.length()) {
                    val jsonObject = jsonArray.getJSONObject(i)
                    val packageName = jsonObject.getString("packageName")
                    val appName = jsonObject.getString("appName")
                    val limitMillis = jsonObject.getLong("limitMillis")
                    val startTime = jsonObject.getLong("startTime")
                    val isActive = jsonObject.getBoolean("isActive")
                    
                    if (isActive) {
                        appsMap[packageName] = BlockedAppData(
                            packageName = packageName,
                            appName = appName,
                            limitMillis = limitMillis,
                            startTime = startTime,
                            isActive = isActive
                        )
                    }
                }
                
                blockedApps = appsMap
                warningShown.clear() // Reset warnings when apps reload
                Log.d(TAG, "✅ Loaded ${blockedApps.size} blocked apps with limits")
            } else {
                blockedApps = emptyMap()
                Log.d(TAG, "No blocked apps found in SharedPreferences")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading blocked apps", e)
            blockedApps = emptyMap()
        }
    }
    
    private fun checkAllBlockedApps() {
        if (blockedApps.isEmpty()) return
        
        for ((packageName, appData) in blockedApps) {
            val currentUsage = usageStatsManager.getTodayUsageTime(packageName)
            val limit = appData.limitMillis
            val remainingTime = limit - currentUsage
            
            Log.d(TAG, "📊 ${appData.appName}: usage=$currentUsage, limit=$limit, remaining=$remainingTime")
            
            // Show warning at 1 minute remaining
            if (remainingTime in 1..60000 && !warningShown.contains(packageName)) {
                sendNotificationToFlutter("showOneMinuteWarning", appData.appName)
                warningShown.add(packageName)
                Log.d(TAG, "⏰ Warning shown for ${appData.appName}")
            }
        }
    }
    
    private fun shouldBlockApp(packageName: String): Boolean {
        val appData = blockedApps[packageName] ?: return false
        if (!appData.isActive) return false
        
        val currentUsage = usageStatsManager.getTodayUsageTime(packageName)
        val limit = appData.limitMillis
        
        Log.d(TAG, "🔍 Checking ${appData.appName}: usage=$currentUsage, limit=$limit")
        
        return currentUsage >= limit
    }
    
    private fun sendNotificationToFlutter(action: String, appName: String) {
        try {
            val intent = Intent("com.eira.NOTIFICATION_ACTION")
            intent.putExtra("action", action)
            intent.putExtra("appName", appName)
            intent.setPackage(packageName)
            sendBroadcast(intent)
            Log.d(TAG, "📤 Sent notification broadcast: $action for $appName")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error sending notification broadcast", e)
        }
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        val pkgName = event.packageName?.toString() ?: return
        
        // Don't block our own app
        if (pkgName == packageName) return
        
        // Always ensure blocked apps are loaded
        if (blockedApps.isEmpty()) {
            Log.d(TAG, "Blocked apps list is empty, reloading from SharedPreferences")
            loadBlockedApps()
        }
        
        // Check if this app should be blocked based on usage time
        if (shouldBlockApp(pkgName)) {
            val appData = blockedApps[pkgName]!!
            Log.d(TAG, "🚫 BLOCKING: ${appData.appName} - time limit exceeded")
            
            // Prevent rapid repeated launches
            val currentTime = System.currentTimeMillis()
            if (pkgName == lastBlockedPackage && currentTime - lastBlockTime < 1000) {
                Log.d(TAG, "Skipping duplicate block event")
                return
            }
            
            lastBlockedPackage = pkgName
            lastBlockTime = currentTime
            
            // Send notification to Flutter
            sendNotificationToFlutter("showBlockedNotification", appData.appName)
            
            // Show blocking overlay
            showBlockingOverlay(pkgName)
            
            // Close the blocked app
            handler.postDelayed({
                try {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    Log.d(TAG, "Sent user to home screen")
                } catch (e: Exception) {
                    Log.e(TAG, "Error performing home action", e)
                }
            }, 500)
        }
    }
    
    private fun showBlockingOverlay(packageName: String) {
        try {
            Log.d(TAG, "Showing blocking overlay for: $packageName")
            blockingOverlay?.show(packageName)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error showing overlay", e)
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }
    
    override fun onUnbind(intent: android.content.Intent?): Boolean {
        Log.d(TAG, "Service onUnbind() called")
        // Return true to allow rebinding
        return true
    }
    
    override fun onRebind(intent: android.content.Intent?) {
        super.onRebind(intent)
        Log.d(TAG, "Service onRebind() called")
        // Reload blocked apps when service rebinds
        loadBlockedApps()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        instance = null
        
        Log.d(TAG, "Service onDestroy() called")
        
        try {
            sharedPreferences.unregisterOnSharedPreferenceChangeListener(prefsListener)
            blockingOverlay?.hide()
            blockingOverlay = null
            handler.removeCallbacksAndMessages(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
    }
}

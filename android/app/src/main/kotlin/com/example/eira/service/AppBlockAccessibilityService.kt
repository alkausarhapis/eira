package com.example.eira.service

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.eira.utils.BlockOverlayManager

class AppBlockAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AppBlockService"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val BLOCKED_APPS_KEY = "flutter.blockedApps"
        var blockedApps: Set<String> = emptySet()
        var isServiceRunning = false
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var lastBlockedPackage: String? = null
    private var lastBlockTime: Long = 0
    private lateinit var sharedPreferences: SharedPreferences
    private var blockingOverlay: BlockOverlayManager? = null
    
    // Listen for changes to blocked apps list
    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == BLOCKED_APPS_KEY) {
            loadBlockedApps()
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceRunning = true
        
        // Initialize SharedPreferences
        sharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sharedPreferences.registerOnSharedPreferenceChangeListener(prefsListener)
        
        // Initialize overlay manager
        blockingOverlay = BlockOverlayManager(this)
        
        // Load blocked apps from SharedPreferences
        loadBlockedApps()
        
        Log.d(TAG, "Accessibility Service connected")
        Log.d(TAG, "Blocked apps: ${blockedApps.size}")
    }
    
    private fun loadBlockedApps() {
        try {
            // Read from SharedPreferences (Flutter format)
            val blockedAppsJson = sharedPreferences.getString(BLOCKED_APPS_KEY, null)
            if (blockedAppsJson != null) {
                // Parse JSON array - Flutter stores lists as JSON arrays
                // Example: ["com.example.app1", "com.example.app2"]
                val apps = blockedAppsJson
                    .removeSurrounding("[", "]")
                    .split(",")
                    .map { it.trim().removeSurrounding("\"") }
                    .filter { it.isNotEmpty() }
                    .toSet()
                
                blockedApps = apps
                Log.d(TAG, "Loaded ${blockedApps.size} blocked apps: $blockedApps")
            } else {
                blockedApps = emptySet()
                Log.d(TAG, "No blocked apps found")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading blocked apps", e)
            blockedApps = emptySet()
        }
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        val pkgName = event.packageName?.toString() ?: return
        
        // Don't block our own app
        if (pkgName == packageName) return
        
        Log.d(TAG, "Window changed to: $pkgName")
        
        if (blockedApps.contains(pkgName)) {
            Log.d(TAG, "BLOCKED APP DETECTED: $pkgName")
            
            // Prevent rapid repeated launches
            val currentTime = System.currentTimeMillis()
            if (pkgName == lastBlockedPackage && currentTime - lastBlockTime < 1000) {
                Log.d(TAG, "Skipping duplicate block event")
                return
            }
            
            lastBlockedPackage = pkgName
            lastBlockTime = currentTime
            
            // Show blocking overlay
            showBlockingOverlay(pkgName)
            
            // Close the blocked app
            handler.postDelayed({
                performGlobalAction(GLOBAL_ACTION_HOME)
                Log.d(TAG, "Sent to home screen")
            }, 500)
        }
    }
    
    private fun showBlockingOverlay(packageName: String) {
        try {
            Log.d(TAG, "Showing overlay for blocked app: $packageName")
            blockingOverlay?.show(packageName)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing overlay", e)
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(prefsListener)
        handler.removeCallbacksAndMessages(null)
        blockingOverlay?.hide()
        blockingOverlay = null
        Log.d(TAG, "Service destroyed")
    }
}

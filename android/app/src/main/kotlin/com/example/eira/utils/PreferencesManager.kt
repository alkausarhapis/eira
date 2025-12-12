package com.example.eira.utils

import android.content.Context
import android.content.SharedPreferences

class PreferencesManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("eira_prefs", Context.MODE_PRIVATE)
    
    companion object {
        private const val KEY_OVERLAY_GRANTED = "pref_overlay_granted"
        private const val KEY_ACCESSIBILITY_GRANTED = "pref_accessibility_granted"
        private const val KEY_USAGE_STATS_GRANTED = "pref_usage_stats_granted"
        private const val KEY_THEME = "pref_theme"
        private const val KEY_LAST_SORT = "pref_last_sort"
        private const val KEY_BLOCK_DEFAULT_DURATION = "pref_block_default_duration"
        private const val KEY_BLOCKED_APPS = "pref_blocked_apps"
    }
    
    var overlayGranted: Boolean
        get() = prefs.getBoolean(KEY_OVERLAY_GRANTED, false)
        set(value) = prefs.edit().putBoolean(KEY_OVERLAY_GRANTED, value).apply()
    
    var accessibilityGranted: Boolean
        get() = prefs.getBoolean(KEY_ACCESSIBILITY_GRANTED, false)
        set(value) = prefs.edit().putBoolean(KEY_ACCESSIBILITY_GRANTED, value).apply()
    
    var usageStatsGranted: Boolean
        get() = prefs.getBoolean(KEY_USAGE_STATS_GRANTED, false)
        set(value) = prefs.edit().putBoolean(KEY_USAGE_STATS_GRANTED, value).apply()
    
    var theme: String
        get() = prefs.getString(KEY_THEME, "system") ?: "system"
        set(value) = prefs.edit().putString(KEY_THEME, value).apply()
    
    var lastSort: String
        get() = prefs.getString(KEY_LAST_SORT, "time_spent") ?: "time_spent"
        set(value) = prefs.edit().putString(KEY_LAST_SORT, value).apply()
    
    var blockDefaultDuration: Long
        get() = prefs.getLong(KEY_BLOCK_DEFAULT_DURATION, 24 * 60 * 60 * 1000) // 24 hours default
        set(value) = prefs.edit().putLong(KEY_BLOCK_DEFAULT_DURATION, value).apply()
    
    // Blocked apps management (simple String set)
    fun getBlockedApps(): Set<String> {
        return prefs.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
    }
    
    fun addBlockedApp(packageName: String, appName: String) {
        val blockedApps = getBlockedApps().toMutableSet()
        blockedApps.add(packageName)
        prefs.edit().putStringSet(KEY_BLOCKED_APPS, blockedApps).apply()
    }
    
    fun removeBlockedApp(packageName: String) {
        val blockedApps = getBlockedApps().toMutableSet()
        blockedApps.remove(packageName)
        prefs.edit().putStringSet(KEY_BLOCKED_APPS, blockedApps).apply()
    }
    
    fun isAppBlocked(packageName: String): Boolean {
        return getBlockedApps().contains(packageName)
    }
}

package com.example.eira.utils

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log

class AppUsageStatsManager(private val context: Context) {
    
    companion object {
        private const val TAG = "AppUsageStats"
    }
    
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
    /**
     * Get today's usage time for a specific app in milliseconds
     */
    fun getTodayUsageTime(packageName: String): Long {
        val endTime = System.currentTimeMillis()
        val startTime = getStartOfToday()
        
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        val appStats = stats?.firstOrNull { it.packageName == packageName }
        val totalTime = appStats?.totalTimeInForeground ?: 0L
        
        Log.d(TAG, "📊 Usage for $packageName today: ${totalTime / 1000}s")
        return totalTime
    }
    
    /**
     * Get start of today in milliseconds
     */
    private fun getStartOfToday(): Long {
        val calendar = java.util.Calendar.getInstance()
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}

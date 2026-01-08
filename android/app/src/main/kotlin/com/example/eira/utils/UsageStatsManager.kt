package com.example.eira.utils

import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import java.util.Calendar

/**
 * Centralized manager for accurate usage statistics calculation.
 * This ensures consistent usage time reporting across all components.
 */
class AppUsageStatsManager(private val context: Context) {
    
    companion object {
        private const val TAG = "AppUsageStats"
    }
    
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
    /**
     * Get today's usage time for a specific app in milliseconds.
     * This method queries from midnight today to now and returns the EXACT total foreground time.
     * 
     * @param packageName The package name to query
     * @return Total foreground time in milliseconds since midnight today
     */
    fun getTodayUsageTime(packageName: String): Long {
        val endTime = System.currentTimeMillis()
        val startTime = getStartOfToday()
        
        return getUsageTimeInRange(packageName, startTime, endTime)
    }
    
    /**
     * Get usage time for a specific package within a time range.
     * 
     * @param packageName The package name to query
     * @param startTime Start time in milliseconds since epoch
     * @param endTime End time in milliseconds since epoch
     * @return Total foreground time in milliseconds
     */
    fun getUsageTimeInRange(packageName: String, startTime: Long, endTime: Long): Long {
        try {
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            if (stats.isNullOrEmpty()) {
                return 0L
            }
            
            val stat = stats
                .filter { it.packageName == packageName }
                .maxByOrNull { it.lastTimeUsed }
            
            return stat?.totalTimeInForeground ?: 0L
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting usage stats for $packageName", e)
            return 0L
        }
    }
    
    /**
     * Get usage statistics for ALL apps today.
     * Returns a map of packageName -> totalTimeInForeground (milliseconds).
     * 
     * This is more efficient than calling getTodayUsageTime for each app.
     */
    fun getAllTodayUsageStats(): Map<String, Long> {
        val endTime = System.currentTimeMillis()
        val startTime = getStartOfToday()
        
        return getAllUsageStatsInRange(startTime, endTime)
    }
    
    /**
     * Get usage statistics for ALL apps within a time range.
     * 
     * @param startTime Start time in milliseconds since epoch
     * @param endTime End time in milliseconds since epoch
     * @return Map of packageName to total foreground time in milliseconds
     */
    fun getAllUsageStatsInRange(startTime: Long, endTime: Long): Map<String, Long> {
        try {
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            
            if (stats.isNullOrEmpty()) {
                return emptyMap()
            }
            
            return stats
                .groupBy { it.packageName }
                .mapValues { (_, packageStats) ->
                    packageStats.maxByOrNull { it.lastTimeUsed }?.totalTimeInForeground ?: 0L
                }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error getting all usage stats", e)
            return emptyMap()
        }
    }
    
    /**
     * Get the start of today (midnight) in milliseconds.
     */
    private fun getStartOfToday(): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis
    }
    
    /**
     * Format usage time for display.
     * 
     * @param milliseconds Usage time in milliseconds
     * @return Formatted string like "1h 23m" or "45m" or "12s"
     */
    fun formatUsageTime(milliseconds: Long): String {
        if (milliseconds == 0L) return "0m"
        
        val totalSeconds = milliseconds / 1000
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        
        return when {
            hours > 0 -> "${hours}h ${minutes}m"
            minutes > 0 -> "${minutes}m"
            else -> "${seconds}s"
        }
    }
    
    /**
     * Get detailed usage info for debugging.
     */
    fun getDetailedUsageInfo(packageName: String): String {
        val endTime = System.currentTimeMillis()
        val startTime = getStartOfToday()
        
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        val appStats = stats?.filter { it.packageName == packageName } ?: emptyList()
        
        return buildString {
            appendLine("Package: $packageName")
            appendLine("Entries: ${appStats.size}")
            appStats.forEachIndexed { index, stat ->
                appendLine("Entry $index:")
                appendLine("  Total time: ${stat.totalTimeInForeground}ms (${stat.totalTimeInForeground / 1000}s)")
                appendLine("  Last used: ${stat.lastTimeUsed}")
                appendLine("  First timestamp: ${stat.firstTimeStamp}")
                appendLine("  Last timestamp: ${stat.lastTimeStamp}")
            }
            val total = appStats.sumOf { it.totalTimeInForeground }
            appendLine("TOTAL: ${total}ms (${total / 1000}s)")
        }
    }
}

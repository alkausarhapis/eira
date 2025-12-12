package com.example.eira.utils

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Process
import android.provider.Settings
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.util.Calendar

data class AppInfo(
    val packageName: String,
    val appName: String,
    val iconBytes: ByteArray?,
    val totalTimeMillis: Long
)

class AppManager(private val context: Context) {
    private val packageManager: PackageManager = context.packageManager
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    private val iconCache = mutableMapOf<String, ByteArray?>()
    
    suspend fun getInstalledUserApps(): List<AppInfo> = withContext(Dispatchers.IO) {
        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        val userApps = installedApps.filter { appInfo ->
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            !isSystem || isUpdatedSystem
        }
        
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        
        val usageStatsMap = getUsageStatsMap(startTime, endTime)
        
        userApps.map { appInfo ->
            AppInfo(
                packageName = appInfo.packageName,
                appName = appInfo.loadLabel(packageManager).toString(),
                iconBytes = null, // Load lazily
                totalTimeMillis = usageStatsMap[appInfo.packageName]?.totalTimeInForeground ?: 0
            )
        }.sortedByDescending { it.totalTimeMillis }
    }
    
    suspend fun getAppIcon(packageName: String): ByteArray? = withContext(Dispatchers.IO) {
        iconCache.getOrPut(packageName) {
            try {
                val icon = packageManager.getApplicationIcon(packageName)
                drawableToByteArray(icon)
            } catch (e: PackageManager.NameNotFoundException) {
                null
            }
        }
    }
    
    fun getUsageStats(packageName: String, fromTimestamp: Long, toTimestamp: Long): Long {
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            fromTimestamp,
            toTimestamp
        )
        
        return usageStats?.firstOrNull { it.packageName == packageName }?.totalTimeInForeground ?: 0
    }
    
    private fun getUsageStatsMap(startTime: Long, endTime: Long): Map<String, UsageStats> {
        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        // Aggregate by package name
        return usageStatsList?.groupBy { it.packageName }
            ?.mapValues { entry ->
                entry.value.maxByOrNull { it.lastTimeUsed } ?: entry.value.first()
            } ?: emptyMap()
    }
    
    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return bitmapToByteArray(drawable.bitmap)
        }
        
        val bitmap = Bitmap.createBitmap(
            drawable.intrinsicWidth.coerceAtLeast(1),
            drawable.intrinsicHeight.coerceAtLeast(1),
            Bitmap.Config.ARGB_8888
        )
        
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        
        return bitmapToByteArray(bitmap)
    }
    
    private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
    
    fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
    
    fun hasOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(context)
    }
}

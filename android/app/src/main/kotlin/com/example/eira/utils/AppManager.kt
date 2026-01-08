package com.example.eira.utils

import android.app.AppOpsManager
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

data class AppInfo(
    val packageName: String,
    val appName: String,
    val iconBytes: ByteArray?,
    val totalTimeMillis: Long
)

class AppManager(private val context: Context) {
    private val packageManager: PackageManager = context.packageManager
    private val usageStatsHelper = AppUsageStatsManager(context)
    private val iconCache = mutableMapOf<String, ByteArray?>()
    
    suspend fun getInstalledUserApps(): List<AppInfo> = withContext(Dispatchers.IO) {
        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        val userApps = installedApps.filter { appInfo ->
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val isUpdatedSystem = (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            val isEiraApp = appInfo.packageName == context.packageName
            (!isSystem || isUpdatedSystem) && !isEiraApp
        }
        
        // Get all usage stats at once for efficiency
        val usageStatsMap = usageStatsHelper.getAllTodayUsageStats()
        
        userApps.map { appInfo ->
            AppInfo(
                packageName = appInfo.packageName,
                appName = appInfo.loadLabel(packageManager).toString(),
                iconBytes = null, // Load lazily
                totalTimeMillis = usageStatsMap[appInfo.packageName] ?: 0
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
        return usageStatsHelper.getUsageTimeInRange(packageName, fromTimestamp, toTimestamp)
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

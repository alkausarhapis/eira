package com.example.eira.utils

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.eira.R

class AppLimitNotificationManager(private val context: Context) {
    
    companion object {
        private const val CHANNEL_ID = "app_limit_warnings"
        private const val CHANNEL_NAME = "Peringatan Batas Aplikasi"
        private const val ONE_MINUTE_WARNING_ID = 1001
        private const val BLOCKED_NOTIFICATION_ID = 1002
    }
    
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    init {
        createNotificationChannel()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi peringatan batas waktu aplikasi"
                setShowBadge(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    fun showOneMinuteWarning(appName: String) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("⏰ Peringatan Batas Waktu")
            .setContentText("$appName akan diblokir dalam 1 menit")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .build()
        
        notificationManager.notify(ONE_MINUTE_WARNING_ID, notification)
    }
    
    fun showBlockedNotification(appName: String) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_delete)
            .setContentTitle("🚫 Aplikasi Diblokir")
            .setContentText("$appName telah mencapai batas waktu penggunaan")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        
        notificationManager.notify(BLOCKED_NOTIFICATION_ID, notification)
    }
    
    fun cancelWarning() {
        notificationManager.cancel(ONE_MINUTE_WARNING_ID)
    }
}

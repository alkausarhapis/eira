package com.example.eira.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotificationReceiver"
        var onNotificationReceived: ((String, String) -> Unit)? = null
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "com.eira.NOTIFICATION_ACTION") {
            val action = intent.getStringExtra("action") ?: return
            val appName = intent.getStringExtra("appName") ?: return
            
            Log.d(TAG, "📨 Received notification: $action for $appName")
            
            // Call the callback if set
            onNotificationReceived?.invoke(action, appName)
        }
    }
}

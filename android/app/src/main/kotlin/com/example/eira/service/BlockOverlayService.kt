package com.example.eira.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat
import com.example.eira.R
import kotlinx.coroutines.*
import java.text.SimpleDateFormat
import java.util.*

class BlockOverlayService : Service() {
    
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var countdownJob: Job? = null
    
    companion object {
        private const val TAG = "BlockOverlayService"
        private const val CHANNEL_ID = "app_block_channel"
        private const val NOTIFICATION_ID = 1
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "BlockOverlayService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val packageName = intent?.getStringExtra("packageName") ?: ""
        val appName = intent?.getStringExtra("appName") ?: "Aplikasi ini"
        
        Log.d(TAG, "onStartCommand: Blocking $appName (package: $packageName)")
        
        // Start as foreground service immediately
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Aplikasi Diblokir")
            .setContentText("$appName sedang diblokir")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ requires foreground service type
            startForeground(NOTIFICATION_ID, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        Log.d(TAG, "Started foreground notification")
        
        // Calculate 24 hours from now
        val blockedUntil = System.currentTimeMillis() + (24 * 60 * 60 * 1000)
        
        showOverlay(appName, blockedUntil)
        
        return START_NOT_STICKY
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pemblokiran Aplikasi",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifikasi untuk aplikasi yang diblokir"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }
    
    private fun showOverlay(appName: String, blockedUntil: Long) {
        Log.d(TAG, "showOverlay called for $appName")
        
        if (overlayView != null) {
            Log.d(TAG, "Overlay already showing, skipping")
            return
        }
        
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )
        
        params.gravity = Gravity.CENTER
        
        // Use application context with Material theme for proper inflation
        val themedContext = android.view.ContextThemeWrapper(
            applicationContext,
            android.R.style.Theme_Material_Light_NoActionBar
        )
        overlayView = LayoutInflater.from(themedContext).inflate(R.layout.block_overlay_layout, null)
        
        // Set up the UI
        overlayView?.findViewById<TextView>(R.id.blocked_app_name)?.text = appName
        val messageText = overlayView?.findViewById<TextView>(R.id.block_message)
        val countdownText = overlayView?.findViewById<TextView>(R.id.countdown_text)
        val unblockTimeText = overlayView?.findViewById<TextView>(R.id.unblock_time)
        
        messageText?.text = "$appName diblokir untuk membantu fokus"
        
        val dateFormat = SimpleDateFormat("dd MMM yyyy, HH:mm", Locale("id", "ID"))
        unblockTimeText?.text = "Diblokir sampai: ${dateFormat.format(Date(blockedUntil))}"
        
        // Start countdown
        startCountdown(countdownText, blockedUntil)
        
        // Close button - returns to home
        overlayView?.findViewById<View>(R.id.close_button)?.setOnClickListener {
            goToHome()
        }
        
        try {
            windowManager?.addView(overlayView, params)
            Log.d(TAG, "Overlay view added to window manager")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add overlay view", e)
            e.printStackTrace()
        }
    }
    
    private fun startCountdown(textView: TextView?, blockedUntil: Long) {
        countdownJob?.cancel()
        countdownJob = serviceScope.launch {
            while (isActive) {
                val now = System.currentTimeMillis()
                val remaining = blockedUntil - now
                
                if (remaining <= 0) {
                    removeOverlay()
                    break
                }
                
                val hours = remaining / (1000 * 60 * 60)
                val minutes = (remaining % (1000 * 60 * 60)) / (1000 * 60)
                val seconds = (remaining % (1000 * 60)) / 1000
                
                textView?.text = String.format("%02d:%02d:%02d", hours, minutes, seconds)
                
                delay(1000)
            }
        }
    }
    
    private fun goToHome() {
        val intent = packageManager.getLaunchIntentForPackage("com.android.launcher")
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        removeOverlay()
    }
    
    private fun removeOverlay() {
        countdownJob?.cancel()
        overlayView?.let {
            try {
                windowManager?.removeView(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        overlayView = null
        stopSelf()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        removeOverlay()
        serviceScope.cancel()
    }
}

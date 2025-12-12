package com.example.eira

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity

class BlockingActivity : ComponentActivity() {
    
    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "blockedPackage"
        private const val TAG = "BlockingActivity"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d(TAG, "=== BlockingActivity onCreate called ===")
        
        // Get blocked package info
        val blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: "Unknown"
        Log.d(TAG, "Blocking package: $blockedPackage")
        
        // Make fullscreen and ensure it shows on top
        window.apply {
            @Suppress("DEPRECATION")
            decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            @Suppress("DEPRECATION")
            addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
        
        Log.d(TAG, "Window flags set")
        
        setContentView(createBlockingView(blockedPackage))
        Log.d(TAG, "=== BlockingActivity setup complete ===")
    }
    
    private fun createBlockingView(blockedPackage: String): View {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFFFFFFFF.toInt())
            setPadding(48, 48, 48, 48)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        // Get app info
        var appName = blockedPackage
        var appIcon: android.graphics.drawable.Drawable? = null
        
        try {
            val appInfo = packageManager.getApplicationInfo(blockedPackage, 0)
            appName = packageManager.getApplicationLabel(appInfo).toString()
            appIcon = packageManager.getApplicationIcon(blockedPackage)
            Log.d(TAG, "Got app info: $appName")
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app info", e)
        }
        
        // App Icon
        val iconView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(200, 200).apply {
                gravity = Gravity.CENTER
                bottomMargin = 32
            }
            appIcon?.let { setImageDrawable(it) }
        }
        layout.addView(iconView)
        
        // App Name
        val nameView = TextView(this).apply {
            text = appName
            textSize = 24f
            gravity = Gravity.CENTER
            setTextColor(0xFF000000.toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 16
            }
        }
        layout.addView(nameView)
        
        // Blocked Message
        val blockedView = TextView(this).apply {
            text = "🚫 $appName diblokir"
            textSize = 32f
            gravity = Gravity.CENTER
            setTextColor(0xFFD32F2F.toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 16
            }
        }
        layout.addView(blockedView)
        
        // Description
        val descView = TextView(this).apply {
            text = "Tetap fokus pada tugas yang penting.\nKamu bisa melakukannya! 💪"
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(0xFF757575.toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 48
            }
        }
        layout.addView(descView)
        
        // Close Button
        val closeButton = Button(this).apply {
            text = "Kembali ke Home"
            textSize = 18f
            setBackgroundColor(0xFF9747FF.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setPadding(48, 32, 48, 32)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 32
                gravity = Gravity.CENTER_HORIZONTAL
            }
            setOnClickListener {
                Log.d(TAG, "Close button clicked")
                goToHome()
            }
        }
        layout.addView(closeButton)
        
        return layout
    }
    
    private fun goToHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        finish()
    }
    
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        goToHome()
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val blockedPackage = intent.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: "Unknown"
        Log.d(TAG, "onNewIntent called for: $blockedPackage")
    }
}

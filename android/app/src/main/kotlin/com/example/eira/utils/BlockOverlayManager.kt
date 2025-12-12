package com.example.eira.utils

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class BlockOverlayManager(private val context: Context) {
    
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    
    companion object {
        private const val TAG = "BlockOverlayManager"
    }
    
    fun show(packageName: String) {
        Log.d(TAG, "=== show() called for $packageName ===")
        hide()

        try {
            // Check overlay permission first
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.canDrawOverlays(context)) {
                    Log.w(TAG, "No overlay permission - cannot show overlay")
                    return
                }
            }

            // Ensure running on main thread
            val mainHandler = android.os.Handler(context.mainLooper)
            mainHandler.post {
                try {
                    Log.d(TAG, "Main thread execution started")
                    
                    val pm = context.packageManager
                    var appName = packageName
                    var appIcon: Drawable? = null
                    try {
                        val appInfo = pm.getApplicationInfo(packageName, 0)
                        appName = pm.getApplicationLabel(appInfo).toString()
                        appIcon = pm.getApplicationIcon(packageName)
                        Log.d(TAG, "Got app info: $appName")
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to get app info for $packageName", e)
                    }

                    overlayView = createOverlayView(appName, appIcon)
                    Log.d(TAG, "Overlay view created")

                    val params = WindowManager.LayoutParams(
                        WindowManager.LayoutParams.MATCH_PARENT,
                        WindowManager.LayoutParams.MATCH_PARENT,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                        } else {
                            @Suppress("DEPRECATION")
                            WindowManager.LayoutParams.TYPE_PHONE
                        },
                        // Keep focusable so close button can receive clicks
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR,
                        PixelFormat.TRANSLUCENT
                    )

                    params.gravity = Gravity.CENTER
                    
                    // Ensure overlay is on top of other app windows
                    @Suppress("DEPRECATION")
                    params.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)

                    Log.d(TAG, "Before addView")
                    windowManager.addView(overlayView, params)
                    Log.d(TAG, "=== Overlay added successfully ===")
                } catch (inner: Exception) {
                    Log.e(TAG, "Failed to add overlay view", inner)
                    inner.printStackTrace()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in show()", e)
            e.printStackTrace()
        }
    }
    
    fun hide() {
        try {
            overlayView?.let {
                windowManager.removeView(it)
                overlayView = null
                Log.d(TAG, "Overlay removed")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding overlay", e)
        }
    }
    
    private fun createOverlayView(appName: String, appIcon: android.graphics.drawable.Drawable?): View {
        Log.d(TAG, "Creating overlay view for $appName")
        
        // Root container with gradient background
        val rootLayout = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            // Gradient background from light purple to white
            val gradientDrawable = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(
                    0xFFF3E5F5.toInt(), // Light purple
                    0xFFFFFFFF.toInt()  // White
                )
            )
            background = gradientDrawable
        }
        
        // Content card container
        val cardLayout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val cardPadding = dpToPx(32)
            setPadding(cardPadding, cardPadding, cardPadding, cardPadding)
            
            // Card background with shadow
            val cardBackground = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dpToPx(24).toFloat()
                setStroke(dpToPx(1), 0xFFE0E0E0.toInt())
            }
            background = cardBackground
            elevation = dpToPx(8).toFloat()
            
            val margin = dpToPx(48)
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(margin, margin, margin, margin)
                gravity = Gravity.CENTER
            }
        }
        
        // App Icon with circular background
        if (appIcon != null) {
            val iconContainer = FrameLayout(context).apply {
                val iconSize = dpToPx(120)
                layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                    gravity = Gravity.CENTER_HORIZONTAL
                    bottomMargin = dpToPx(24)
                }
                
                // Circular background
                val circleBackground = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(0xFFF3E5F5.toInt()) // Light purple
                }
                background = circleBackground
                elevation = dpToPx(4).toFloat()
            }
            
            val iconView = ImageView(context).apply {
                val padding = dpToPx(20)
                setPadding(padding, padding, padding, padding)
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
                setImageDrawable(appIcon)
                scaleType = ImageView.ScaleType.FIT_CENTER
            }
            iconContainer.addView(iconView)
            cardLayout.addView(iconContainer)
        }
        
        // App Name
        val nameView = TextView(context).apply {
            text = appName
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            gravity = Gravity.CENTER
            setTextColor(0xFF212121.toInt()) // Dark gray
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(8)
            }
        }
        cardLayout.addView(nameView)
        
        // Blocked Badge
        val badgeLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            val badgePadding = dpToPx(12)
            setPadding(dpToPx(20), badgePadding, dpToPx(20), badgePadding)
            
            val badgeBackground = GradientDrawable().apply {
                setColor(0xFFFFEBEE.toInt()) // Light red
                cornerRadius = dpToPx(20).toFloat()
            }
            background = badgeBackground
            
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dpToPx(24)
                topMargin = dpToPx(16)
            }
        }
        
        val blockedIcon = TextView(context).apply {
            text = "🚫"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                rightMargin = dpToPx(8)
            }
        }
        badgeLayout.addView(blockedIcon)
        
        val blockedText = TextView(context).apply {
            text = "Aplikasi Diblokir"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTextColor(0xFFC62828.toInt()) // Dark red
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
        }
        badgeLayout.addView(blockedText)
        cardLayout.addView(badgeLayout)
        
        // Motivational Message
        val messageView = TextView(context).apply {
            text = "Tetap fokus pada tugas yang penting.\nKamu bisa melakukannya! 💪"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            gravity = Gravity.CENTER
            setTextColor(0xFF616161.toInt()) // Medium gray
            setLineSpacing(dpToPx(4).toFloat(), 1f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(32)
            }
        }
        cardLayout.addView(messageView)
        
        // Home Button with Material Design
        val homeButton = Button(context).apply {
            text = "Kembali ke Home"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            isAllCaps = false
            
            // Button background with rounded corners
            val buttonBackground = GradientDrawable().apply {
                setColor(0xFF9747FF.toInt()) // Primary purple
                cornerRadius = dpToPx(12).toFloat()
            }
            background = buttonBackground
            
            val horizontalPadding = dpToPx(32)
            val verticalPadding = dpToPx(14)
            setPadding(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding)
            elevation = dpToPx(2).toFloat()
            stateListAnimator = null // Remove default animation
            
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(8)
            }
            
            // Add ripple effect
            foreground = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val rippleColor = 0x40FFFFFF // White with 25% opacity
                android.graphics.drawable.RippleDrawable(
                    android.content.res.ColorStateList.valueOf(rippleColor),
                    null,
                    null
                )
            } else {
                null
            }
            
            setOnClickListener {
                Log.d(TAG, "Close button clicked")
                // Go to home screen
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(homeIntent)
                // Hide overlay
                hide()
            }
        }
        cardLayout.addView(homeButton)
        
        rootLayout.addView(cardLayout)
        return rootLayout
    }
    
    private fun dpToPx(dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}

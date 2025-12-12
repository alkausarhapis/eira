package com.example.eira.utils

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Locale

class FocusModeOverlayManager(private val context: Context) {
    
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var startTime: Long = 0
    private var timerRunnable: Runnable? = null
    private var timerTextView: TextView? = null
    
    companion object {
        private const val TAG = "FocusModeOverlay"
    }
    
    fun show(onStop: () -> Unit) {
        Log.d(TAG, "=== show() called ===")
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
            handler.post {
                try {
                    Log.d(TAG, "Main thread execution started")
                    
                    startTime = System.currentTimeMillis()
                    overlayView = createOverlayView(onStop)
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
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                        PixelFormat.TRANSLUCENT
                    )

                    params.gravity = Gravity.CENTER
                    
                    // Ensure overlay is on top
                    @Suppress("DEPRECATION")
                    params.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)

                    Log.d(TAG, "Before addView")
                    windowManager.addView(overlayView, params)
                    Log.d(TAG, "=== Focus mode overlay added successfully ===")
                    
                    // Start timer after overlay is properly attached to window
                    overlayView?.post {
                        Log.d(TAG, "overlayView attached: ${overlayView?.isAttachedToWindow}")
                        startTimer()
                    }
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
            handler.post {
                stopTimer()
                overlayView?.let {
                    windowManager.removeView(it)
                    overlayView = null
                    Log.d(TAG, "Overlay removed")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding overlay", e)
        }
    }
    
    private fun startTimer() {
        Log.d(TAG, "=== startTimer() called ===")
        stopTimer() // Clear any existing timer
        
        if (timerTextView == null) {
            Log.e(TAG, "timerTextView is null!")
            return
        }
        
        Log.d(TAG, "timerTextView attached: ${timerTextView?.isAttachedToWindow}")
        Log.d(TAG, "Creating timer runnable")
        
        timerRunnable = object : Runnable {
            override fun run() {
                try {
                    val elapsed = (System.currentTimeMillis() - startTime) / 1000
                    val hours = elapsed / 3600
                    val minutes = (elapsed % 3600) / 60
                    val secs = elapsed % 60
                    val timeString = String.format(Locale.getDefault(), "%02d:%02d:%02d", hours, minutes, secs)
                    
                    // Update UI directly (handler is already on main looper)
                    timerTextView?.apply {
                        text = timeString
                        invalidate() // Force redraw
                        requestLayout() // Force layout update
                    }
                    // Log.d(TAG, "Timer updated: $timeString (attached: ${timerTextView?.isAttachedToWindow}, visible: ${timerTextView?.visibility == View.VISIBLE}, size: ${timerTextView?.width}x${timerTextView?.height})")
                    
                    // Schedule next update
                    handler.postDelayed(this, 1000)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in timer runnable", e)
                }
            }
        }
        
        // Post first update immediately
        handler.post(timerRunnable!!)
        Log.d(TAG, "Timer started successfully")
    }
    
    private fun stopTimer() {
        timerRunnable?.let { 
            handler.removeCallbacks(it)
            Log.d(TAG, "Timer stopped")
        }
        timerRunnable = null
    }
    
    private fun updateTimerDisplay(seconds: Int) {
        try {
            val hours = seconds / 3600
            val minutes = (seconds % 3600) / 60
            val secs = seconds % 60
            val timeString = String.format(Locale.getDefault(), "%02d:%02d:%02d", hours, minutes, secs)
            timerTextView?.text = timeString
            Log.d(TAG, "Timer updated: $timeString")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating timer display", e)
        }
    }
    
    private fun createOverlayView(onStop: () -> Unit): View {
        Log.d(TAG, "Creating focus mode overlay view")
        
        // Root container with black background
        val rootLayout = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.BLACK)
        }
        
        // Content container
        val contentLayout = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val padding = dpToPx(32)
            setPadding(padding, padding, padding, padding)
            
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
            }
        }
        
        // Focus Mode Icon with gradient circle
        val iconContainer = FrameLayout(context).apply {
            val size = dpToPx(120)
            layoutParams = LinearLayout.LayoutParams(size, size).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dpToPx(32)
            }
            
            // Gradient background
            val gradientDrawable = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(
                    0xFF9747FF.toInt(),
                    0xFFB47FFF.toInt()
                )
            ).apply {
                shape = GradientDrawable.OVAL
            }
            background = gradientDrawable
            elevation = dpToPx(4).toFloat()
        }
        
        val iconView = TextView(context).apply {
            text = "👁️"
            textSize = 48f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        iconContainer.addView(iconView)
        contentLayout.addView(iconContainer)
        
        // Title
        val titleView = TextView(context).apply {
            text = "Fokus Mode Aktif"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 32f)
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(16)
            }
        }
        contentLayout.addView(titleView)
        
        // Description
        val descView = TextView(context).apply {
            text = "Overlay ini akan menutup seluruh distraksi dari layar ponselmu"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.CENTER
            setTextColor(0xFFB3B3B3.toInt()) // White70
            setLineSpacing(dpToPx(4).toFloat(), 1f)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(48)
            }
        }
        contentLayout.addView(descView)
        
        // Timer Container
        val timerContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val horizontalPadding = dpToPx(32)
            val verticalPadding = dpToPx(16)
            setPadding(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding)
            
            val timerBackground = GradientDrawable().apply {
                setColor(0x1AFFFFFF) // White with 10% opacity
                cornerRadius = dpToPx(16).toFloat()
                setStroke(dpToPx(2), 0x33FFFFFF) // White with 20% opacity
            }
            background = timerBackground
            
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = dpToPx(48)
            }
        }
        
        val timerLabel = TextView(context).apply {
            text = "Waktu Fokus"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(0x99FFFFFF.toInt()) // White60
            letterSpacing = 0.12f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(8)
            }
        }
        timerContainer.addView(timerLabel)
        
        timerTextView = TextView(context).apply {
            text = "00:00:00"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 48f)
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            // Ensure TextView has proper dimensions
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        Log.d(TAG, "timerTextView created with initial text: ${timerTextView?.text}")
        timerContainer.addView(timerTextView)
        contentLayout.addView(timerContainer)
        
        // Stop Button
        val stopButton = Button(context).apply {
            text = "Hentikan Fokus"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setTextColor(Color.BLACK)
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            isAllCaps = false
            
            val buttonBackground = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dpToPx(12).toFloat()
            }
            background = buttonBackground
            
            val horizontalPadding = dpToPx(32)
            val verticalPadding = dpToPx(16)
            setPadding(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding)
            elevation = dpToPx(0).toFloat()
            stateListAnimator = null
            
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            
            setOnClickListener {
                Log.d(TAG, "Stop button clicked")
                hide()
                onStop()
            }
        }
        contentLayout.addView(stopButton)
        
        rootLayout.addView(contentLayout)
        return rootLayout
    }
    
    private fun dpToPx(dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}

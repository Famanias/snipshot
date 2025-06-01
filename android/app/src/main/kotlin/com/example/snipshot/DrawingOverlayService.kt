package com.example.snipshot

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.*
import android.view.*
import androidx.core.app.NotificationCompat

class DrawingOverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var drawingView: RectangleSelectionView

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        showOverlay()
    }

    private fun startForegroundService() {
        val channelId = "overlay_channel_id"
        val channelName = "Overlay Drawing Service"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_NONE)
            chan.lightColor = Color.BLUE
            chan.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(chan)
        }

        val notificationBuilder = NotificationCompat.Builder(this, channelId)
        val notification: Notification = notificationBuilder
            .setOngoing(true)
            .setContentTitle("SnipShot Overlay")
            .setContentText("Tap and drag to select a region")
            .setSmallIcon(android.R.drawable.ic_menu_crop)
            .setPriority(NotificationManager.IMPORTANCE_MIN)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()

        startForeground(1, notification)
    }

    private fun showOverlay() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )

        drawingView = RectangleSelectionView(this)
        windowManager.addView(drawingView, layoutParams)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::drawingView.isInitialized) {
            windowManager.removeView(drawingView)
        }
    }

    class RectangleSelectionView(context: Context) : View(context) {
        private val paint = Paint().apply {
            color = Color.argb(150, 0, 0, 255) // Semi-transparent blue
            style = Paint.Style.STROKE
            strokeWidth = 5f
            isAntiAlias = true
        }

        private var startX = 0f
        private var startY = 0f
        private var endX = 0f
        private var endY = 0f
        private var isDrawing = false

        override fun onTouchEvent(event: MotionEvent): Boolean {
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startX = event.x
                    startY = event.y
                    endX = startX
                    endY = startY
                    isDrawing = true
                    invalidate()
                }
                MotionEvent.ACTION_MOVE -> {
                    endX = event.x
                    endY = event.y
                    invalidate()
                }
                MotionEvent.ACTION_UP -> {
                    endX = event.x
                    endY = event.y
                    isDrawing = false
                    invalidate()
                    // You can handle cropping or capturing the area here if needed
                }
            }
            return true
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            if (isDrawing || (startX != endX && startY != endY)) {
                val left = minOf(startX, endX)
                val top = minOf(startY, endY)
                val right = maxOf(startX, endX)
                val bottom = maxOf(startY, endY)
                canvas.drawRect(left, top, right, bottom, paint)
            }
        }
    }
}

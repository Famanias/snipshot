package com.example.snipshot

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class ScreenshotService : Service() {

    companion object {
        var resultCode: Int = 0
        var resultData: Intent? = null
    }

    private lateinit var projectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null

    private var cropStartX: Float = 0f
    private var cropStartY: Float = 0f
    private var cropEndX: Float = 0f
    private var cropEndY: Float = 0f

    override fun onCreate() {
        super.onCreate()
        startForeground(1, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        cropStartX = intent?.getFloatExtra("startX", 0f) ?: 0f
        cropStartY = intent?.getFloatExtra("startY", 0f) ?: 0f
        cropEndX = intent?.getFloatExtra("endX", 0f) ?: 0f
        cropEndY = intent?.getFloatExtra("endY", 0f) ?: 0f

        projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = projectionManager.getMediaProjection(resultCode, resultData!!)

        val metrics = DisplayMetrics()
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.defaultDisplay.getRealMetrics(metrics)

        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )

        imageReader?.setOnImageAvailableListener({
            val image = it.acquireLatestImage() ?: return@setOnImageAvailableListener

            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * width

            val bitmap = Bitmap.createBitmap(
                width + rowPadding / pixelStride,
                height, Bitmap.Config.ARGB_8888
            )
            bitmap.copyPixelsFromBuffer(buffer)

            image.close()

            // Crop the bitmap to selected rectangle
            val left = minOf(cropStartX, cropEndX).toInt().coerceAtLeast(0)
            val top = minOf(cropStartY, cropEndY).toInt().coerceAtLeast(0)
            val right = maxOf(cropStartX, cropEndX).toInt().coerceAtMost(bitmap.width)
            val bottom = maxOf(cropStartY, cropEndY).toInt().coerceAtMost(bitmap.height)

            val cropWidth = right - left
            val cropHeight = bottom - top

            if (cropWidth > 0 && cropHeight > 0) {
                val croppedBitmap = Bitmap.createBitmap(bitmap, left, top, cropWidth, cropHeight)
                saveBitmap(croppedBitmap)
            } else {
                // If invalid crop area, save full bitmap
                saveBitmap(bitmap)
            }

            stopSelf()

        }, null)

        return START_NOT_STICKY
    }

    private fun saveBitmap(bitmap: Bitmap) {
        val date = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val filePath = "${externalCacheDir?.absolutePath}/screenshot_$date.png"
        FileOutputStream(filePath).use { outputStream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            outputStream.flush()
        }
        Log.d("ScreenshotService", "Saved screenshot: $filePath")
    }

    private fun createNotification(): Notification {
        val channelId = "screenshot_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Screenshot Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return Notification.Builder(this, channelId)
            .setContentTitle("Taking Screenshot...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .build()
    }

    override fun onDestroy() {
        imageReader?.close()
        virtualDisplay?.release()
        mediaProjection?.stop()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

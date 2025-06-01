package com.example.snipshot

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle

class RequestScreenshotPermissionActivity : Activity() {

    companion object {
        const val SCREENSHOT_REQUEST_CODE = 1001
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val intent = projectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, SCREENSHOT_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == SCREENSHOT_REQUEST_CODE && resultCode == RESULT_OK && data != null) {
            ScreenshotService.resultCode = resultCode
            ScreenshotService.resultData = data

            val intent = Intent(this, ScreenshotService::class.java)
            startService(intent)
        }

        finish() // Close the activity
    }
}

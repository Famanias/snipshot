package com.example.snipshot

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.widget.Toast

class RequestScreenshotPermissionActivity : Activity() {

    companion object {
        const val SCREENSHOT_REQUEST_CODE = 1001
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Request screen capture permission from the user
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val captureIntent = projectionManager.createScreenCaptureIntent()
        startActivityForResult(captureIntent, SCREENSHOT_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SCREENSHOT_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                // Pass MediaProjection permission result to your service (or wherever you handle capture)
                ScreenshotService.resultCode = resultCode
                ScreenshotService.resultData = data

                // Start the screenshot/drawing overlay service
                val serviceIntent = Intent(this, ScreenshotService::class.java)
                startService(serviceIntent)

            } else {
                // User denied screen capture permission
                Toast.makeText(this, "Screen capture permission denied", Toast.LENGTH_SHORT).show()
            }
            // Close this permission activity after handling the result
            finish()
        }
    }
}

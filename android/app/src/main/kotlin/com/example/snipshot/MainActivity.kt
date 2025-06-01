package com.example.snipshot

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast

class MainActivity: FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        val action = intent.action
        if (action == "intent.bring.app.to.foreground") {
            // Instead of opening Flutter UI, start a native overlay or service
            Log.d("BubbleIntent", "Bubble clicked, starting overlay...")

            // TODO: Launch your custom drawing overlay activity or service
            val drawIntent = Intent(this, DrawingOverlayService::class.java)
            startService(drawIntent)

            // Optional: Don't show Flutter UI
            moveTaskToBack(true) // Push Flutter UI back to background
        }
    }
}
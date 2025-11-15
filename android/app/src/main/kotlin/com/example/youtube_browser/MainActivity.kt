package com.example.youtube_browser // use your app package

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "pip_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> {
                    enterPipMode()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val aspect = Rational(16, 9)
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(aspect)
                .build()
            try {
                enterPictureInPictureMode(params)
            } catch (e: Exception) {
                // ignore
            }
        }
    }

    override fun onUserLeaveHint() {
        // Called when user presses Home - optionally try to auto enter PiP
        // super.onUserLeaveHint()
    }
}

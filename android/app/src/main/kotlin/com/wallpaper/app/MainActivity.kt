package com.wallpaper.app

import android.app.WallpaperManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wallpaper.app/wallpaper"
    private val HOME_SCREEN = 1
    private val LOCK_SCREEN = 2
    private val BOTH_SCREENS = 3

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val path = call.argument<String>("path")
                val location = call.argument<Int>("location") ?: HOME_SCREEN

                if (path == null) {
                    result.success(
                        hashMapOf(
                            "success" to false,
                            "error" to "Path is required"
                        )
                    )
                    return@setMethodCallHandler
                }

                try {
                    val success = setWallpaperFromPath(path, location)
                    if (success) {
                        result.success(
                            hashMapOf("success" to true)
                        )
                    } else {
                        result.success(
                            hashMapOf(
                                "success" to false,
                                "error" to "Failed to set wallpaper"
                            )
                        )
                    }
                } catch (e: Exception) {
                    result.success(
                        hashMapOf(
                            "success" to false,
                            "error" to (e.message ?: "Unknown error")
                        )
                    )
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setWallpaperFromPath(path: String, location: Int): Boolean {
        val wallpaperManager = WallpaperManager.getInstance(this)
        val file = File(path)

        if (!file.exists()) {
            return false
        }

        var successCount = 0

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            if (location == HOME_SCREEN || location == BOTH_SCREENS) {
                try {
                    FileInputStream(file).use { inputStream ->
                        wallpaperManager.setStream(inputStream, null, true, WallpaperManager.FLAG_SYSTEM)
                    }
                    successCount++
                } catch (e: Exception) { }
            }

            if (location == LOCK_SCREEN || location == BOTH_SCREENS) {
                try {
                    FileInputStream(file).use { lockStream ->
                        wallpaperManager.setStream(lockStream, null, true, WallpaperManager.FLAG_LOCK)
                    }
                    successCount++
                } catch (e: Exception) { }
            }
        } else {
            try {
                FileInputStream(file).use { inputStream ->
                    wallpaperManager.setStream(inputStream)
                }
                successCount++
            } catch (e: Exception) { }
        }

        return successCount > 0
    }
}

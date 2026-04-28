package com.ai.anime.art.generator.photo.create.aiart

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ai.anime.art.generator.photo.create.aiart/splash"
    private val PREFS_NAME = "splash_theme_prefs"
    private val THEME_KEY = "splash_theme"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController?.let {
            it.hide(androidx.core.view.WindowInsetsCompat.Type.systemBars())
            it.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Đăng ký Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_small_image_bottom",
            GenericNativeAdFactory(context, R.layout.ad_native_small_image_bottom)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_small_image_top",
            GenericNativeAdFactory(context, R.layout.ad_native_small_image_top)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_small_no_image",
            GenericNativeAdFactory(context, R.layout.ad_native_small_no_image)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_small_image_bottom_2",
            GenericNativeAdFactory(context, R.layout.ad_native_small_image_bottom_2)
        )

        // Small styles from image
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_small_image_bottom_1",
            GenericNativeAdFactory(context, R.layout.ad_native_small_image_bottom_1)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_small_image_top_1",
            GenericNativeAdFactory(context, R.layout.ad_native_small_image_top_1)
        )
        // Medium styles from image
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_medium_image_bottom_1",
            GenericNativeAdFactory(context, R.layout.ad_native_medium_bottom_1)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_medium_video_bottom_1",
            GenericNativeAdFactory(context, R.layout.ad_native_medium_bottom_1)
        )
        // More styles from image
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_medium_image_bottom_2",
            GenericNativeAdFactory(context, R.layout.ad_native_medium_bottom_2)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_medium_video_bottom_2",
            GenericNativeAdFactory(context, R.layout.ad_native_medium_bottom_2)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_medium_image_top_2",
            GenericNativeAdFactory(context, R.layout.ad_native_medium_top_2)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_medium_video_top_2",
            GenericNativeAdFactory(context, R.layout.ad_native_medium_top_2)
        )
        // Card and box styles from image
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_card_right_1",
            GenericNativeAdFactory(context, R.layout.ad_native_card_right_1)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_card_bottom_1",
            GenericNativeAdFactory(context, R.layout.ad_native_card_bottom_1)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_box_bottom_1",
            GenericNativeAdFactory(context, R.layout.ad_native_box_bottom_1)
        )
        // Fullscreen styles from image
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_fullscreen_image_1",
            GenericNativeAdFactory(context, R.layout.ad_native_fullscreen_1)
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_fullscreen_video_1",
            GenericNativeAdFactory(context, R.layout.ad_native_fullscreen_1)
        )

        // Đăng ký Method Channel cho Splash Theme
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveTheme" -> {
                    val theme = call.argument<String>("theme")
                    if (theme != null) {
                        saveTheme(theme)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Theme argument is null", null)
                    }
                }
                "getTheme" -> {
                    val theme = getSavedTheme()
                    result.success(theme)
                }
                "restartApp" -> {
                    restartApp()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun saveTheme(theme: String) {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val success = prefs.edit().putString(THEME_KEY, theme).commit()
            android.util.Log.d("MainActivity", "💾 Saved theme: $theme, success: $success")
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Error saving theme: ${e.message}", e)
        }
    }

    private fun getSavedTheme(): String? {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val theme = prefs.getString(THEME_KEY, null)
            android.util.Log.d("MainActivity", "📖 Read theme from SharedPreferences: $theme")
            return theme
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "❌ Error reading theme: ${e.message}", e)
            return null
        }
    }

    private fun restartApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(it)
            finish()
            android.os.Process.killProcess(android.os.Process.myPid())
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "native_small_image_bottom")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "native_small_image_top")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "native_small_no_image")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_small_image_bottom_2"
        )

        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_small_image_bottom_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_small_image_top_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_medium_image_bottom_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_medium_video_bottom_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_medium_image_bottom_2"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_medium_video_bottom_2"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_medium_image_top_2"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_medium_video_top_2"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_card_right_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_card_bottom_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_box_bottom_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_fullscreen_image_1"
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "native_fullscreen_video_1"
        )
    }
}

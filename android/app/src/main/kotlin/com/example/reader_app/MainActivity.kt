package com.example.reader_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "reader_app/tts_background"
	private var wakeLock: PowerManager.WakeLock? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"setWakeLock" -> {
						val enabled = call.argument<Boolean>("enabled") ?: false
						setWakeLockEnabled(enabled)
						result.success(null)
					}
					"isIgnoringBatteryOptimizations" -> {
						result.success(isIgnoringBatteryOptimizations())
					}
					"requestIgnoreBatteryOptimizations" -> {
						requestIgnoreBatteryOptimizations()
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun isIgnoringBatteryOptimizations(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
		val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
		return powerManager.isIgnoringBatteryOptimizations(packageName)
	}

	private fun requestIgnoreBatteryOptimizations() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
		if (isIgnoringBatteryOptimizations()) return

		val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
			data = Uri.parse("package:$packageName")
		}
		startActivity(intent)
	}

	private fun setWakeLockEnabled(enabled: Boolean) {
		if (enabled) {
			if (wakeLock?.isHeld == true) return

			val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
			wakeLock = powerManager.newWakeLock(
				PowerManager.PARTIAL_WAKE_LOCK,
				"reader_app:TtsWakeLock"
			).apply {
				setReferenceCounted(false)
				acquire()
			}
			return
		}

		wakeLock?.let {
			if (it.isHeld) {
				it.release()
			}
		}
		wakeLock = null
	}

	override fun onDestroy() {
		setWakeLockEnabled(false)
		super.onDestroy()
	}
}

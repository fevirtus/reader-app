package com.example.reader_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.reader_app.tts.ReaderSleepTimer
import com.example.reader_app.tts.ReaderTtsMediaBridge
import com.example.reader_app.tts.ReaderTtsMediaService
import com.example.reader_app.tts.ReaderTtsStartRequest

class MainActivity : AudioServiceActivity() {
	private val channelName = "reader_app/tts_background"
	private val mediaChannelName = "reader_app/tts_media"
	private val mediaEventsChannelName = "reader_app/tts_media_events"
	private var wakeLock: PowerManager.WakeLock? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "reader_app/sleep_timer")
            .setMethodCallHandler { call, result ->
                if (call.method == "set") {
                    val milliseconds = call.argument<Number>("milliseconds")?.toLong()
                    if (milliseconds != null && (milliseconds <= 0 || milliseconds > 86_400_000L)) {
                        result.error("invalid_duration", "Invalid sleep timer duration", null)
                    } else {
                        ReaderSleepTimer.set(this, milliseconds)
                        result.success(null)
                    }
                } else result.notImplemented()
            }


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

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"initialize" -> {
						val enabled = call.argument<Boolean>("backgroundModeEnabled") ?: true
						ReaderTtsMediaService.initialize(this, enabled)
						result.success(ReaderTtsMediaBridge.snapshot())
					}
					"getApplicationId" -> result.success(packageName)
					"getSnapshot" -> result.success(ReaderTtsMediaBridge.snapshot())
					"startReading" -> {
						val content = call.argument<String>("content") ?: ""
						val contentKey = call.argument<String>("contentKey")
						val title = call.argument<String>("title")
						val speed = call.argument<Double>("speed") ?: 0.9
						val language = call.argument<String>("language") ?: "vi-VN"
						val voiceName = call.argument<String>("voiceName")
						val backgroundModeEnabled = call.argument<Boolean>("backgroundModeEnabled") ?: true
						val nextChapterId = call.argument<String>("nextChapterId")
						val chapterNumber = call.argument<Int>("chapterNumber")
						val includeTitle = call.argument<Boolean>("includeTitle") ?: true
						val apiBaseUrl = call.argument<String>("apiBaseUrl")
						val startIndex = call.argument<Int>("startIndex") ?: 0
						val started = ReaderTtsMediaService.startReading(
							this,
							ReaderTtsStartRequest(
								content = content,
								contentKey = contentKey,
								title = title,
								speed = speed,
								language = language,
								voiceName = voiceName,
								backgroundModeEnabled = backgroundModeEnabled,
								nextChapterId = nextChapterId,
								chapterNumber = chapterNumber,
								includeTitle = includeTitle,
								apiBaseUrl = apiBaseUrl,
								startIndex = startIndex,
							),
						)
						if (started) result.success(null)
						else result.error("tts_start_failed", "Không khởi động được dịch vụ đọc", null)
					}
					"pause" -> {
						ReaderTtsMediaService.pause(this)
						result.success(null)
					}
					"resume" -> {
						ReaderTtsMediaService.resume(this)
						result.success(null)
					}
					"stop" -> {
						ReaderTtsMediaService.stop(this)
						result.success(null)
					}
					"skipForward" -> {
						ReaderTtsMediaService.skipForward(this)
						result.success(null)
					}
					"skipBack" -> {
						ReaderTtsMediaService.skipBack(this)
						result.success(null)
					}
					"setSpeed" -> {
						val speed = call.argument<Double>("speed") ?: 0.9
						ReaderTtsMediaService.setSpeed(this, speed)
						result.success(null)
					}
					"setVoiceByName" -> {
						ReaderTtsMediaService.setVoice(
							this,
							call.argument<String>("voiceName"),
							call.argument<String>("language"),
						)
						result.success(null)
					}
					"setBackgroundModeEnabled" -> {
						val enabled = call.argument<Boolean>("enabled") ?: true
						ReaderTtsMediaService.setBackgroundModeEnabled(this, enabled)
						result.success(null)
					}
					"areNotificationsEnabled" -> {
						result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())
					}
					"openNotificationSettings" -> {
						openNotificationSettings()
						result.success(null)
					}
					"dispose" -> result.success(null)
					else -> result.notImplemented()
				}
			}

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, mediaEventsChannelName)
			.setStreamHandler(
				object : EventChannel.StreamHandler {
					override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
						ReaderTtsMediaBridge.attachSink(events)
					}

					override fun onCancel(arguments: Any?) {
						ReaderTtsMediaBridge.detachSink()
					}
				},
			)
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

	private fun openNotificationSettings() {
		val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
				putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
			}
		} else {
			Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
				data = Uri.fromParts("package", packageName, null)
			}
		}
		startActivity(intent)
	}

	override fun onDestroy() {
		setWakeLockEnabled(false)
		super.onDestroy()
	}
}

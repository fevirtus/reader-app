package com.example.reader_app.tts

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Parcelable
import android.os.PowerManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.media.app.NotificationCompat.MediaStyle
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import com.example.reader_app.R
import kotlinx.parcelize.Parcelize
import kotlin.math.min
import java.util.Locale

@Parcelize
data class ReaderTtsSegment(
	val text: String,
	val paragraphIndex: Int,
	val start: Int,
	val end: Int,
) : Parcelable

class ReaderTtsMediaService : Service(), TextToSpeech.OnInitListener {
	companion object {
		private const val NOTIFICATION_ID = 46021
		private const val CHANNEL_ID = "reader_tts_playback"
		private const val CHANNEL_NAME = "Reader TTS"
		private const val BASE_SPEED = 0.9
		private const val TAG = "ReaderTtsMediaService"
		private const val HEALTH_CHECK_INTERVAL_MS = 1500L
		private const val START_GRACE_PERIOD_MS = 5_000L
		private const val MAX_SEGMENT_RETRIES_BEFORE_SKIP = 4

		const val ACTION_INIT = "com.example.reader_app.tts.INIT"
		const val ACTION_START_READING = "com.example.reader_app.tts.START_READING"
		const val ACTION_PAUSE = "com.example.reader_app.tts.PAUSE"
		const val ACTION_RESUME = "com.example.reader_app.tts.RESUME"
		const val ACTION_STOP = "com.example.reader_app.tts.STOP"
		const val ACTION_SKIP_FORWARD = "com.example.reader_app.tts.SKIP_FORWARD"
		const val ACTION_SKIP_BACK = "com.example.reader_app.tts.SKIP_BACK"
		const val ACTION_SET_SPEED = "com.example.reader_app.tts.SET_SPEED"
		const val ACTION_SET_VOICE = "com.example.reader_app.tts.SET_VOICE"
		const val ACTION_SET_BACKGROUND_MODE = "com.example.reader_app.tts.SET_BACKGROUND_MODE"

		const val EXTRA_SEGMENTS = "segments"
		const val EXTRA_START_INDEX = "startIndex"
		const val EXTRA_CONTENT_KEY = "contentKey"
		const val EXTRA_TITLE = "title"
		const val EXTRA_SPEED = "speed"
		const val EXTRA_LANGUAGE = "language"
		const val EXTRA_VOICE_NAME = "voiceName"
		const val EXTRA_BACKGROUND_MODE_ENABLED = "backgroundModeEnabled"
		const val EXTRA_CLEAR_CONTENT_KEY = "clearContentKey"
		const val EXTRA_STOP_REASON = "stopReason"
		private const val STOP_REASON_USER = "user"

		fun initialize(context: Context, backgroundModeEnabled: Boolean) {
			context.startService(
				Intent(context, ReaderTtsMediaService::class.java).apply {
					action = ACTION_INIT
					putExtra(EXTRA_BACKGROUND_MODE_ENABLED, backgroundModeEnabled)
				},
			)
		}

		fun startReading(
			context: Context,
			segments: ArrayList<ReaderTtsSegment>,
			startIndex: Int,
			contentKey: String?,
			title: String?,
			speed: Double,
			language: String,
			voiceName: String?,
			backgroundModeEnabled: Boolean,
		) {
			ContextCompat.startForegroundService(
				context,
				Intent(context, ReaderTtsMediaService::class.java).apply {
					action = ACTION_START_READING
					putParcelableArrayListExtra(EXTRA_SEGMENTS, segments)
					putExtra(EXTRA_START_INDEX, startIndex)
					putExtra(EXTRA_CONTENT_KEY, contentKey)
					putExtra(EXTRA_TITLE, title)
					putExtra(EXTRA_SPEED, speed)
					putExtra(EXTRA_LANGUAGE, language)
					putExtra(EXTRA_VOICE_NAME, voiceName)
					putExtra(EXTRA_BACKGROUND_MODE_ENABLED, backgroundModeEnabled)
				},
			)
		}

		fun pause(context: Context) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_PAUSE
			})

		fun resume(context: Context) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_RESUME
			})

		fun stop(context: Context, clearContentKey: Boolean = true) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_STOP
				putExtra(EXTRA_CLEAR_CONTENT_KEY, clearContentKey)
				putExtra(EXTRA_STOP_REASON, STOP_REASON_USER)
			})

		fun skipForward(context: Context) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_SKIP_FORWARD
			})

		fun skipBack(context: Context) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_SKIP_BACK
			})

		fun setSpeed(context: Context, speed: Double) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_SET_SPEED
				putExtra(EXTRA_SPEED, speed)
			})

		fun setVoice(context: Context, voiceName: String?, language: String?) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_SET_VOICE
				putExtra(EXTRA_VOICE_NAME, voiceName)
				putExtra(EXTRA_LANGUAGE, language)
			})

		fun setBackgroundModeEnabled(context: Context, enabled: Boolean) =
			context.startService(Intent(context, ReaderTtsMediaService::class.java).apply {
				action = ACTION_SET_BACKGROUND_MODE
				putExtra(EXTRA_BACKGROUND_MODE_ENABLED, enabled)
			})
	}

	private val mainHandler = Handler(Looper.getMainLooper())
	private lateinit var notificationManager: NotificationManagerCompat
	private lateinit var mediaSession: MediaSessionCompat
	private lateinit var audioManager: AudioManager
	private lateinit var powerManager: PowerManager
	private var audioFocusRequest: AudioFocusRequest? = null
	private var wakeLock: PowerManager.WakeLock? = null
	private var tts: TextToSpeech? = null
	private var isTtsReady = false
	private var isForegroundActive = false
	private var status = "idle"
	private var speed = 0.9
	private var language = "vi-VN"
	private var voiceName: String? = null
	private var contentKey: String? = null
	private var title: String? = null
	private var segments: List<ReaderTtsSegment> = emptyList()
	private var currentIndex = 0
	private var completedCount = 0
	private var backgroundModeEnabled = true
	private var availableVoices: List<Map<String, String>> = emptyList()
	private var sessionGeneration = 0
	private var lastStartedUtterance: String? = null
	private var currentUtteranceId: String? = null
	private var currentUtteranceStarted = false
	private var pendingReplayAfterInit = false
	private var isRebuildingEngine = false
	private var engineRebuildAttempt = 0
	private var audioFocusRetryAttempt = 0
	private var consecutivePlaybackRecoveryFailures = 0
	private var pendingEngineRebuild: Runnable? = null
	private var pendingAudioFocusRetry: Runnable? = null
	private var pendingIdleStop: Runnable? = null
	private var currentSegmentRetry = 0
	private var consecutiveSilentHealthChecks = 0
	private var utteranceWatchdog: Runnable? = null
	private var pausedByAudioFocus = false
	private var lastSpeakRequestTimeMs = 0L
	private val playbackHealthRunnable = object : Runnable {
		override fun run() {
			runPlaybackHealthCheck()
			mainHandler.postDelayed(this, HEALTH_CHECK_INTERVAL_MS)
		}
	}

	private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
		mainHandler.post {
			when (focusChange) {
				AudioManager.AUDIOFOCUS_LOSS,
				AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
					if (status == "playing") {
						pausedByAudioFocus = true
						handlePause()
					}
				}
				AudioManager.AUDIOFOCUS_GAIN -> {
					if (pausedByAudioFocus && status == "paused") {
						pausedByAudioFocus = false
						handleResume()
					}
				}
			}
		}
	}

	override fun onCreate() {
		super.onCreate()
		notificationManager = NotificationManagerCompat.from(this)
		audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
		powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
		createNotificationChannel()
		setupMediaSession()
		setupTextToSpeech()
		mainHandler.postDelayed(playbackHealthRunnable, HEALTH_CHECK_INTERVAL_MS)
		publishSnapshot()
	}

	override fun onBind(intent: Intent?): IBinder? = null

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		Log.i(TAG, "onStartCommand action=${intent?.action} status=$status index=$currentIndex")
		when (intent?.action) {
			ACTION_INIT -> {
				backgroundModeEnabled = intent.getBooleanExtra(
					EXTRA_BACKGROUND_MODE_ENABLED,
					backgroundModeEnabled,
				)
				publishSnapshot()
			}
			ACTION_START_READING -> handleStartReading(intent)
			ACTION_PAUSE -> handlePause()
			ACTION_RESUME -> handleResume()
			ACTION_STOP -> handleStop(
				clearContentKey = intent.getBooleanExtra(EXTRA_CLEAR_CONTENT_KEY, true),
				reason = intent.getStringExtra(EXTRA_STOP_REASON) ?: "unknown",
			)
			ACTION_SKIP_FORWARD -> handleSkip(1)
			ACTION_SKIP_BACK -> handleSkip(-1)
			ACTION_SET_SPEED -> {
				speed = intent.getDoubleExtra(EXTRA_SPEED, speed)
				applyVoiceAndSpeedSettings()
				publishSnapshot()
			}
			ACTION_SET_VOICE -> {
				voiceName = intent.getStringExtra(EXTRA_VOICE_NAME)
				language = intent.getStringExtra(EXTRA_LANGUAGE) ?: language
				applyVoiceAndSpeedSettings()
				publishSnapshot()
			}
			ACTION_SET_BACKGROUND_MODE -> {
				backgroundModeEnabled = intent.getBooleanExtra(
					EXTRA_BACKGROUND_MODE_ENABLED,
					backgroundModeEnabled,
				)
				syncNotificationState()
				publishSnapshot()
			}
		}

		return START_STICKY
	}

	private fun setupTextToSpeech() {
		tts = TextToSpeech(applicationContext, this)
		tts?.setOnUtteranceProgressListener(
			object : UtteranceProgressListener() {
				override fun onStart(utteranceId: String?) {
					if (utteranceId == null) return
					mainHandler.post {
						if (!isActiveUtterance(utteranceId)) return@post
						if (utteranceId != currentUtteranceId) return@post
						lastStartedUtterance = utteranceId
						currentUtteranceStarted = true
						currentSegmentRetry = 0
						status = "playing"
						scheduleUtteranceWatchdog(utteranceId)
						syncNotificationState()
						publishSnapshot()
					}
				}

				override fun onDone(utteranceId: String?) {
					if (utteranceId == null) return
					mainHandler.post {
						if (!isActiveUtterance(utteranceId)) return@post
						if (utteranceId != currentUtteranceId) return@post
						clearUtteranceRuntimeState()
						handleUtteranceCompleted(parseUtteranceIndex(utteranceId))
					}
				}

				@Deprecated("Deprecated in Java")
				override fun onError(utteranceId: String?) {
					onError(utteranceId, TextToSpeech.ERROR)
				}

				override fun onError(utteranceId: String?, errorCode: Int) {
					if (utteranceId == null) return
					mainHandler.post {
						if (!isActiveUtterance(utteranceId)) return@post
						if (utteranceId != currentUtteranceId) return@post
						clearUtteranceRuntimeState()
						// ERROR_SERVICE (-6) means the TTS engine process disconnected.
						// Rebuild the engine immediately rather than retrying on a dead instance.
						if (errorCode == TextToSpeech.ERROR_SERVICE ||
							errorCode == TextToSpeech.ERROR_NOT_INSTALLED_YET) {
							rebuildTtsEngineForRecovery("utterance_error_$errorCode")
						} else {
							recoverFromSilentPlayback("utterance_error_$errorCode")
						}
					}
				}
			},
		)
	}

	override fun onInit(initStatus: Int) {
		isRebuildingEngine = false
		isTtsReady = initStatus == TextToSpeech.SUCCESS
		if (isTtsReady) {
			engineRebuildAttempt = 0
			consecutivePlaybackRecoveryFailures = 0
			currentSegmentRetry = 0  // reset retry counter after successful engine reconnect
			refreshAvailableVoices()
			applyVoiceAndSpeedSettings()
			if ((pendingReplayAfterInit || status == "playing") && segments.isNotEmpty()) {
				pendingReplayAfterInit = false
				speakCurrentSegment(forceRestart = true)
			}
		} else {
			if (status == "playing" || pendingReplayAfterInit || segments.isNotEmpty()) {
				status = "paused"
				scheduleEngineRebuild("onInit_failed_$initStatus")
			} else {
				status = "idle"
			}
		}
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
	}

	private fun refreshAvailableVoices() {
		val ttsInstance = tts ?: return
		val vietnameseVoices = ttsInstance.voices
			?.filter { voice -> voice.locale?.toLanguageTag()?.lowercase()?.startsWith("vi") == true }
			?.mapNotNull { voice ->
				val locale = voice.locale?.toLanguageTag() ?: return@mapNotNull null
				mapOf("name" to voice.name, "locale" to locale)
			}
			.orEmpty()
			.distinctBy { voice -> "${voice["name"]}:${voice["locale"]}" }
			.sortedBy { voice -> voice["name"] }

		availableVoices = vietnameseVoices
		if (voiceName.isNullOrBlank()) {
			val preferred = vietnameseVoices.firstOrNull { voice ->
				val normalized = voice["name"]?.lowercase().orEmpty()
				normalized.contains("female") || normalized.contains("natural")
			} ?: vietnameseVoices.firstOrNull()
			voiceName = preferred?.get("name")
			language = preferred?.get("locale") ?: language
		}
	}

	private fun applyVoiceAndSpeedSettings() {
		val ttsInstance = tts ?: return
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
			ttsInstance.setAudioAttributes(
				AudioAttributes.Builder()
					.setUsage(AudioAttributes.USAGE_MEDIA)
					.setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
					.build(),
			)
		}
		ttsInstance.setSpeechRate(speed.toFloat())
		val locale = language.toLocale()
		ttsInstance.setLanguage(locale)
		val matchingVoice = ttsInstance.voices?.firstOrNull { voice ->
			voice.name == voiceName && voice.locale?.toLanguageTag() == language
		}
		if (matchingVoice != null) {
			ttsInstance.voice = matchingVoice
		}
	}

	private fun handleStartReading(intent: Intent) {
		cancelIdleStop()
		backgroundModeEnabled = intent.getBooleanExtra(
			EXTRA_BACKGROUND_MODE_ENABLED,
			backgroundModeEnabled,
		)
		speed = intent.getDoubleExtra(EXTRA_SPEED, speed)
		language = intent.getStringExtra(EXTRA_LANGUAGE) ?: language
		voiceName = intent.getStringExtra(EXTRA_VOICE_NAME)
		contentKey = intent.getStringExtra(EXTRA_CONTENT_KEY)
		title = intent.getStringExtra(EXTRA_TITLE)
		segments = extractSegments(intent)
		currentIndex = intent.getIntExtra(EXTRA_START_INDEX, 0)
			.coerceIn(0, (segments.size - 1).coerceAtLeast(0))
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		status = "playing"
		pausedByAudioFocus = false
		pendingReplayAfterInit = false
		tts?.stop()
		syncPowerState()
		publishSnapshot()

		if (!isTtsReady) return
		speakCurrentSegment(forceRestart = true)
	}

	private fun handlePause() {
		if (status != "playing") return
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		status = "paused"
		pendingReplayAfterInit = false
		tts?.stop()
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
	}

	private fun handleResume() {
		if (segments.isEmpty()) return
		cancelIdleStop()
		status = "playing"
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		pendingReplayAfterInit = false
		syncPowerState()
		publishSnapshot()
		if (!isTtsReady) return
		speakCurrentSegment(forceRestart = true)
	}

	private fun handleStop(clearContentKey: Boolean, reason: String) {
		Log.i(TAG, "handleStop reason=$reason clearContentKey=$clearContentKey")
		sessionGeneration += 1
		clearScheduledRecoveries()
		cancelIdleStop()
		clearUtteranceRuntimeState()
		status = "idle"
		currentIndex = 0
		segments = emptyList()
		title = null
		if (clearContentKey) {
			contentKey = null
		}
		tts?.stop()
		abandonAudioFocus()
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
		stopSelf()
	}

	private fun handleSkip(direction: Int) {
		if (segments.isEmpty()) return
		val nextIndex = (currentIndex + direction).coerceIn(0, segments.lastIndex)
		if (nextIndex == currentIndex && status == "idle") return
		currentIndex = nextIndex
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		status = "playing"
		pendingReplayAfterInit = false
		tts?.stop()
		syncPowerState()
		publishSnapshot()
		if (!isTtsReady) return
		speakCurrentSegment(forceRestart = true)
	}

	private fun handleUtteranceCompleted(completedIndex: Int) {
		if (status != "playing") return
		if (completedIndex != currentIndex) return

		val nextIndex = currentIndex + 1
		if (nextIndex >= segments.size) {
			status = "idle"
			currentIndex = 0
			completedCount += 1
			Log.i(TAG, "chapter_completed contentKey=$contentKey completedCount=$completedCount")
			clearUtteranceRuntimeState()
			abandonAudioFocus()
			syncPowerState()
			syncNotificationState()
			publishSnapshot()
			scheduleIdleStop()
			return
		}

		currentIndex = nextIndex
		speakCurrentSegment(forceRestart = false)
	}

	private fun handlePlaybackFailure() {
		consecutivePlaybackRecoveryFailures += 1
		Log.e(
			TAG,
			"Playback failure at index=$currentIndex contentKey=$contentKey, recoveryAttempt=$consecutivePlaybackRecoveryFailures",
		)
		status = "paused"
		pendingReplayAfterInit = true
		if (consecutivePlaybackRecoveryFailures > 12) {
			// Keep trying indefinitely but avoid a tight error loop.
			consecutivePlaybackRecoveryFailures = 6
		}
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
		scheduleEngineRebuild("playback_failure")
	}

	private fun speakCurrentSegment(forceRestart: Boolean) {
		if (segments.isEmpty() || !isTtsReady) return
		if (!requestAudioFocus()) {
			pausedByAudioFocus = true
			status = "paused"
			syncPowerState()
			syncNotificationState()
			publishSnapshot()
			scheduleAudioFocusRetry()
			return
		}
		clearAudioFocusRetry()

		val segment = segments.getOrNull(currentIndex) ?: run {
			handlePlaybackFailure()
			return
		}

		applyVoiceAndSpeedSettings()
		status = "playing"
		// Reset retry counter when advancing to a new segment; keep it when retrying same segment.
		if (!forceRestart) {
			currentSegmentRetry = 0
		}
		syncPowerState()
		syncNotificationState()
		publishSnapshot()

		val utteranceId = "${sessionGeneration}:${currentIndex}:${System.nanoTime()}"
		lastStartedUtterance = if (forceRestart) null else lastStartedUtterance
		currentUtteranceId = utteranceId
		currentUtteranceStarted = false
		lastSpeakRequestTimeMs = System.currentTimeMillis()
		scheduleUtteranceWatchdog(utteranceId)
		val speakResult = try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
				tts?.speak(segment.text, TextToSpeech.QUEUE_FLUSH, Bundle(), utteranceId)
			} else {
				@Suppress("DEPRECATION")
				tts?.speak(segment.text, TextToSpeech.QUEUE_FLUSH, null)
			}
		} catch (e: Exception) {
			Log.e(TAG, "speak() failed for index=$currentIndex", e)
			null
		}

		if (speakResult == null || speakResult == TextToSpeech.ERROR) {
			// speak() returning ERROR/null almost always means the TTS engine process died
			// (visible in logcat as "Disconnected from TTS engine").
			// Rebuild immediately instead of burning 3 retries on a dead engine.
			if (!isRebuildingEngine) {
				rebuildTtsEngineForRecovery("speak_error_or_null")
			}
		}
	}

	private fun scheduleUtteranceWatchdog(utteranceId: String) {
		clearUtteranceWatchdog()
		val segment = currentSegment() ?: return
		val timeoutMs = estimateUtteranceTimeoutMs(segment.text)
		val guard = Runnable {
			if (status != "playing") return@Runnable
			if (utteranceId != currentUtteranceId) return@Runnable
			recoverFromSilentPlayback("watchdog_timeout")
		}
		utteranceWatchdog = guard
		mainHandler.postDelayed(guard, timeoutMs)
	}

	private fun clearUtteranceWatchdog() {
		utteranceWatchdog?.let(mainHandler::removeCallbacks)
		utteranceWatchdog = null
	}

	private fun clearUtteranceRuntimeState() {
		clearUtteranceWatchdog()
		lastStartedUtterance = null
		currentUtteranceId = null
		currentUtteranceStarted = false
		consecutiveSilentHealthChecks = 0
	}

	private fun estimateUtteranceTimeoutMs(text: String): Long {
		val safeSpeed = speed.coerceIn(0.2, 1.5)
		val multiplier = (BASE_SPEED / safeSpeed).coerceIn(0.5, 3.0)
		// Use 200ms/char (was 90ms) and a larger 10s buffer so the watchdog does not
		// fire prematurely for longer Vietnamese sentences (e.g. ~150 chars ≈ 17 s at 0.9×).
		val estimate = (text.length * 200L * multiplier).toLong() + 10_000L
		return estimate.coerceIn(15_000L, 180_000L)
	}

	private fun recoverFromSilentPlayback(reason: String) {
		if (status != "playing") return
		Log.w(TAG, "Recover from silent playback: $reason (index=$currentIndex retry=$currentSegmentRetry)")
		if (segments.isEmpty()) {
			handlePlaybackFailure()
			return
		}

		clearUtteranceRuntimeState()
		if (currentSegmentRetry >= MAX_SEGMENT_RETRIES_BEFORE_SKIP) {
			skipCurrentSegmentAfterFailure(reason)
			return
		}

		currentSegmentRetry += 1
		if (currentSegmentRetry >= 3) {
			rebuildTtsEngineForRecovery(reason)
			return
		}

		tts?.stop()
		speakCurrentSegment(forceRestart = true)
	}

	private fun rebuildTtsEngineForRecovery(reason: String) {
		if (isRebuildingEngine) {
			Log.w(TAG, "Rebuild already in progress, skipping: $reason")
			return
		}
		Log.w(TAG, "Rebuilding TextToSpeech engine for recovery: $reason")
		isRebuildingEngine = true
		pendingReplayAfterInit = true
		isTtsReady = false
		clearScheduledRecoveries()
		// Increment session so callbacks from the dying engine are ignored
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		tts?.stop()
		tts?.shutdown()
		tts = null
		setupTextToSpeech()
	}

	private fun skipCurrentSegmentAfterFailure(reason: String) {
		Log.e(
			TAG,
			"Skipping problematic segment after repeated recovery failures: reason=$reason index=$currentIndex total=${segments.size}",
		)
		clearUtteranceRuntimeState()
		pendingReplayAfterInit = false

		val nextIndex = currentIndex + 1
		if (nextIndex >= segments.size) {
			handlePlaybackFailure()
			return
		}

		currentIndex = nextIndex
		currentSegmentRetry = 0
		publishSnapshot()
		if (!isTtsReady) {
			rebuildTtsEngineForRecovery("skip_after_failure")
			return
		}
		speakCurrentSegment(forceRestart = false)
	}

	private fun runPlaybackHealthCheck() {
		if (status != "playing") return
		if (segments.isEmpty()) return

		val ttsInstance = tts
		if (ttsInstance == null) {
			rebuildTtsEngineForRecovery("tts_instance_null")
			return
		}

		if (!isTtsReady) {
			if (!pendingReplayAfterInit && !isRebuildingEngine) {
				rebuildTtsEngineForRecovery("tts_not_ready")
			}
			return
		}

		val isSpeaking = try {
			ttsInstance.isSpeaking
		} catch (_: Exception) {
			false
		}

		if (!currentUtteranceStarted) {
			if (!isSpeaking) {
				// Allow a grace period after speak() is called before flagging as silent.
				// Some engines on mid/low-end devices need noticeably longer before
				// firing onStart after many segments or after screen-off transitions.
				val elapsedSinceSpeak = System.currentTimeMillis() - lastSpeakRequestTimeMs
				if (elapsedSinceSpeak > START_GRACE_PERIOD_MS) {
					recoverFromSilentPlayback("no_onStart_and_not_speaking")
				}
			}
			return
		}

		if (isSpeaking) {
			consecutiveSilentHealthChecks = 0
			return
		}

		consecutiveSilentHealthChecks += 1
		if (consecutiveSilentHealthChecks < 2) {
			return
		}

		// Engine stopped speaking but onDone was never delivered; advance manually.
		consecutiveSilentHealthChecks = 0
		clearUtteranceRuntimeState()
		handleUtteranceCompleted(currentIndex)
	}

	private fun requestAudioFocus(): Boolean {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val request = audioFocusRequest
				?: AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
					.setAudioAttributes(
						AudioAttributes.Builder()
							.setUsage(AudioAttributes.USAGE_MEDIA)
							.setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
							.build(),
					)
					.setAcceptsDelayedFocusGain(true)
					.setOnAudioFocusChangeListener(audioFocusListener)
					.build()
					.also { audioFocusRequest = it }
			val result = audioManager.requestAudioFocus(request)
			result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
		} else {
			@Suppress("DEPRECATION")
			audioManager.requestAudioFocus(
				audioFocusListener,
				AudioManager.STREAM_MUSIC,
				AudioManager.AUDIOFOCUS_GAIN,
			) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
		}
	}

	private fun scheduleEngineRebuild(reason: String) {
		if (isRebuildingEngine) return
		pendingEngineRebuild?.let(mainHandler::removeCallbacks)
		engineRebuildAttempt += 1
		val delayMs = min(30_000L, 1_000L * engineRebuildAttempt * engineRebuildAttempt)
		pendingEngineRebuild = Runnable {
			if (status == "idle") return@Runnable
			if (segments.isEmpty()) return@Runnable
			rebuildTtsEngineForRecovery(reason)
		}.also { mainHandler.postDelayed(it, delayMs) }
	}

	private fun scheduleAudioFocusRetry() {
		pendingAudioFocusRetry?.let(mainHandler::removeCallbacks)
		audioFocusRetryAttempt += 1
		val delayMs = min(6_000L, 1_000L + (audioFocusRetryAttempt * 500L))
		pendingAudioFocusRetry = Runnable {
			if (status == "idle") return@Runnable
			if (!pausedByAudioFocus) return@Runnable
			if (requestAudioFocus()) {
				pausedByAudioFocus = false
				audioFocusRetryAttempt = 0
				handleResume()
				return@Runnable
			}
			scheduleAudioFocusRetry()
		}.also { mainHandler.postDelayed(it, delayMs) }
	}

	private fun clearAudioFocusRetry() {
		pendingAudioFocusRetry?.let(mainHandler::removeCallbacks)
		pendingAudioFocusRetry = null
		audioFocusRetryAttempt = 0
	}

	private fun clearScheduledRecoveries() {
		pendingEngineRebuild?.let(mainHandler::removeCallbacks)
		pendingEngineRebuild = null
		clearAudioFocusRetry()
	}

	private fun scheduleIdleStop() {
		pendingIdleStop?.let(mainHandler::removeCallbacks)
		pendingIdleStop = Runnable {
			if (status != "idle") return@Runnable
			Log.i(TAG, "idle_timeout_stop")
			stopSelf()
		}.also { mainHandler.postDelayed(it, 30_000L) }
	}

	private fun cancelIdleStop() {
		pendingIdleStop?.let(mainHandler::removeCallbacks)
		pendingIdleStop = null
	}

	private fun abandonAudioFocus() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			audioFocusRequest?.let(audioManager::abandonAudioFocusRequest)
		} else {
			@Suppress("DEPRECATION")
			audioManager.abandonAudioFocus(audioFocusListener)
		}
	}

	private fun syncPowerState() {
		val shouldHoldWakeLock = backgroundModeEnabled && status == "playing"
		if (shouldHoldWakeLock) {
			if (wakeLock?.isHeld == true) return
			wakeLock = powerManager.newWakeLock(
				PowerManager.PARTIAL_WAKE_LOCK,
				"reader_app:ReaderTtsPlayback"
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

	private fun isActiveUtterance(utteranceId: String): Boolean {
		val generation = utteranceId.substringBefore(':').toIntOrNull() ?: return false
		return generation == sessionGeneration
	}

	private fun parseUtteranceIndex(utteranceId: String): Int {
		val parts = utteranceId.split(':')
		return parts.getOrNull(1)?.toIntOrNull() ?: currentIndex
	}

	private fun currentSegment(): ReaderTtsSegment? = segments.getOrNull(currentIndex)

	private fun currentProgressLabel(): String {
		if (segments.isEmpty()) return voiceName ?: language
		return "Câu ${currentIndex + 1}/${segments.size}"
	}

	private fun appLabel(): String = applicationInfo.loadLabel(packageManager).toString()

	private fun buildLaunchIntent(): PendingIntent? {
		val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
			flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
		}
		return launchIntent?.let {
			PendingIntent.getActivity(
				this,
				100,
				it,
				PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
			)
		}
	}

	private fun buildServicePendingIntent(action: String): PendingIntent {
		return PendingIntent.getService(
			this,
			action.hashCode(),
			Intent(this, ReaderTtsMediaService::class.java).apply {
				this.action = action
				if (action == ACTION_STOP) {
					putExtra(EXTRA_CLEAR_CONTENT_KEY, true)
					putExtra(EXTRA_STOP_REASON, STOP_REASON_USER)
				}
			},
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
		)
	}

	@SuppressLint("MissingPermission")
	private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
		.setSmallIcon(R.mipmap.ic_launcher)
		.setContentTitle(title ?: appLabel())
		.setContentText(currentProgressLabel())
		.setContentIntent(buildLaunchIntent())
		.setOnlyAlertOnce(true)
		.setOngoing(status == "playing" || status == "paused")
		.setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
		.setCategory(NotificationCompat.CATEGORY_TRANSPORT)
		.addAction(
			android.R.drawable.ic_media_previous,
			"Lùi câu",
			buildServicePendingIntent(ACTION_SKIP_BACK),
		)
		.addAction(
			if (status == "playing") android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
			if (status == "playing") "Tạm dừng" else "Tiếp tục",
			buildServicePendingIntent(if (status == "playing") ACTION_PAUSE else ACTION_RESUME),
		)
		.addAction(
			android.R.drawable.ic_menu_close_clear_cancel,
			"Dừng",
			buildServicePendingIntent(ACTION_STOP),
		)
		.addAction(
			android.R.drawable.ic_media_next,
			"Tới câu",
			buildServicePendingIntent(ACTION_SKIP_FORWARD),
		)
		.setStyle(
			MediaStyle()
				.setMediaSession(mediaSession.sessionToken)
				.setShowActionsInCompactView(0, 1, 3),
		)
		.build()

	private fun setupMediaSession() {
		mediaSession = MediaSessionCompat(this, "ReaderTtsMediaSession")
		mediaSession.setCallback(
			object : MediaSessionCompat.Callback() {
				override fun onPlay() = handleResume()
				override fun onPause() = handlePause()
				override fun onStop() = handleStop(clearContentKey = true, reason = STOP_REASON_USER)
				override fun onSkipToNext() = handleSkip(1)
				override fun onSkipToPrevious() = handleSkip(-1)
			},
		)
		mediaSession.isActive = true
		updateMediaSessionState()
	}

	private fun updateMediaSessionState() {
		val playbackState = when (status) {
			"playing" -> PlaybackStateCompat.STATE_PLAYING
			"paused" -> PlaybackStateCompat.STATE_PAUSED
			else -> PlaybackStateCompat.STATE_STOPPED
		}
		val actions = PlaybackStateCompat.ACTION_PLAY or
			PlaybackStateCompat.ACTION_PAUSE or
			PlaybackStateCompat.ACTION_STOP or
			PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
			PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS

		mediaSession.setPlaybackState(
			PlaybackStateCompat.Builder()
				.setActions(actions)
				.setState(playbackState, currentIndex.toLong(), 1.0f)
				.build(),
		)
		mediaSession.setMetadata(
			MediaMetadataCompat.Builder()
				.putString(MediaMetadataCompat.METADATA_KEY_TITLE, title ?: appLabel())
				.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentProgressLabel())
				.build(),
		)
	}

	@SuppressLint("MissingPermission")
	private fun syncNotificationState() {
		syncPowerState()
		updateMediaSessionState()
		if (!backgroundModeEnabled) {
			if (isForegroundActive) {
				stopForeground(true)
				isForegroundActive = false
			}
			notificationManager.cancel(NOTIFICATION_ID)
			// Even without background mode, keep foreground service alive while playing
			// to prevent Android from killing us.
			if (status == "playing" || status == "paused") {
				val notification = buildNotification()
				startForeground(NOTIFICATION_ID, notification)
				isForegroundActive = true
			}
			return
		}

		when (status) {
			"playing", "paused" -> {
				val notification = buildNotification()
				if (!isForegroundActive) {
					startForeground(NOTIFICATION_ID, notification)
					isForegroundActive = true
				} else {
					notificationManager.notify(NOTIFICATION_ID, notification)
				}
			}
			else -> {
				if (isForegroundActive) {
					stopForeground(true)
					isForegroundActive = false
				}
				notificationManager.cancel(NOTIFICATION_ID)
			}
		}
	}

	private fun publishSnapshot() {
		val segment = currentSegment()
		val canExposeSegmentProgress = status == "playing" && currentUtteranceStarted
		ReaderTtsMediaBridge.publish(
			hashMapOf(
				"status" to status,
				"paragraphIndex" to currentIndex,
				"totalParagraphs" to segments.size,
				"activeParagraphIndex" to if (canExposeSegmentProgress) {
					(segment?.paragraphIndex ?: -1)
				} else {
					-1
				},
				"progressStart" to if (canExposeSegmentProgress) {
					(segment?.start ?: -1)
				} else {
					-1
				},
				"progressEnd" to if (canExposeSegmentProgress) {
					(segment?.end ?: -1)
				} else {
					-1
				},
				"contentKey" to contentKey,
				"completedCount" to completedCount,
				"backgroundModeEnabled" to backgroundModeEnabled,
				"language" to language,
				"voiceName" to voiceName,
				"availableVietnameseVoices" to availableVoices,
			),
		)
	}

	private fun createNotificationChannel() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
		val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
		val channel = NotificationChannel(
			CHANNEL_ID,
			CHANNEL_NAME,
			NotificationManager.IMPORTANCE_LOW,
		).apply {
			description = "Điều khiển đọc truyện bằng TTS"
			setShowBadge(false)
		}
		manager.createNotificationChannel(channel)
	}

	private fun extractSegments(intent: Intent): List<ReaderTtsSegment> {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			intent.getParcelableArrayListExtra(EXTRA_SEGMENTS, ReaderTtsSegment::class.java)
				?: arrayListOf()
		} else {
			@Suppress("DEPRECATION")
			(intent.getParcelableArrayListExtra<ReaderTtsSegment>(EXTRA_SEGMENTS)
				?: arrayListOf())
		}
	}

	override fun onDestroy() {
		mainHandler.removeCallbacks(playbackHealthRunnable)
		isRebuildingEngine = false
		clearScheduledRecoveries()
		cancelIdleStop()
		status = "idle"
		currentIndex = 0
		segments = emptyList()
		clearUtteranceRuntimeState()
		pendingReplayAfterInit = false
		publishSnapshot()
		tts?.stop()
		tts?.shutdown()
		abandonAudioFocus()
		syncPowerState()
		if (isForegroundActive) {
			stopForeground(true)
			isForegroundActive = false
		}
		mediaSession.release()
		super.onDestroy()
	}
}

private fun String.toLocale(): Locale {
	val normalized = replace('_', '-')
	return Locale.forLanguageTag(normalized).takeIf { it.language.isNotBlank() }
		?: Locale("vi", "VN")
}













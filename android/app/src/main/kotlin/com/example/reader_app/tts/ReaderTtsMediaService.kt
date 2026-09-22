package com.example.reader_app.tts

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.util.concurrent.Future
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
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
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.min
import java.util.Locale
import java.util.concurrent.Executors

data class ReaderTtsSegment(
	val text: String,
	val paragraphIndex: Int,
	val start: Int,
	val end: Int,
)

private data class ReaderRemoteChapter(
	val id: String,
	val number: Int?,
	val title: String?,
	val content: String,
	val nextChapterId: String?,
)

class ReaderTtsMediaService : Service(), TextToSpeech.OnInitListener {
	companion object {
		private const val NOTIFICATION_ID = 46021
		private const val CHANNEL_ID = "reader_tts_playback"
		private const val CHANNEL_NAME = "Reader TTS"
		private const val BASE_SPEED = 0.9
		private const val TAG = "ReaderTtsMediaService"
		private const val HEALTH_CHECK_INTERVAL_MS = 1500L
		private const val START_GRACE_PERIOD_MS = 5_000L
		private const val MAX_SEGMENT_RETRIES = 4
		private const val DEDUPE_START_WINDOW_MS = 600L

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

		const val EXTRA_SESSION_TOKEN = "sessionToken"
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

		fun startReading(context: Context, request: ReaderTtsStartRequest): Boolean {
			return try {
				val sessionToken = ReaderTtsPlaybackStore.enqueue(request)
				ContextCompat.startForegroundService(
					context,
					Intent(context, ReaderTtsMediaService::class.java).apply {
						action = ACTION_START_READING
						putExtra(EXTRA_SESSION_TOKEN, sessionToken)
					},
				)
				true
			} catch (e: Throwable) {
				Log.e(TAG, "startForegroundService blocked or failed", e)
				false
			}
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
	private var engineRecoveryAttempts = 0
	private var pendingEngineRebuild: Runnable? = null
	private var pendingAudioFocusRetry: Runnable? = null
	private var pendingIdleStop: Runnable? = null
	private var currentSegmentRetry = 0
	private var consecutiveSilentHealthChecks = 0
	private var utteranceWatchdog: Runnable? = null
	private var pausedByAudioFocus = false
	private var isDuckedByAudioFocus = false
	private var volumeMultiplier = 1.0f
	private var lastSpeakRequestTimeMs = 0L
	private var nextChapterId: String? = null
	private var chapterNumber: Int? = null
	private var includeChapterTitleInPlayback = true
	private var apiBaseUrl: String? = null
	private var isPreparingNextChapter = false
	private var awaitingNextChapter = false
	private var playbackError: String? = null
	private var chapterTask: Future<*>? = null
	@Volatile private var chapterConnection: HttpURLConnection? = null
	private var lastStartSignature: String? = null
	private var lastStartRequestAtMs = 0L
	private val networkExecutor = Executors.newSingleThreadExecutor()
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
					clearDuckingState(restartPlayback = false)
					if (status == "playing") {
						pausedByAudioFocus = true
						handlePause(fromAudioFocus = true)
					}
				}
				AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> handleDuckAudioFocusLoss()
				AudioManager.AUDIOFOCUS_GAIN -> {
					val shouldRestorePlaybackVolume = isDuckedByAudioFocus
					clearDuckingState(
						restartPlayback = shouldRestorePlaybackVolume && status == "playing",
					)
					if (pausedByAudioFocus && status == "paused") {
						pausedByAudioFocus = false
						handleResume()
					} else if (pausedByAudioFocus && status == "playing") {
						// Delayed focus grant arrived while status was already "playing"
						// (set optimistically). Treat same as resume.
						pausedByAudioFocus = false
						clearAudioFocusRetry()
						speakCurrentSegment(forceRestart = true)
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
		// Call startForeground() IMMEDIATELY in onCreate() before any async work.
		// Android O+ (and MIUI strictly enforced) requires startForeground() to be called
		// within 5 seconds of startForegroundService(). TTS engine init is async and may
		// take longer on cold start / low-end devices, so we must not wait for it.
		isForegroundActive = startForegroundCompat(buildIdleNotification())
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
				if (isTtsReady) {
					applyVoiceAndSpeedSettings()
				}
				publishSnapshot()
			}
			ACTION_SET_VOICE -> {
				voiceName = intent.getStringExtra(EXTRA_VOICE_NAME)
				language = intent.getStringExtra(EXTRA_LANGUAGE) ?: language
				if (isTtsReady) {
					applyVoiceAndSpeedSettings()
				}
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
						engineRecoveryAttempts = 0
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
			currentSegmentRetry = 0  // reset retry counter after successful engine reconnect
			refreshAvailableVoices()
			applyVoiceAndSpeedSettings()
			if ((pendingReplayAfterInit || status == "playing") && segments.isNotEmpty() && !awaitingNextChapter) {
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
			?.sortedBy { it.isNetworkConnectionRequired }
			?.mapNotNull { voice ->
				val locale = voice.locale?.toLanguageTag() ?: return@mapNotNull null
				mapOf("name" to voice.name, "locale" to locale)
			}
			.orEmpty()
			.distinctBy { voice -> "${voice["name"]}:${voice["locale"]}" }

		availableVoices = vietnameseVoices
		if (voiceName.isNullOrBlank()) {
			val preferred = vietnameseVoices.firstOrNull()
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
		val request = ReaderTtsPlaybackStore.consume(intent.getStringExtra(EXTRA_SESSION_TOKEN))
		if (request == null) {
			Log.e(TAG, "Missing in-memory TTS start request; refusing to start playback")
			handleStop(clearContentKey = true, reason = "missing_start_request")
			return
		}

		val now = System.currentTimeMillis()
		val signature = listOf(
			request.contentKey ?: "",
			request.title ?: "",
			request.chapterNumber?.toString() ?: "",
			request.startIndex.toString(),
			request.includeTitle.toString(),
			request.content.length.toString(),
		).joinToString("|")
		val isDuplicateRapidStart =
			signature == lastStartSignature &&
			(now - lastStartRequestAtMs) in 0..DEDUPE_START_WINDOW_MS
		if (isDuplicateRapidStart && (status == "playing" || status == "paused")) {
			Log.w(TAG, "Ignore duplicated rapid START_READING request")
			return
		}
		lastStartSignature = signature
		lastStartRequestAtMs = now

		cancelChapterLoad()
		engineRecoveryAttempts = 0
		currentSegmentRetry = 0
		awaitingNextChapter = false
		playbackError = null
		cancelIdleStop()
		backgroundModeEnabled = request.backgroundModeEnabled
		speed = request.speed
		language = request.language
		voiceName = request.voiceName ?: voiceName
		contentKey = request.contentKey
		title = request.title
		nextChapterId = request.nextChapterId
		chapterNumber = request.chapterNumber
		includeChapterTitleInPlayback = request.includeTitle
		apiBaseUrl = request.apiBaseUrl?.trimEnd('/')
		segments = buildSegments(
			content = request.content,
			title = request.title,
			includeTitle = includeChapterTitleInPlayback,
		)
		currentIndex = request.startIndex.coerceIn(0, (segments.size - 1).coerceAtLeast(0))
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		clearDuckingState(restartPlayback = false)
		isPreparingNextChapter = false
		status = "playing"
		pausedByAudioFocus = false
		pendingReplayAfterInit = false
		tts?.stop()
		syncPowerState()
		publishSnapshot()

		if (segments.isEmpty()) {
			handleStop(clearContentKey = false, reason = "empty_segments")
			return
		}

		if (!isTtsReady) return
		applyVoiceAndSpeedSettings()
		speakCurrentSegment(forceRestart = true)
	}

	private fun handlePause(fromAudioFocus: Boolean = false) {
		if (!fromAudioFocus) pausedByAudioFocus = false
		clearScheduledRecoveries()
		if (status != "playing") return
		cancelChapterLoad()
		clearScheduledRecoveries()
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		status = "paused"
		isPreparingNextChapter = false
		pendingReplayAfterInit = false
		tts?.stop()
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
	}

	private fun handleResume() {
		if (segments.isEmpty()) return
		engineRecoveryAttempts = 0
		currentSegmentRetry = 0
		cancelIdleStop()
		status = "playing"
		playbackError = null
		isPreparingNextChapter = false
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		pendingReplayAfterInit = false
		syncPowerState()
		publishSnapshot()
		if (awaitingNextChapter) {
			handleChapterCompleted()
			return
		}
		if (!isTtsReady) return
		speakCurrentSegment(forceRestart = true)
	}

	private fun handleStop(clearContentKey: Boolean, reason: String) {
		Log.i(TAG, "handleStop reason=$reason clearContentKey=$clearContentKey")
		cancelChapterLoad()
		awaitingNextChapter = false
		playbackError = null
		sessionGeneration += 1
		clearScheduledRecoveries()
		cancelIdleStop()
		clearUtteranceRuntimeState()
		clearDuckingState(restartPlayback = false)
		isPreparingNextChapter = false
		status = "idle"
		currentIndex = 0
		segments = emptyList()
		title = null
		nextChapterId = null
		chapterNumber = null
		apiBaseUrl = null
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
		cancelChapterLoad()
		awaitingNextChapter = false
		playbackError = null
		val nextIndex = (currentIndex + direction).coerceIn(0, segments.lastIndex)
		if (nextIndex == currentIndex && status == "idle") return
		currentIndex = nextIndex
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		isPreparingNextChapter = false
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
			handleChapterCompleted()
			return
		}

		currentIndex = nextIndex
		speakCurrentSegment(forceRestart = false)
	}

	private fun handlePlaybackFailure() {
		// Preserve the current sentence. Recovery must not silently skip text
		// or restart an unavailable engine forever.
		status = "paused"
		pendingReplayAfterInit = false
		playbackError = "Giọng đọc gặp lỗi. Hãy kiểm tra giọng tiếng Việt rồi nhấn tiếp tục."
		clearScheduledRecoveries()
		clearUtteranceRuntimeState()
		tts?.stop()
		abandonAudioFocus()
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
	}

	private fun speakCurrentSegment(forceRestart: Boolean) {
		if (segments.isEmpty() || !isTtsReady) return
		isPreparingNextChapter = false
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
				val params = Bundle().apply {
					putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volumeMultiplier)
				}
				tts?.speak(segment.text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
			} else {
				@Suppress("DEPRECATION")
				tts?.speak(
					segment.text,
					TextToSpeech.QUEUE_FLUSH,
					hashMapOf(
						TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID to utteranceId,
						TextToSpeech.Engine.KEY_PARAM_VOLUME to volumeMultiplier.toString(),
					),
				)
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
		if (currentSegmentRetry >= MAX_SEGMENT_RETRIES) {
			handlePlaybackFailure()
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
		engineRecoveryAttempts += 1
		if (engineRecoveryAttempts > 3) {
			handlePlaybackFailure()
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
					.setWillPauseWhenDucked(false)
					.setOnAudioFocusChangeListener(audioFocusListener)
					.build()
					.also { audioFocusRequest = it }
			val result = audioManager.requestAudioFocus(request)
			// AUDIOFOCUS_REQUEST_DELAYED (= 2) means focus will arrive via the listener.
			// Treat it as "not yet granted" – the listener will resume playback on GAIN.
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
				"$packageName:ReaderTtsPlayback"
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
		playbackError?.let { return it }
		if (isPreparingNextChapter) return "Đang tải chương tiếp theo"
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

	/** Minimal notification used in onCreate() to satisfy the 5-second startForeground() rule. */
	private fun buildIdleNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
		.setSmallIcon(android.R.drawable.ic_media_play)
		.setContentTitle(appLabel())
		.setContentText("Đang khởi động TTS…")
		.setOngoing(true)
		.setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
		.setCategory(NotificationCompat.CATEGORY_SERVICE)
		.build()

	@SuppressLint("MissingPermission")
	private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
		// Avoid adaptive launcher icon for foreground notifications on strict OEM ROMs.
		.setSmallIcon(android.R.drawable.ic_media_play)
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
				isForegroundActive = startForegroundCompat(notification)
			}
			return
		}

		when (status) {
			"playing", "paused" -> {
				val notification = buildNotification()
				if (!isForegroundActive) {
					isForegroundActive = startForegroundCompat(notification)
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

	private fun startForegroundCompat(notification: android.app.Notification): Boolean {
		return try {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				startForeground(
					NOTIFICATION_ID,
					notification,
					ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
				)
			} else {
				startForeground(NOTIFICATION_ID, notification)
			}
			true
		} catch (e: Throwable) {
			Log.e(TAG, "startForeground failed", e)
			false
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
				"isPreparingNextChapter" to isPreparingNextChapter,
				"errorMessage" to playbackError,
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
			// IMPORTANCE_DEFAULT is required on MIUI 12+ so the system does not demote
			// the foreground service. Sound/vibration are disabled explicitly so the user
			// is not disturbed despite the higher importance level.
			NotificationManager.IMPORTANCE_DEFAULT,
		).apply {
			description = "Điều khiển đọc truyện bằng TTS"
			setShowBadge(false)
			setSound(null, null)
			enableLights(false)
			enableVibration(false)
		}
		manager.createNotificationChannel(channel)
	}

	private fun sanitizeForTts(raw: String): String {
		if (raw.isBlank()) return raw
		return raw
			.replace(Regex("[\"“”]"), " ")
			.replace(Regex("[_\\$#^*+=~`|<>\\\\\\[\\]{}]"), " ")
			.replace(Regex("\\s+"), " ")
			.trim()
	}

	private fun buildSegments(
		content: String,
		title: String?,
		includeTitle: Boolean,
	): List<ReaderTtsSegment> {
		val builtSegments = mutableListOf<ReaderTtsSegment>()
		val trimmedTitle = title?.trim().orEmpty()
		if (includeTitle && trimmedTitle.isNotEmpty()) {
			val sanitizedTitle = sanitizeForTts(trimmedTitle)
			if (sanitizedTitle.isNotEmpty()) {
				builtSegments += ReaderTtsSegment(
					text = sanitizedTitle,
					paragraphIndex = -1,
					start = -1,
					end = -1,
				)
			}
		}

		val paragraphs = content
			.split(Regex("\\n+"))
			.map(String::trim)
			.filter(String::isNotEmpty)
		val sentenceRegex = Regex("[^.!?…]+[.!?…]*")

		paragraphs.forEachIndexed { paragraphIndex, paragraph ->
			var cursor = 0
			sentenceRegex.findAll(paragraph).forEach { match ->
				val sentence = match.value.trim()
				if (sentence.isEmpty()) return@forEach
				val sanitizedSentence = sanitizeForTts(sentence)
				if (sanitizedSentence.isEmpty()) return@forEach

				var start = paragraph.indexOf(sentence, cursor)
				if (start < 0) {
					start = cursor.coerceIn(0, paragraph.length)
				}
				val end = (start + sentence.length).coerceIn(0, paragraph.length)
				cursor = end

				builtSegments += ReaderTtsSegment(
					text = sanitizedSentence,
					paragraphIndex = paragraphIndex,
					start = start,
					end = end,
				)
			}
		}

		return builtSegments
	}

	private fun handleChapterCompleted() {
		clearUtteranceRuntimeState()
		val nextId = nextChapterId
		if (nextId.isNullOrBlank()) {
			finishPlaybackAfterChapterCompletion()
			return
		}

		awaitingNextChapter = true
		playbackError = null
		isPreparingNextChapter = true
		syncNotificationState()
		publishSnapshot()
		fetchAndPlayNextChapter(nextId, sessionGeneration)
	}

	private fun finishPlaybackAfterChapterCompletion() {
		awaitingNextChapter = false
		isPreparingNextChapter = false
		status = "idle"
		currentIndex = 0
		completedCount += 1
		Log.i(TAG, "chapter_completed contentKey=$contentKey completedCount=$completedCount")
		clearUtteranceRuntimeState()
		clearDuckingState(restartPlayback = false)
		abandonAudioFocus()
		syncPowerState()
		syncNotificationState()
		publishSnapshot()
		scheduleIdleStop()
	}

	private fun cancelChapterLoad() {
		chapterTask?.cancel(true)
		chapterTask = null
		chapterConnection?.disconnect()
		chapterConnection = null
	}

	private fun fetchAndPlayNextChapter(chapterId: String, generation: Int) {
		cancelChapterLoad()
		val baseUrl = apiBaseUrl
		chapterTask = networkExecutor.submit {
			val chapter = try {
				loadLocalChapter(chapterId) ?: fetchChapter(chapterId, baseUrl)
			} catch (error: Exception) {
				Log.w(TAG, "next_chapter_unavailable chapterId=$chapterId", error)
				null
			}
			mainHandler.post {
				if (generation != sessionGeneration || status != "playing") return@post
				isPreparingNextChapter = false
				if (chapter == null) {
					// Keep the next-chapter intent. Play retries it instead of replaying
					// the last sentence, silently stopping, or looping network retries.
					status = "paused"
					playbackError = "Chưa tải được chương tiếp theo. Kiểm tra mạng rồi nhấn tiếp tục."
					abandonAudioFocus()
					syncPowerState()
					syncNotificationState()
					publishSnapshot()
					return@post
				}
				adoptRemoteChapter(chapter)
			}
		}
	}

	private fun loadLocalChapter(chapterId: String): ReaderRemoteChapter? {
		// Same SQLite file as Drift/path_provider; read-only and off the main thread.
		val file = File(getDir("flutter", Context.MODE_PRIVATE), "reader_app.db")
		if (!file.exists()) return null
		return SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY).use { db ->
			db.rawQuery(
				"SELECT chapter_id, number, title, content, next_chapter_id FROM chapter_contents WHERE chapter_id = ? LIMIT 1",
				arrayOf(chapterId),
			).use { row ->
				if (!row.moveToFirst()) return@use null
				Log.i(TAG, "next_chapter_local chapterId=$chapterId")
				ReaderRemoteChapter(row.getString(0), row.getInt(1), row.getString(2),
					row.getString(3), if (row.isNull(4)) null else row.getString(4))
			}
		}
	}

	private fun fetchChapter(chapterId: String, origin: String?): ReaderRemoteChapter {
		if (Thread.currentThread().isInterrupted) throw InterruptedException()
		val baseUrl = origin?.trimEnd('/') ?: error("Missing api base URL for TTS service")
		val connection = (URL("$baseUrl/api/chapters/$chapterId").openConnection() as HttpURLConnection).apply {
			requestMethod = "GET"
			connectTimeout = 5_000
			readTimeout = 8_000
			setRequestProperty("Accept", "application/json")
		}

		chapterConnection = connection
		Log.i(TAG, "next_chapter_network chapterId=$chapterId")
		try {
			val statusCode = connection.responseCode
			val responseBody = (if (statusCode in 200..299) {
				connection.inputStream
			} else {
				connection.errorStream
			})?.bufferedReader()?.use { it.readText() }.orEmpty()

			if (statusCode !in 200..299) {
				error("HTTP $statusCode when fetching chapter $chapterId: $responseBody")
			}

			val json = JSONObject(responseBody)
			val id = json.optString("id").takeIf { it.isNotBlank() }
				?: error("Chapter payload missing id")
			require(id == chapterId) { "Unexpected chapter id" }
			val title = json.optString("title").takeIf { it.isNotBlank() }
			val content = json.optString("content")
			val nextId = if (json.isNull("nextChapterId")) null else json.optString("nextChapterId").takeIf { it.isNotBlank() }
			val number = if (json.isNull("number")) null else json.optInt("number")

			return ReaderRemoteChapter(
				id = id,
				number = number,
				title = title,
				content = content,
				nextChapterId = nextId,
			)
		} finally {
			connection.disconnect()
			if (chapterConnection === connection) chapterConnection = null
		}
	}

	private fun adoptRemoteChapter(remoteChapter: ReaderRemoteChapter) {
		awaitingNextChapter = false
		playbackError = null
		val nextTitle = buildChapterTitle(remoteChapter.number, remoteChapter.title)
		val nextSegments = buildSegments(
			content = remoteChapter.content,
			title = nextTitle,
			includeTitle = includeChapterTitleInPlayback,
		)
		if (nextSegments.isEmpty()) {
			Log.e(TAG, "Fetched next chapter has no readable segments id=${remoteChapter.id}")
			isPreparingNextChapter = false
			finishPlaybackAfterChapterCompletion()
			return
		}

		completedCount += 1
		contentKey = remoteChapter.id
		title = nextTitle
		chapterNumber = remoteChapter.number
		nextChapterId = remoteChapter.nextChapterId
		segments = nextSegments
		currentIndex = 0
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		isPreparingNextChapter = false
		status = "playing"
		pausedByAudioFocus = false
		pendingReplayAfterInit = false
		clearDuckingState(restartPlayback = false)
		publishSnapshot()

		if (!isTtsReady) {
			pendingReplayAfterInit = true
			scheduleEngineRebuild("next_chapter_tts_not_ready")
			return
		}

		speakCurrentSegment(forceRestart = true)
	}

	private fun buildChapterTitle(number: Int?, rawTitle: String?): String? {
		val trimmedTitle = rawTitle?.trim().orEmpty()
		return when {
			number != null && trimmedTitle.isNotEmpty() -> "Chương $number: $trimmedTitle"
			number != null -> "Chương $number"
			trimmedTitle.isNotEmpty() -> trimmedTitle
			else -> null
		}
	}

	private fun handleDuckAudioFocusLoss() {
		pausedByAudioFocus = false
		if (isDuckedByAudioFocus) return
		isDuckedByAudioFocus = true
		volumeMultiplier = 0.35f
		if (status == "playing" && !isPreparingNextChapter) {
			restartCurrentSegmentForFocusChange()
		}
	}

	private fun clearDuckingState(restartPlayback: Boolean) {
		if (!isDuckedByAudioFocus && volumeMultiplier == 1.0f) return
		isDuckedByAudioFocus = false
		volumeMultiplier = 1.0f
		if (restartPlayback && status == "playing" && !isPreparingNextChapter) {
			restartCurrentSegmentForFocusChange()
		}
	}

	private fun restartCurrentSegmentForFocusChange() {
		if (segments.isEmpty() || !isTtsReady) return
		sessionGeneration += 1
		clearUtteranceRuntimeState()
		tts?.stop()
		speakCurrentSegment(forceRestart = true)
	}

	override fun onDestroy() {
		sessionGeneration += 1
		cancelChapterLoad()
		mainHandler.removeCallbacks(playbackHealthRunnable)
		isRebuildingEngine = false
		clearScheduledRecoveries()
		cancelIdleStop()
		status = "idle"
		currentIndex = 0
		segments = emptyList()
		nextChapterId = null
		chapterNumber = null
		apiBaseUrl = null
		isPreparingNextChapter = false
		clearUtteranceRuntimeState()
		pendingReplayAfterInit = false
		clearDuckingState(restartPlayback = false)
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
		networkExecutor.shutdownNow()
		super.onDestroy()
	}
}

private fun String.toLocale(): Locale {
	val normalized = replace('_', '-')
	return Locale.forLanguageTag(normalized).takeIf { it.language.isNotBlank() }
		?: Locale("vi", "VN")
}













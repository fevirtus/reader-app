package com.example.reader_app.tts

import java.util.LinkedHashMap
import java.util.UUID

data class ReaderTtsStartRequest(
	val content: String,
	val contentKey: String?,
	val title: String?,
	val speed: Double,
	val language: String,
	val voiceName: String?,
	val backgroundModeEnabled: Boolean,
	val nextChapterId: String?,
	val chapterNumber: Int?,
	val includeTitle: Boolean,
	val apiBaseUrl: String?,
	val startIndex: Int = 0,
)

object ReaderTtsPlaybackStore {
	private const val MAX_PENDING_REQUESTS = 4
	private val pendingRequests = LinkedHashMap<String, ReaderTtsStartRequest>()

	@Synchronized
	fun enqueue(request: ReaderTtsStartRequest): String {
		val token = UUID.randomUUID().toString()
		pendingRequests[token] = request
		while (pendingRequests.size > MAX_PENDING_REQUESTS) {
			val oldestKey = pendingRequests.entries.firstOrNull()?.key ?: break
			pendingRequests.remove(oldestKey)
		}
		return token
	}

	@Synchronized
	fun consume(token: String?): ReaderTtsStartRequest? {
		if (token.isNullOrBlank()) return null
		return pendingRequests.remove(token)
	}
}
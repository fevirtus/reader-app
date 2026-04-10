package com.example.reader_app.tts

import io.flutter.plugin.common.EventChannel

object ReaderTtsMediaBridge {
	private var eventSink: EventChannel.EventSink? = null
	private var latestSnapshot: Map<String, Any?> = defaultSnapshot()

	@Synchronized
	fun attachSink(sink: EventChannel.EventSink) {
		eventSink = sink
		sink.success(HashMap(latestSnapshot))
	}

	@Synchronized
	fun detachSink() {
		eventSink = null
	}

	@Synchronized
	fun publish(snapshot: Map<String, Any?>) {
		latestSnapshot = HashMap(snapshot)
		eventSink?.success(HashMap(latestSnapshot))
	}

	@Synchronized
	fun snapshot(): Map<String, Any?> = HashMap(latestSnapshot)

	private fun defaultSnapshot(): Map<String, Any?> = hashMapOf(
		"status" to "idle",
		"paragraphIndex" to 0,
		"totalParagraphs" to 0,
		"activeParagraphIndex" to -1,
		"progressStart" to -1,
		"progressEnd" to -1,
		"contentKey" to null,
		"completedCount" to 0,
		"backgroundModeEnabled" to true,
		"language" to "vi-VN",
		"voiceName" to null,
		"availableVietnameseVoices" to emptyList<Map<String, String>>()
	)
}


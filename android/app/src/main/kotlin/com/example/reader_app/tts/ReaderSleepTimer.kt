package com.example.reader_app.tts

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock

/** TTS safety deadline survives Activity/Flutter view destruction in this process.
 * Active TTS owns a partial wake lock; no exact-alarm permission is required. */
object ReaderSleepTimer {
    private val handler = Handler(Looper.getMainLooper())
    private var pending: Runnable? = null

    fun set(context: Context, milliseconds: Long?) {
        pending?.let(handler::removeCallbacks)
        pending = null
        if (milliseconds == null) return
        require(milliseconds > 0 && milliseconds <= 24 * 60 * 60 * 1000L)
        val deadline = SystemClock.elapsedRealtime() + milliseconds
        val app = context.applicationContext
        val task = object : Runnable {
            override fun run() {
                val remaining = deadline - SystemClock.elapsedRealtime()
                if (remaining > 0) {
                    handler.postDelayed(this, remaining)
                    return
                }
                pending = null
                if (ReaderTtsMediaBridge.snapshot()["status"] != "idle") {
                    ReaderTtsMediaService.pause(app)
                }
            }
        }
        pending = task
        handler.postDelayed(task, milliseconds)
    }
}

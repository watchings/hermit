package com.hermit.core.tools.system

import android.content.Context
import com.hermit.util.AppLogger
import org.json.JSONObject
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Owns one Hermes process and speaks newline-delimited JSON to it.
 *
 * The manager never invokes a shell. The service is the only Android entry point
 * and is non-exported, so this IPC is intentionally local to this application.
 */
class HermesRuntimeManager private constructor(context: Context) {
    private val runtime = HermesPythonRuntime(context.applicationContext)
    private val lock = Any()
    private val requestExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "HermesRuntime-request").apply { isDaemon = true }
    }
    private var process: Process? = null
    private var writer: BufferedWriter? = null
    private var reader: BufferedReader? = null

    companion object {
        private const val TAG = "HermesRuntimeManager"
        private const val MAX_JSON_BYTES = 1024 * 1024
        private const val REQUEST_TIMEOUT_SECONDS = 30L

        @Volatile
        private var instance: HermesRuntimeManager? = null

        fun initialize(context: Context) {
            if (instance == null) {
                synchronized(this) {
                    if (instance == null) {
                        instance = HermesRuntimeManager(context)
                    }
                }
            }
        }

        fun getInstance(): HermesRuntimeManager {
            return checkNotNull(instance) {
                "HermesRuntimeManager must be initialized by OperitApplication"
            }
        }
    }

    fun start(): JSONObject {
        synchronized(lock) {
            if (isRunningLocked()) {
                return statusLocked()
            }
            val command = runtime.command(emptyList())
            val started = ProcessBuilder(command)
                .directory(runtime.layout().agent)
                .redirectErrorStream(false)
                .start()
            process = started
            writer = BufferedWriter(OutputStreamWriter(started.outputStream, Charsets.UTF_8))
            reader = BufferedReader(InputStreamReader(started.inputStream, Charsets.UTF_8))
            drainErrors(started)
            AppLogger.i(TAG, "Hermes runtime started")
            return statusLocked()
        }
    }

    fun request(jsonLine: String): String {
        require(jsonLine.toByteArray(Charsets.UTF_8).size <= MAX_JSON_BYTES) {
            "Hermes request exceeds $MAX_JSON_BYTES bytes"
        }
        val request = JSONObject(jsonLine)
        val future = requestExecutor.submit<String> {
            val responseReader: BufferedReader
            synchronized(lock) {
                check(isRunningLocked()) { "Hermes runtime is not running" }
                writer!!.apply {
                    write(request.toString())
                    newLine()
                    flush()
                }
                responseReader = reader!!
            }
            val response = responseReader.readLine()
                ?: throw IllegalStateException("Hermes runtime closed its JSON stream")
            require(response.toByteArray(Charsets.UTF_8).size <= MAX_JSON_BYTES) {
                "Hermes response exceeds $MAX_JSON_BYTES bytes"
            }
            JSONObject(response).toString()
        }
        return try {
            future.get(REQUEST_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        } catch (error: Exception) {
            future.cancel(true)
            AppLogger.e(TAG, "Hermes JSON request failed", error)
            stop()
            throw IllegalStateException("Hermes JSON request failed", error)
        }
    }

    fun stop(): JSONObject {
        synchronized(lock) {
            val current = process
            process = null
            writer?.close()
            reader?.close()
            writer = null
            reader = null
            if (current != null) {
                current.destroy()
                if (!current.waitFor(2, TimeUnit.SECONDS)) {
                    current.destroyForcibly()
                }
                AppLogger.i(TAG, "Hermes runtime stopped")
            }
            return statusLocked()
        }
    }

    fun status(): JSONObject = synchronized(lock) { statusLocked() }

    private fun isRunningLocked(): Boolean = process?.isAlive == true

    private fun statusLocked(): JSONObject = JSONObject()
        .put("running", isRunningLocked())

    private fun drainErrors(started: Process) {
        Thread {
            BufferedReader(InputStreamReader(started.errorStream, Charsets.UTF_8)).useLines { lines ->
                lines.forEach { line -> AppLogger.w(TAG, "Hermes stderr: $line") }
            }
        }.apply {
            name = "HermesRuntime-stderr"
            isDaemon = true
            start()
        }
    }
}

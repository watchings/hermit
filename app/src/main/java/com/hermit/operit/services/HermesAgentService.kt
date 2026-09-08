package com.hermit.services

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.hermit.core.tools.system.HermesRuntimeManager
import com.hermit.util.AppLogger
import org.json.JSONObject

/** Local-only owner of the Hermes runtime process. */
class HermesAgentService : Service() {
    private lateinit var runtimeManager: HermesRuntimeManager
    private val binder = HermesBinder()

    override fun onCreate() {
        super.onCreate()
        runtimeManager = HermesRuntimeManager.getInstance()
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onDestroy() {
        runtimeManager.stop()
        super.onDestroy()
    }

    inner class HermesBinder : Binder() {
        fun start(): String = runtimeManager.start().toString()

        fun request(jsonLine: String): String = try {
            runtimeManager.request(jsonLine)
        } catch (error: Exception) {
            AppLogger.e("HermesAgentService", "Hermes request rejected", error)
            JSONObject()
                .put("ok", false)
                .put("error", error.message ?: "Hermes request failed")
                .toString()
        }

        fun stop(): String = runtimeManager.stop().toString()

        fun status(): String = runtimeManager.status().toString()
    }
}

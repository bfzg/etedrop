package com.fasteddy.app

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private val logTag = "EddyLan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.fasteddy.app/lan_multicast_lock",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> {
                    try {
                        acquireLanMulticastLock()
                        Log.i(logTag, "WifiMulticastLock acquired (held=${multicastLock?.isHeld == true})")
                        result.success(null)
                    } catch (e: Exception) {
                        Log.e(logTag, "WifiMulticastLock acquire failed", e)
                        result.error("MULTICAST_LOCK", e.message, null)
                    }
                }
                "release" -> {
                    releaseLanMulticastLock()
                    Log.i(logTag, "WifiMulticastLock released")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun acquireLanMulticastLock() {
        if (multicastLock?.isHeld == true) return
        if (multicastLock == null) {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            multicastLock = wifi.createMulticastLock("eddy_lan_discovery").apply {
                setReferenceCounted(false)
            }
        }
        multicastLock?.acquire()
    }

    private fun releaseLanMulticastLock() {
        val lock = multicastLock ?: return
        if (lock.isHeld) {
            lock.release()
        }
    }
}

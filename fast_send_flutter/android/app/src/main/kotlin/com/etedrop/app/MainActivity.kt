package com.etedrop.app

import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private val logTag = "EteDropLan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.etedrop.app/ffmpeg_exec_paths",
        ).setMethodCallHandler { call, result ->
            if (call.method != "getExecutablePaths") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val dir = applicationContext.applicationInfo.nativeLibraryDir
                val ffmpeg = File(dir, "libffmpeg_etedrop.so")
                val ffprobe = File(dir, "libffprobe_etedrop.so")
                if (!ffmpeg.isFile || !ffprobe.isFile) {
                    result.error(
                        "MISSING_FFMPEG",
                        "缺少 jniLibs 中的 libffmpeg_etedrop.so / libffprobe_etedrop.so，请确认已构建 copyFfmpegAndroidJniLibs",
                        null,
                    )
                    return@setMethodCallHandler
                }
                result.success(
                    mapOf(
                        "ffmpegPath" to ffmpeg.absolutePath,
                        "ffprobePath" to ffprobe.absolutePath,
                    ),
                )
            } catch (e: Exception) {
                Log.e(logTag, "ffmpeg_exec_paths failed", e)
                result.error("FFMPEG_PATHS", e.message, null)
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.etedrop.app/lan_multicast_lock",
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
            multicastLock = wifi.createMulticastLock("etedrop_lan_discovery").apply {
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

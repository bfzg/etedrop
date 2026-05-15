package cn.etedrop.app

import android.content.ContentValues
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private val ioExecutor = Executors.newSingleThreadExecutor()
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.etedrop.app/public_downloads",
        ).setMethodCallHandler { call, result ->
            if (call.method != "copyToPublicDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val sourcePath = call.argument<String>("sourcePath")
                val fileName = call.argument<String>("fileName")
                val mimeType = call.argument<String>("mimeType")
                val subdirectory = call.argument<String>("subdirectory") ?: "EteDrop"
                if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                    result.error("BAD_ARGS", "sourcePath/fileName required", null)
                    return@setMethodCallHandler
                }
                ioExecutor.execute {
                    try {
                        val copied = copyToPublicDownloads(
                            sourcePath = sourcePath,
                            fileName = fileName,
                            mimeType = mimeType,
                            subdirectory = subdirectory,
                        )
                        runOnUiThread {
                            result.success(
                                mapOf(
                                    "absolutePath" to copied.absolutePath,
                                    "fileName" to copied.name,
                                ),
                            )
                        }
                    } catch (e: Exception) {
                        Log.e(logTag, "copyToPublicDownloads failed", e)
                        runOnUiThread {
                            result.error("COPY_PUBLIC_DOWNLOADS", e.message, null)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(logTag, "copyToPublicDownloads failed", e)
                result.error("COPY_PUBLIC_DOWNLOADS", e.message, null)
            }
        }
    }

    private fun copyToPublicDownloads(
        sourcePath: String,
        fileName: String,
        mimeType: String?,
        subdirectory: String,
    ): File {
        val source = File(sourcePath)
        require(source.isFile) { "Source file not found: $sourcePath" }

        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val targetDir = File(downloadsDir, subdirectory)
        if (!targetDir.exists()) {
            targetDir.mkdirs()
        }
        val targetName = uniqueFileName(targetDir, fileName)
        val targetFile = File(targetDir, targetName)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/$subdirectory"
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, targetName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType ?: guessMimeType(targetName))
                put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("Failed to create MediaStore item")
            try {
                FileInputStream(source).use { input ->
                    resolver.openOutputStream(uri, "w")?.use { output ->
                        input.copyTo(output)
                    } ?: throw IOException("Failed to open MediaStore output stream")
                }
                val finalizeValues = ContentValues().apply {
                    put(MediaStore.Downloads.IS_PENDING, 0)
                }
                resolver.update(uri, finalizeValues, null, null)
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
        } else {
            FileInputStream(source).use { input ->
                targetFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        }

        return targetFile
    }

    private fun uniqueFileName(directory: File, fileName: String): String {
        val dot = fileName.lastIndexOf('.')
        val stem = if (dot > 0) fileName.substring(0, dot) else fileName
        val ext = if (dot > 0) fileName.substring(dot) else ""
        var candidate = fileName
        var index = 1
        while (File(directory, candidate).exists()) {
            candidate = "$stem ($index)$ext"
            index += 1
        }
        return candidate
    }

    private fun guessMimeType(fileName: String): String {
        return when (fileName.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "bmp" -> "image/bmp"
            "heic" -> "image/heic"
            "mp4" -> "video/mp4"
            "mov" -> "video/quicktime"
            "m4v" -> "video/x-m4v"
            "mkv" -> "video/x-matroska"
            "webm" -> "video/webm"
            "avi" -> "video/x-msvideo"
            "3gp" -> "video/3gpp"
            "mp3" -> "audio/mpeg"
            "m4a" -> "audio/mp4"
            "wav" -> "audio/wav"
            "pdf" -> "application/pdf"
            "txt" -> "text/plain"
            "json" -> "application/json"
            else -> "application/octet-stream"
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

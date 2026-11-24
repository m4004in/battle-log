package com.battlelog.log

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingName: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePng" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val name = call.argument<String>("fileName") ?: "battlelog.png"
                        if (bytes == null) {
                            result.success(false)
                        } else {
                            savePng(bytes, sanitize(name), result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun sanitize(name: String): String {
        val cleaned = name.replace(Regex("[\\\\/:*?\"<>|\\s]+"), "_")
        return if (cleaned.lowercase().endsWith(".png")) cleaned else "$cleaned.png"
    }

    private fun savePng(bytes: ByteArray, name: String, result: MethodChannel.Result) {
        val needsLegacyPermission = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED

        if (needsLegacyPermission) {
            pendingResult = result
            pendingBytes = bytes
            pendingName = name
            requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), REQ_WRITE)
            return
        }
        writeAsync(bytes, name, result)
    }

    private fun writeAsync(bytes: ByteArray, name: String, result: MethodChannel.Result) {
        Thread {
            val ok = writeFile(bytes, name)
            runOnUiThread { result.success(ok) }
        }.start()
    }

    private fun writeFile(bytes: ByteArray, name: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val resolver = applicationContext.contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                    put(MediaStore.Downloads.MIME_TYPE, "image/png")
                    put(
                        MediaStore.Downloads.RELATIVE_PATH,
                        Environment.DIRECTORY_DOWNLOADS + "/BattleLog"
                    )
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: return false
                resolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                    output.flush()
                } ?: return false
                val done = ContentValues().apply {
                    put(MediaStore.Downloads.IS_PENDING, 0)
                }
                resolver.update(uri, done, null, null)
                true
            } else {
                @Suppress("DEPRECATION")
                val downloads = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                )
                val dir = File(downloads, "BattleLog")
                if (!dir.exists() && !dir.mkdirs()) return false
                val file = File(dir, name)
                FileOutputStream(file).use { output ->
                    output.write(bytes)
                    output.flush()
                }
                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(file.absolutePath),
                    arrayOf("image/png"),
                    null
                )
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQ_WRITE) return
        val result = pendingResult
        val bytes = pendingBytes
        val name = pendingName
        pendingResult = null
        pendingBytes = null
        pendingName = null
        if (result == null || bytes == null || name == null) {
            result?.success(false)
            return
        }
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (granted) {
            writeAsync(bytes, name, result)
        } else {
            result.success(false)
        }
    }

    companion object {
        private const val CHANNEL = "battlelog/image_saver"
        private const val REQ_WRITE = 9011
    }
}

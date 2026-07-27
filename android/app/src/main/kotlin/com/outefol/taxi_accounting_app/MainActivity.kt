package com.outefol.taxi_accounting_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "taxi_accounting_app/files"
    private val saveRequestCode = 7001
    private val openRequestCode = 7002
    private var pendingResult: MethodChannel.Result? = null
    private var pendingContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (pendingResult != null) {
                    result.error("busy", "另一个文件操作正在进行", null)
                    return@setMethodCallHandler
                }

                when (call.method) {
                    "saveText" -> {
                        val filename = call.argument<String>("filename")
                            ?: "出租车记账数据.txt"
                        val mimeType = call.argument<String>("mimeType")
                            ?: "text/plain"
                        pendingContent = call.argument<String>("content") ?: ""
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                            putExtra(Intent.EXTRA_TITLE, filename)
                        }
                        startActivityForResult(intent, saveRequestCode)
                    }

                    "openText" -> {
                        val mimeType = call.argument<String>("mimeType")
                            ?: "application/json"
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                        }
                        startActivityForResult(intent, openRequestCode)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveRequestCode && requestCode != openRequestCode) {
            return
        }

        val result = pendingResult ?: return
        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            clearPending()
            return
        }

        try {
            if (requestCode == saveRequestCode) {
                contentResolver.openOutputStream(uri)?.bufferedWriter(Charsets.UTF_8).use {
                    writer -> writer?.write(pendingContent ?: "")
                }
                result.success(true)
            } else {
                val text = contentResolver.openInputStream(uri)
                    ?.bufferedReader(Charsets.UTF_8)
                    .use { reader -> reader?.readText() }
                result.success(text)
            }
        } catch (error: Exception) {
            result.error("file_error", error.message, null)
        } finally {
            clearPending()
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingContent = null
    }
}

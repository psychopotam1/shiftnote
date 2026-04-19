package com.shiftnote.app

import android.content.ContentValues
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "backup_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveBackup") {
                    val fileName =
                        call.argument<String>("fileName") ?: "shiftnote_backup.json"
                    val content = call.argument<String>("content") ?: ""

                    try {
                        val resolver = applicationContext.contentResolver
                        val relativePath = "Documents/"
                        val collection = MediaStore.Files.getContentUri("external")

                        val existingUri = findExistingFileUri(
                            fileName = fileName,
                            relativePath = relativePath,
                        )

                        val targetUri: Uri = existingUri ?: run {
                            val values = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                            }

                            resolver.insert(collection, values)
                                ?: throw IllegalStateException("Could not create backup file")
                        }

                        val outputStream: OutputStream =
                            resolver.openOutputStream(targetUri, "wt")
                                ?: throw IllegalStateException("Could not open backup file")

                        outputStream.use {
                            it.write(content.toByteArray())
                            it.flush()
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun findExistingFileUri(
        fileName: String,
        relativePath: String,
    ): Uri? {
        val resolver = applicationContext.contentResolver
        val collection = MediaStore.Files.getContentUri("external")

        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection =
            "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val selectionArgs = arrayOf(fileName, relativePath)

        resolver.query(
            collection,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val id = cursor.getLong(idIndex)
                return Uri.withAppendedPath(collection, id.toString())
            }
        }

        return null
    }
}
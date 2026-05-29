package com.demo.shareplugin

import android.content.ClipData
import android.content.ClipDescription
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.net.Uri
import androidx.core.content.FileProvider
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import java.io.File
import java.io.FileOutputStream

@CapacitorPlugin(name = "SharePreview")
class SharePreviewPlugin : Plugin() {

    companion object {
        // Solid background painted behind the share-sheet icon. Fills any transparent
        // areas of the icon so the system sheet's gray background can't show through.
        // Change this hex to recolor the icon background (e.g. Color.WHITE, "#FF0000").
        private val ICON_BACKGROUND_COLOR = Color.WHITE
    }

    @PluginMethod
    fun share(call: PluginCall) {
        val title = call.getString("title") ?: ""
        val text  = call.getString("text")
        val url   = call.getString("url")

        val content = url ?: text
        if (content == null) {
            call.reject("Provide either 'url' or 'text'")
            return
        }

        val iconUri = appIconUri()

        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TITLE, title)
            putExtra(Intent.EXTRA_TEXT, content)

            if (iconUri != null) {
                clipData = ClipData(
                    ClipDescription(title, arrayOf("image/png")),
                    ClipData.Item(iconUri)
                )
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
        }

        val chooser = Intent.createChooser(shareIntent, title)
        activity.startActivity(chooser)
        call.resolve()
    }

    private fun appIconUri(): Uri? {
        return try {
            // Load from drawable/ — mipmap/ic_launcher resolves to adaptive icon XML
            // on API 26+ which BitmapFactory cannot decode.
            val src = BitmapFactory.decodeResource(
                context.resources,
                context.resources.getIdentifier("share_icon", "drawable", context.packageName)
            ) ?: return null

            // Composite the icon onto a solid background so the share sheet's gray
            // background does not show through any transparent pixels.
            val bitmap = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
            Canvas(bitmap).apply {
                drawColor(ICON_BACKGROUND_COLOR)
                drawBitmap(src, 0f, 0f, null)
            }

            val iconDir = File(context.cacheDir, "share_icons")
            iconDir.mkdirs()
            val iconFile = File(iconDir, "app_icon.png")
            FileOutputStream(iconFile).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }

            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                iconFile
            )
        } catch (e: Exception) {
            null
        }
    }
}

package com.example.kanairoxo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.*
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class MomentsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        private const val MAX_BITMAP_WIDTH = 600
        private const val MAX_BITMAP_HEIGHT = 600

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, widgetData: SharedPreferences) {
            val views = RemoteViews(context.packageName, R.layout.moments_widget)

            views.setImageViewBitmap(R.id.widget_title, createTitleBitmap(context))

            // The caption strip, matching the iOS polaroid. The view existed
            // in the layout and was never populated.
            val caption = widgetData.getString("latest_moment_caption", "") ?: ""
            val userName = widgetData.getString("latest_moment_user_name", "") ?: ""
            val firstName = userName.trim().split(" ").firstOrNull().orEmpty()
            val isVideo = widgetData.getBoolean("latest_moment_is_video", false)

            val stripText = when {
                caption.isNotBlank() && firstName.isNotBlank() -> "$caption · $firstName"
                caption.isNotBlank() -> caption
                firstName.isNotBlank() -> firstName
                else -> "a moment"
            }
            views.setTextViewText(R.id.widget_moment_caption, stripText)

            // Flutter writes this key; the widget was reading "moment_photo_0",
            // which nothing ever set — so it always fell back to the launcher
            // icon no matter how many moments had been posted.
            val latestPhoto = widgetData.getString("latest_moment_image_path", null)

            if (latestPhoto != null) {
                val file = File(latestPhoto)
                if (file.exists()) {
                    val bitmap = loadScaledBitmap(latestPhoto)
                    if (bitmap != null) {
                        views.setImageViewBitmap(
                            R.id.widget_moment_image,
                            if (isVideo) withPlayBadge(bitmap) else bitmap)
                    } else {
                        views.setImageViewResource(R.id.widget_moment_image, R.mipmap.ic_launcher)
                    }
                } else {
                    views.setImageViewResource(R.id.widget_moment_image, R.mipmap.ic_launcher)
                }
            } else {
                views.setImageViewResource(R.id.widget_moment_image, R.mipmap.ic_launcher)
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra("tab", "moments")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_moment_image, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_moment_caption, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun createTitleBitmap(context: Context): Bitmap {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = 42f
                color = Color.parseColor("#8B1A1A")
                typeface = Typeface.create("cursive", Typeface.ITALIC)
                setShadowLayer(4f, 0f, 2f, Color.argb(80, 0, 0, 0))
            }
            val text = "Moments"
            val width = paint.measureText(text).toInt() + 16
            val height = 56
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            canvas.drawText(text, 8f, 44f, paint)
            return bmp
        }

        /** Video moments ship the server's first-frame still, so without a
         *  badge they are indistinguishable from photos — same as iOS. */
        private fun withPlayBadge(src: Bitmap): Bitmap {
            return try {
                val out = src.copy(Bitmap.Config.ARGB_8888, true)
                val canvas = Canvas(out)
                val r = minOf(out.width, out.height) * 0.11f
                val cx = out.width - r - r * 0.6f
                val cy = out.height - r - r * 0.6f

                canvas.drawCircle(cx, cy, r, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.argb(150, 0, 0, 0)
                })
                val tri = Path().apply {
                    moveTo(cx - r * 0.28f, cy - r * 0.40f)
                    lineTo(cx + r * 0.44f, cy)
                    lineTo(cx - r * 0.28f, cy + r * 0.40f)
                    close()
                }
                canvas.drawPath(tri, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                })
                out
            } catch (e: Exception) {
                src
            }
        }

        private fun loadScaledBitmap(path: String): Bitmap? {
            return try {
                val options = BitmapFactory.Options()
                options.inJustDecodeBounds = true
                BitmapFactory.decodeFile(path, options)

                val originalWidth = options.outWidth
                val originalHeight = options.outHeight

                var sampleSize = 1
                while (originalWidth / sampleSize > MAX_BITMAP_WIDTH || originalHeight / sampleSize > MAX_BITMAP_HEIGHT) {
                    sampleSize *= 2
                }

                options.inJustDecodeBounds = false
                options.inSampleSize = sampleSize
                options.inPreferredConfig = Bitmap.Config.ARGB_8888

                BitmapFactory.decodeFile(path, options)
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }
}

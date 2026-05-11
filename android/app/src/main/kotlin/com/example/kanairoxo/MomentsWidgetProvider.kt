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

            // Change 2: Set Title Bitmap
            views.setImageViewBitmap(R.id.widget_title, createTitleBitmap(context))

            // Change 1: Show only the latest photo
            val latestPhoto = widgetData.getString("moment_photo_0", null)
            
            if (latestPhoto != null) {
                val file = File(latestPhoto)
                if (file.exists()) {
                    val bitmap = loadScaledBitmap(latestPhoto)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_moment_image, bitmap)
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

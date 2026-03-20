package com.example.kanairoxo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
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
        private const val MAX_BITMAP_WIDTH = 200
        private const val MAX_BITMAP_HEIGHT = 200

        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, widgetData: SharedPreferences) {
            val views = RemoteViews(context.packageName, R.layout.moments_widget)

            val photoIds = listOf(R.id.photo_1, R.id.photo_2, R.id.photo_3, R.id.photo_4)
            val swahiliIds = listOf(R.id.swahili_1, R.id.swahili_2, R.id.swahili_3, R.id.swahili_4)
            val defaultPhrases = listOf("Furaha kubwa", "Wakati mzuri", "Maisha ni mazuri", "Pamoja daima")

            for (i in 0..3) {
                val path = widgetData.getString("photo_path_$i", "") ?: ""
                val phrase = widgetData.getString("swahili_$i", defaultPhrases[i]) ?: defaultPhrases[i]

                views.setTextViewText(swahiliIds[i], phrase)

                if (path.isNotEmpty()) {
                    val file = File(path)
                    if (file.exists()) {
                        val scaledBitmap = loadScaledBitmap(path)
                        if (scaledBitmap != null) {
                            views.setImageViewBitmap(photoIds[i], scaledBitmap)
                            views.setViewVisibility(photoIds[i], View.VISIBLE)
                            views.setViewVisibility(swahiliIds[i], View.VISIBLE)
                        } else {
                            views.setImageViewResource(photoIds[i], R.mipmap.ic_launcher)
                        }
                    } else {
                        views.setImageViewResource(photoIds[i], R.mipmap.ic_launcher)
                    }
                } else {
                    views.setImageViewResource(photoIds[i], R.mipmap.ic_launcher)
                    views.setViewVisibility(photoIds[i], View.INVISIBLE)
                    views.setViewVisibility(swahiliIds[i], View.INVISIBLE)
                }
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra("tab", "moments")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.photo_1, pendingIntent) // Simplified click handling

            appWidgetManager.updateAppWidget(appWidgetId, views)
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
                options.inPreferredConfig = Bitmap.Config.RGB_565

                val sampledBitmap = BitmapFactory.decodeFile(path, options) ?: return null

                val scaled = Bitmap.createScaledBitmap(sampledBitmap, MAX_BITMAP_WIDTH, MAX_BITMAP_HEIGHT, true)
                if (scaled != sampledBitmap) {
                    sampledBitmap.recycle()
                }
                scaled
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }
}

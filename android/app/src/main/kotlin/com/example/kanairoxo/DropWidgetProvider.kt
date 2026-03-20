package com.example.kanairoxo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DropWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.drop_widget)
            
            val countdown = widgetData.getString("countdown_text", "00:00:00") ?: "00:00:00"
            val isLive = widgetData.getBoolean("is_live", false)
            val dropTitle = widgetData.getString("drop_title", "Friday at 6pm") ?: "Friday at 6pm"
            
            views.setTextViewText(R.id.countdown_text, countdown)
            views.setTextViewText(R.id.drop_title, dropTitle)
            
            if (isLive) {
                views.setTextViewText(R.id.drop_status, "LIVE NOW")
                views.setTextColor(R.id.countdown_text, Color.parseColor("#FF4444"))
            } else {
                views.setTextViewText(R.id.drop_status, "THE DROP")
                views.setTextColor(R.id.countdown_text, Color.WHITE)
            }
            
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.drop_widget_root, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

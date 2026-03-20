package com.example.kanairoxo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ActivityWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.activity_widget)
            
            val connections = widgetData.getInt("connections_count", 0)
            val notifications = widgetData.getInt("notifications_count", 0)
            val moments = widgetData.getInt("moments_count", 0)
            
            views.setTextViewText(R.id.connections_count, connections.toString())
            views.setTextViewText(R.id.notifications_count, notifications.toString())
            views.setTextViewText(R.id.moments_count, moments.toString())
            
            // Note: If you want to handle clicks, add a root ID to activity_widget.xml
            // val intent = Intent(context, MainActivity::class.java)
            // val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

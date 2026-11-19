package com.example.mi_app_universitaria

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PomodoroWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.pomodoro_widget_layout).apply {
                val subject = widgetData.getString("subject", "Enfoque Académico")
                val streak = widgetData.getInt("streak", 3)
                val progress = (widgetData.getFloat("progress", 0.65f) * 100).toInt()
                val species = widgetData.getString("species", "sp_oak")

                val emoji = when (species) {
                    "sp_rose" -> "🌹"
                    "sp_sakura" -> "🌸"
                    else -> "🌳"
                }

                setTextViewText(R.id.widget_emoji, emoji)
                setTextViewText(R.id.widget_subject, subject)
                setTextViewText(R.id.widget_streak, "🔥 $streak Días de Racha")
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)

                // Al tocar el widget, abre la app
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

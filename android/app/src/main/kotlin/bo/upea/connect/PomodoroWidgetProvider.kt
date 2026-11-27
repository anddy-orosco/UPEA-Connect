package bo.upea.connect

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class PomodoroWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Asegurar que cualquier broadcast actualice de inmediato todos los widgets en pantalla
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val thisWidget = ComponentName(context, PomodoroWidgetProvider::class.java)
        val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
        if (allWidgetIds != null && allWidgetIds.isNotEmpty()) {
            val widgetData = HomeWidgetPlugin.getData(context)
            onUpdate(context, appWidgetManager, allWidgetIds, widgetData)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pomodoro_widget_layout).apply {
                val subject = widgetData.getString("subject", "Enfoque Académico") ?: "Enfoque Académico"
                val streak = widgetData.getInt("streak", 1)
                val studiedToday = widgetData.getBoolean("studiedToday", false)
                val statusText = widgetData.getString("statusText", if (studiedToday) "✓ AL DÍA" else "⚡ HOY") ?: "⚡ HOY"
                val motivation = widgetData.getString("motivation", "🌱 ¡Tu brote tiene sed! Estudia hoy.") 
                    ?: "🌱 ¡Tu brote tiene sed! Estudia hoy."

                // Leer el progreso de forma 100% segura evitando cualquier ClassCastException
                val progress = try {
                    val raw = widgetData.all["progress"] ?: widgetData.all["progressInt"]
                    when (raw) {
                        is Int -> raw.coerceIn(0, 100)
                        is Long -> {
                            if (raw in 0..100) {
                                raw.toInt()
                            } else {
                                (java.lang.Double.longBitsToDouble(raw) * 100).toInt().coerceIn(0, 100)
                            }
                        }
                        is Float -> (raw * 100).toInt().coerceIn(0, 100)
                        is Double -> (raw * 100).toInt().coerceIn(0, 100)
                        else -> 25
                    }
                } catch (e: Exception) {
                    25
                }

                val species = widgetData.getString("species", "sp_oak") ?: "sp_oak"
                val plantImagePath = widgetData.getString("plant_graphic", null)

                // Localizar el archivo de imagen renderizado
                val imageFile = when {
                    plantImagePath != null && File(plantImagePath).exists() -> File(plantImagePath)
                    File(context.filesDir, "home_widget/plant_graphic.png").exists() -> File(context.filesDir, "home_widget/plant_graphic.png")
                    else -> null
                }

                var imageLoaded = false
                if (imageFile != null && imageFile.exists()) {
                    try {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        if (bitmap != null) {
                            setImageViewBitmap(R.id.widget_plant_image, bitmap)
                            setViewVisibility(R.id.widget_plant_image, View.VISIBLE)
                            setViewVisibility(R.id.widget_emoji, View.GONE)
                            imageLoaded = true
                        }
                    } catch (e: Exception) {
                        imageLoaded = false
                    }
                }

                if (!imageLoaded) {
                    showFallbackEmoji(this, species)
                }

                // 1. Textos principales
                setTextViewText(R.id.widget_subject, subject)
                setTextViewText(R.id.widget_motivation, motivation)
                setTextViewText(R.id.widget_progress_text, "$progress%")

                // 2. Racha estilo Duolingo
                val streakText = if (streak == 1) "🔥 1 DÍA" else "🔥 $streak DÍAS"
                setTextViewText(R.id.widget_streak, streakText)

                // 3. Chip de Estado (Al día / Hoy)
                setTextViewText(R.id.widget_status, statusText)
                if (studiedToday) {
                    setInt(R.id.widget_status, "setBackgroundResource", R.drawable.widget_status_badge_completed)
                    setTextColor(R.id.widget_status, Color.parseColor("#58CC02"))
                } else {
                    setInt(R.id.widget_status, "setBackgroundResource", R.drawable.widget_status_badge_pending)
                    setTextColor(R.id.widget_status, Color.parseColor("#FFC800"))
                }

                // 4. Barra de Progreso
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)

                // 5. Clic interactivo para abrir la app directamente
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun showFallbackEmoji(views: RemoteViews, species: String?) {
        val emoji = when (species) {
            "sp_rose" -> "🌹"
            "sp_sakura" -> "🌸"
            else -> "🌳"
        }
        views.setViewVisibility(R.id.widget_plant_image, View.GONE)
        views.setViewVisibility(R.id.widget_emoji, View.VISIBLE)
        views.setTextViewText(R.id.widget_emoji, emoji)
    }
}

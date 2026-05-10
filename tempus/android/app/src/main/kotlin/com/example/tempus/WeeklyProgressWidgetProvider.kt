package com.example.tempus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WeeklyProgressWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_weekly_progress)

            val totalHours = widgetData.getString("weekly_total", "0h") ?: "0h"
            val streak = widgetData.getInt("streak_count", 0)
            val sessionsCount = widgetData.getInt("weekly_sessions", 0)
            val changeText = widgetData.getString("weekly_change", "—") ?: "—"

            // Total hours
            views.setTextViewText(R.id.tv_total_hours, totalHours)

            // vs last week
            views.setTextViewText(R.id.tv_change, changeText)
            val isUp = changeText.contains("↑") || changeText == "—"
            views.setTextColor(R.id.tv_change, if (isUp) 0xFF00C853.toInt() else 0xFFFF5252.toInt())

            // Streak
            val streakText = if (streak > 0) "🔥 $streak day${if (streak == 1) "" else "s"}" else "🔥 No streak"
            views.setTextViewText(R.id.tv_streak, streakText)

            // Sessions count
            views.setTextViewText(R.id.tv_sessions_count, "$sessionsCount session${if (sessionsCount == 1) "" else "s"}")

            // Bar chart — read per-day minutes and scale bar heights
            val barIds = intArrayOf(
                R.id.bar_mon, R.id.bar_tue, R.id.bar_wed,
                R.id.bar_thu, R.id.bar_fri, R.id.bar_sat, R.id.bar_sun
            )
            val dayKeys = arrayOf("day_mon", "day_tue", "day_wed", "day_thu", "day_fri", "day_sat", "day_sun")

            var maxMinutes = 1 // Avoid division by zero
            val dayMinutes = IntArray(7)
            for (i in 0..6) {
                dayMinutes[i] = widgetData.getInt(dayKeys[i], 0)
                if (dayMinutes[i] > maxMinutes) maxMinutes = dayMinutes[i]
            }

            for (i in 0..6) {
                // Set bar image based on whether the day has data.
                if (dayMinutes[i] > 0) {
                    views.setImageViewResource(barIds[i], R.drawable.widget_bar_active)
                } else {
                    views.setImageViewResource(barIds[i], R.drawable.widget_bar_bg)
                }

                // Dynamically set bar height (requires API 31+).
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val fraction = dayMinutes[i].toFloat() / maxMinutes.toFloat()
                    val heightDp = (4 + (fraction * 32)).toInt() // min 4dp, max 36dp
                    views.setViewLayoutHeight(barIds[i], heightDp.toFloat(), TypedValue.COMPLEX_UNIT_DIP)
                }
            }

            // Clicking the widget opens the app
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_weekly_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

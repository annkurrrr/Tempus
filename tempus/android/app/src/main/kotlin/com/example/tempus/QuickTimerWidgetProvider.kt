package com.example.tempus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickTimerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_timer)

            val timerStatus = widgetData.getString("timer_status", "idle") ?: "idle"
            val elapsed = widgetData.getString("timer_elapsed", "00:00:00") ?: "00:00:00"
            val streak = widgetData.getInt("streak_count", 0)
            val sessionNum = widgetData.getInt("current_session_num", 0)

            // Update timer text
            views.setTextViewText(R.id.tv_timer, elapsed)

            // Update status label
            val statusText = when (timerStatus) {
                "running" -> "⏱ Running"
                "paused" -> "⏸ Paused"
                else -> "No active session"
            }
            views.setTextViewText(R.id.tv_status, statusText)

            // Status color
            val statusColor = when (timerStatus) {
                "running" -> 0xFF00C853.toInt()
                "paused" -> 0xFFFFD54F.toInt()
                else -> 0xFFB0B0B0.toInt()
            }
            views.setTextColor(R.id.tv_status, statusColor)

            // Timer text color
            val timerColor = when (timerStatus) {
                "running" -> 0xFF00C853.toInt()
                else -> 0xFFF5F5F5.toInt()
            }
            views.setTextColor(R.id.tv_timer, timerColor)

            // Streak
            val streakText = if (streak > 0) "🔥 $streak day${if (streak == 1) "" else "s"} streak" else "🔥 No streak"
            views.setTextViewText(R.id.tv_streak, streakText)

            // Session badge
            if (sessionNum > 0 && timerStatus != "idle") {
                views.setTextViewText(R.id.tv_session_badge, "Session #$sessionNum")
                views.setViewVisibility(R.id.tv_session_badge, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.tv_session_badge, View.GONE)
            }

            // Clicking the widget opens the app
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_quick_timer_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

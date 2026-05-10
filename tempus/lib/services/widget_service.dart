import 'package:home_widget/home_widget.dart';
import '../models/session.dart';

/// Pushes session/timer data to Android home screen widgets via [HomeWidget].
class WidgetService {
  WidgetService._();

  /// Call this once at app startup to set the group ID.
  static Future<void> init() async {
    await HomeWidget.setAppGroupId('com.example.tempus');
  }

  /// Updates widget data based on the current session list and timer state.
  /// Call this after saving/deleting a session or changing timer state.
  static Future<void> updateWidgets({
    required List<Session> sessions,
    String timerStatus = 'idle', // 'idle', 'running', 'paused'
    String timerElapsed = '00:00:00',
    int currentSessionNum = 0,
  }) async {
    // ── Timer data (for Quick Timer widget) ──────────────────────────
    await HomeWidget.saveWidgetData('timer_status', timerStatus);
    await HomeWidget.saveWidgetData('timer_elapsed', timerElapsed);
    await HomeWidget.saveWidgetData('current_session_num', currentSessionNum);

    // ── Streak calculation ──────────────────────────────────────────
    final streak = _computeStreak(sessions);
    await HomeWidget.saveWidgetData('streak_count', streak);

    // ── Weekly stats (for Weekly Progress widget) ───────────────────
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final monday = todayDate.subtract(Duration(days: todayDate.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    final lastMonday = monday.subtract(const Duration(days: 7));

    final thisWeek = sessions.where((s) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      return !d.isBefore(monday) && d.isBefore(nextMonday);
    }).toList();

    final lastWeek = sessions.where((s) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      return !d.isBefore(lastMonday) && d.isBefore(monday);
    }).toList();

    // Total hours
    final totalSecsThisWeek =
        thisWeek.fold<int>(0, (sum, s) => sum + s.totalDuration.inSeconds);
    final totalSecsLastWeek =
        lastWeek.fold<int>(0, (sum, s) => sum + s.totalDuration.inSeconds);

    final hours = totalSecsThisWeek / 3600.0;
    String totalText;
    if (hours < 1) {
      totalText = '${(hours * 60).round()}m';
    } else {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      totalText = m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    await HomeWidget.saveWidgetData('weekly_total', totalText);
    await HomeWidget.saveWidgetData('weekly_sessions', thisWeek.length);

    // vs last week
    String changeText = '—';
    if (totalSecsLastWeek > 0) {
      final pct =
          ((totalSecsThisWeek - totalSecsLastWeek) / totalSecsLastWeek * 100);
      changeText = pct >= 0
          ? '↑${pct.abs().toStringAsFixed(0)}%'
          : '↓${pct.abs().toStringAsFixed(0)}%';
    } else if (totalSecsThisWeek > 0) {
      changeText = '↑100%';
    }
    await HomeWidget.saveWidgetData('weekly_change', changeText);

    // Per-day minutes for bar chart
    final dayKeys = ['day_mon', 'day_tue', 'day_wed', 'day_thu', 'day_fri', 'day_sat', 'day_sun'];
    final dayMinutes = List.filled(7, 0);
    for (final s in thisWeek) {
      final dayIdx = s.date.weekday - 1; // 0=Mon, 6=Sun
      dayMinutes[dayIdx] += s.totalDuration.inMinutes;
    }
    for (int i = 0; i < 7; i++) {
      await HomeWidget.saveWidgetData(dayKeys[i], dayMinutes[i]);
    }

    // ── Trigger native widget refresh ───────────────────────────────
    await HomeWidget.updateWidget(
      androidName: 'QuickTimerWidgetProvider',
    );
    await HomeWidget.updateWidget(
      androidName: 'WeeklyProgressWidgetProvider',
    );
  }

  /// Lightweight update — only pushes the elapsed time string.
  /// Called every second while the timer is running. Avoids recomputing
  /// streak and weekly stats on each tick.
  static Future<void> updateTimerElapsed(String elapsed) async {
    await HomeWidget.saveWidgetData('timer_elapsed', elapsed);
    await HomeWidget.updateWidget(
      androidName: 'QuickTimerWidgetProvider',
    );
  }

  /// Computes the current streak (same logic as StreakCounter widget).
  static int _computeStreak(List<Session> sessions) {
    if (sessions.isEmpty) return 0;
    final qualifying =
        sessions.where((s) => s.totalDuration.inMinutes >= 30).toList();
    if (qualifying.isEmpty) return 0;
    final dates = qualifying
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    int count = 0;
    DateTime expected = dates.contains(todayDate) ? todayDate : yesterday;
    for (final d in dates) {
      if (d == expected) {
        count++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (d.isBefore(expected)) {
        break;
      }
    }
    return count;
  }
}

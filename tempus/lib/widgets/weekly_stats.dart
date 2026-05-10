import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';

/// Displays aggregated weekly stats: total hours, avg session, best day,
/// and a comparison vs. last week.
class WeeklyStats extends StatelessWidget {
  final List<Session> sessions;

  const WeeklyStats({super.key, required this.sessions});

  DateTime get _mondayOfThisWeek {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  DateTime get _mondayOfLastWeek =>
      _mondayOfThisWeek.subtract(const Duration(days: 7));

  List<Session> _sessionsInRange(DateTime start, DateTime end) {
    return sessions.where((s) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);

    final thisWeek = _sessionsInRange(
      _mondayOfThisWeek,
      _mondayOfThisWeek.add(const Duration(days: 7)),
    );
    final lastWeek = _sessionsInRange(_mondayOfLastWeek, _mondayOfThisWeek);

    // ── Compute stats ──────────────────────────────────────────────────
    final totalSecondsThisWeek = thisWeek.fold<int>(
      0,
      (sum, s) => sum + s.totalDuration.inSeconds,
    );
    final totalSecondsLastWeek = lastWeek.fold<int>(
      0,
      (sum, s) => sum + s.totalDuration.inSeconds,
    );

    final totalHours = totalSecondsThisWeek / 3600.0;
    final avgMinutes = thisWeek.isNotEmpty
        ? (totalSecondsThisWeek / thisWeek.length / 60.0)
        : 0.0;

    // Best day
    String bestDay = '—';
    if (thisWeek.isNotEmpty) {
      final dayTotals = <int, int>{}; // weekday → total seconds
      for (final s in thisWeek) {
        dayTotals[s.date.weekday] =
            (dayTotals[s.date.weekday] ?? 0) + s.totalDuration.inSeconds;
      }
      final bestWeekday = dayTotals.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      bestDay = DateFormat(
        'EEEE',
      ).format(_mondayOfThisWeek.add(Duration(days: bestWeekday - 1)));
    }

    // Week-over-week comparison
    double changePercent = 0;
    bool isUp = true;
    if (totalSecondsLastWeek > 0) {
      changePercent =
          ((totalSecondsThisWeek - totalSecondsLastWeek) /
              totalSecondsLastWeek) *
          100;
      isUp = changePercent >= 0;
    } else if (totalSecondsThisWeek > 0) {
      changePercent = 100;
      isUp = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(
              Icons.insights_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'This Week',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${thisWeek.length} session${thisWeek.length == 1 ? '' : 's'}',
              style: TextStyle(color: c.textTertiary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stats grid — 2×2
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.schedule_rounded,
                label: 'Total',
                value: _formatHours(totalHours),
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: Icons.av_timer_rounded,
                label: 'Avg session',
                value: _formatMinutes(avgMinutes),
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.emoji_events_rounded,
                label: 'Best day',
                value: bestDay,
                color: const Color(0xFFFFD54F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                icon: isUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label: 'vs last week',
                value: totalSecondsLastWeek == 0 && totalSecondsThisWeek == 0
                    ? '—'
                    : '${isUp ? '↑' : '↓'}${changePercent.abs().toStringAsFixed(0)}%',
                color: isUp ? AppTheme.primary : Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).round()}m';
    }
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatMinutes(double minutes) {
    if (minutes < 1) return '0m';
    if (minutes < 60) return '${minutes.round()}m';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: c.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

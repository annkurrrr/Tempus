import 'package:flutter/material.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';

/// Displays the current streak count with an animated fire icon.
/// Only sessions with >= 30 minutes count towards the streak.
class StreakCounter extends StatelessWidget {
  final List<Session> sessions;

  const StreakCounter({super.key, required this.sessions});

  int get streak {
    if (sessions.isEmpty) return 0;
    final qualifyingSessions =
        sessions.where((s) => s.totalDuration.inMinutes >= 30).toList();
    if (qualifyingSessions.isEmpty) return 0;
    final dates = qualifyingSessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    int count = 0;
    // Start from today; if no session today, start from yesterday.
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

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    final s = streak;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: s > 0
                ? AppTheme.primary.withValues(alpha: 0.12)
                : c.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: s > 0 ? AppTheme.primary : c.textTertiary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$s day${s == 1 ? '' : 's'}',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'current streak',
              style: TextStyle(color: c.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

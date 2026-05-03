import 'package:flutter/material.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';

/// Displays a dynamic grid of rounded squares representing sessions,
/// colored by productivity level (GitHub-contribution style).
class ProductivityCalendar extends StatelessWidget {
  final List<Session> sessions;

  const ProductivityCalendar({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.grid_view_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Productivity',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${sessions.length} sessions',
              style: TextStyle(color: c.textTertiary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const double baseSize = 26;
            const double spacing = 8;
            final int perRow =
                ((constraints.maxWidth + spacing) / (baseSize + spacing))
                    .floor();
            final double squareSize =
                (constraints.maxWidth - (perRow - 1) * spacing) / perRow;
            const int rows = 5;
            final int totalSlots = perRow * rows;
            final recentSessions = sessions.length > totalSlots
                ? sessions.sublist(sessions.length - totalSlots)
                : sessions;
            final emptySlots = totalSlots - recentSessions.length;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (int i = 0; i < emptySlots; i++)
                  _SquareDot(level: -1, index: i, size: squareSize),
                for (int i = 0; i < recentSessions.length; i++)
                  _SquareDot(
                    level: recentSessions[i].productivityLevel,
                    index: emptySlots + i,
                    size: squareSize,
                    sessionName: recentSessions[i].sessionName,
                    duration: recentSessions[i].formattedDuration,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _Legend(),
      ],
    );
  }
}

class _SquareDot extends StatelessWidget {
  final int level;
  final int index;
  final double size;
  final String? sessionName;
  final String? duration;

  const _SquareDot({
    required this.level,
    required this.index,
    required this.size,
    this.sessionName,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    Color color;
    if (level == -1) {
      color = c.surfaceLighter.withValues(alpha: 0.4);
    } else if (level == 0) {
      color = c.level0;
    } else {
      color = AppTheme.levelColor(level, colors: c);
    }

    final dot = AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index % 40) * 15),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: level >= 3
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    if (level == -1 || sessionName == null) return dot;

    return Tooltip(
      message: '$sessionName — $duration',
      preferBelow: false,
      decoration: BoxDecoration(
        color: c.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: c.textPrimary, fontSize: 12),
      child: dot,
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Less ',
            style: TextStyle(color: c.textTertiary, fontSize: 11)),
        for (int i = 0; i <= 4; i++) ...[
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == 0 ? c.level0 : AppTheme.levelColor(i, colors: c),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        Text(' More',
            style: TextStyle(color: c.textTertiary, fontSize: 11)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';

/// A modal bottom sheet showing full details of a session.
class SessionDetailSheet extends StatelessWidget {
  final Session session;
  final VoidCallback? onDelete;

  const SessionDetailSheet({
    super.key,
    required this.session,
    this.onDelete,
  });

  static void show(
    BuildContext context,
    Session session, {
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionDetailSheet(
        session: session,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    final dateFmt = DateFormat('dd MMMM yyyy');
    final timeFmt = DateFormat('hh:mm:ss a');
    final levelColor =
        AppTheme.levelColor(session.productivityLevel, colors: c);

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: c.surfaceLighter,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Session #${session.sessionNumber}',
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session.sessionName,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.redAccent,
                  tooltip: 'Delete session',
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: c.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  session.formattedDuration,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.levelLabel(session.productivityLevel),
                  style: TextStyle(
                    color: levelColor.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: dateFmt.format(session.date),
          ),
          _InfoRow(
            icon: Icons.play_circle_outline_rounded,
            label: 'Started at',
            value: timeFmt.format(session.startTime),
          ),
          _InfoRow(
            icon: Icons.stop_circle_outlined,
            label: 'Ended at',
            value: timeFmt.format(session.endTime),
          ),
          if (session.comment != null && session.comment!.isNotEmpty)
            _InfoRow(
              icon: Icons.comment_outlined,
              label: 'Comment',
              value: session.comment!,
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final c = TempusColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Session?',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Session #${session.sessionNumber} "${session.sessionName}" '
          'will be permanently deleted.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: c.textTertiary, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: c.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

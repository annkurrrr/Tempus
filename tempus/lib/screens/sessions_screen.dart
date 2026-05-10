import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/session_storage.dart';
import '../services/widget_service.dart';
import '../theme/app_theme.dart';
import '../widgets/session_grid_card.dart';
import '../widgets/session_detail_sheet.dart';

/// Screen displaying all saved sessions in a 3-column grid.
class SessionsScreen extends StatelessWidget {
  final List<Session> sessions;
  final VoidCallback onSessionDeleted;

  const SessionsScreen({
    super.key,
    required this.sessions,
    required this.onSessionDeleted,
  });

  Future<void> _deleteSession(
      BuildContext context, Session session) async {
    final updatedSessions = await SessionStorage.deleteSession(session.sessionNumber);
    onSessionDeleted();
    // Refresh home screen widgets with updated data.
    WidgetService.updateWidgets(sessions: updatedSessions);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Session #${session.sessionNumber} deleted'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    // Reversed so newest sessions come first.
    final reversed = sessions.reversed.toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded,
                    color: AppTheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Sessions',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sessions.length}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.surfaceLighter),
          Expanded(
            child: sessions.isEmpty
                ? _EmptyState()
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: reversed.length,
                    itemBuilder: (context, index) {
                      final session = reversed[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                            milliseconds: 300 + (index * 30)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset:
                                  Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: SessionGridCard(
                          session: session,
                          onTap: () => SessionDetailSheet.show(
                            context,
                            session,
                            onDelete: () =>
                                _deleteSession(context, session),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty_rounded,
              size: 64,
              color: c.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your first session from the home tab',
            style: TextStyle(color: c.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

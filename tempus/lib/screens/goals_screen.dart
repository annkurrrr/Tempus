import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weekly_goal.dart';
import '../services/goal_storage.dart';
import '../theme/app_theme.dart';

/// Screen for weekly goals — set, edit, mark status, and view history.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<WeeklyGoal> _allGoals = [];
  bool _loading = true;
  bool _checkedPast = false;

  DateTime get _currentMonday => GoalStorage.mondayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await GoalStorage.loadGoals();
    setState(() {
      _allGoals = goals;
      _loading = false;
    });
    if (!_checkedPast) {
      _checkedPast = true;
      _handleUnresolvedPastGoals();
    }
  }

  Future<void> _handleUnresolvedPastGoals() async {
    final unresolved = await GoalStorage.unresolvedPastGoals(_currentMonday);
    if (unresolved.isEmpty || !mounted) return;
    for (final goal in unresolved) {
      if (!mounted) return;
      await _showMarkPastGoalDialog(goal);
    }
    await _load();
  }

  Future<void> _showMarkPastGoalDialog(WeeklyGoal goal) async {
    final c = TempusColors.of(context);
    final weekLabel = _weekLabel(goal.weekStart);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pending Goal',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have an unmarked goal from $weekLabel:',
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                goal.goalText,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How did it go?',
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          _StatusChip(
            label: 'Completed',
            color: AppTheme.primary,
            icon: Icons.check_circle_rounded,
            onTap: () {
              goal.status = GoalStatus.complete;
              goal.statusChangedAt = DateTime.now();
              GoalStorage.updateGoal(goal);
              Navigator.pop(ctx);
            },
          ),
          _StatusChip(
            label: 'In Progress',
            color: Colors.amber,
            icon: Icons.timelapse_rounded,
            onTap: () {
              goal.status = GoalStatus.inProgress;
              goal.statusChangedAt = DateTime.now();
              GoalStorage.updateGoal(goal);
              Navigator.pop(ctx);
            },
          ),
          _StatusChip(
            label: "Didn't Complete",
            color: Colors.redAccent,
            icon: Icons.cancel_rounded,
            onTap: () {
              goal.status = GoalStatus.incomplete;
              goal.statusChangedAt = DateTime.now();
              GoalStorage.updateGoal(goal);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  WeeklyGoal? get _activeGoal {
    final thisWeek = _allGoals
        .where(
          (g) =>
              g.weekStart.year == _currentMonday.year &&
              g.weekStart.month == _currentMonday.month &&
              g.weekStart.day == _currentMonday.day,
        )
        .toList();
    final pending = thisWeek.where((g) => !g.isResolved).toList();
    if (pending.isNotEmpty) return pending.last;
    return null;
  }

  List<WeeklyGoal> get _thisWeekGoals {
    return _allGoals
        .where(
          (g) =>
              g.weekStart.year == _currentMonday.year &&
              g.weekStart.month == _currentMonday.month &&
              g.weekStart.day == _currentMonday.day,
        )
        .toList();
  }

  List<WeeklyGoal> get _pastGoals {
    return _allGoals.where((g) => g.weekStart.isBefore(_currentMonday)).toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
  }

  Future<void> _setGoal() async {
    final c = TempusColors.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set Weekly Goal',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: c.textPrimary),
          decoration: const InputDecoration(hintText: 'Your goal...'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('SET GOAL'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final goal = WeeklyGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalText: result,
        weekStart: _currentMonday,
        createdAt: DateTime.now(),
      );
      await GoalStorage.addGoal(goal);
      await _load();
    }
  }

  Future<void> _editGoal(WeeklyGoal goal) async {
    final c = TempusColors.of(context);
    final controller = TextEditingController(text: goal.goalText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Goal',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: c.textPrimary),
          decoration: const InputDecoration(hintText: 'Your goal...'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final updated = WeeklyGoal(
        id: goal.id,
        goalText: result,
        weekStart: goal.weekStart,
        createdAt: goal.createdAt,
        status: goal.status,
        statusChangedAt: goal.statusChangedAt,
      );
      await GoalStorage.updateGoal(updated);
      await _load();
    }
  }

  Future<void> _markGoal(WeeklyGoal goal, GoalStatus status) async {
    goal.status = status;
    goal.statusChangedAt = DateTime.now();
    await GoalStorage.updateGoal(goal);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal marked as ${status.label}'),
          backgroundColor: _statusColor(status),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _weekLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('dd MMM');
    return '${fmt.format(monday)} – ${fmt.format(sunday)}';
  }

  Color _statusColor(GoalStatus s) {
    switch (s) {
      case GoalStatus.complete:
        return AppTheme.primary;
      case GoalStatus.inProgress:
        return Colors.amber;
      case GoalStatus.incomplete:
        return Colors.redAccent;
      case GoalStatus.pending:
        return Colors.grey;
    }
  }

  IconData _statusIcon(GoalStatus s) {
    switch (s) {
      case GoalStatus.complete:
        return Icons.check_circle_rounded;
      case GoalStatus.inProgress:
        return Icons.timelapse_rounded;
      case GoalStatus.incomplete:
        return Icons.cancel_rounded;
      case GoalStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    final active = _activeGoal;
    final past = _pastGoals;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Weekly Goals',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _weekLabel(_currentMonday),
                    style: TextStyle(color: c.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(height: 16, color: c.surfaceLighter),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'THIS WEEK',
                style: TextStyle(
                  color: c.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: active != null
                  ? _ActiveGoalCard(
                      goal: active,
                      onEdit: () => _editGoal(active),
                      onComplete: () => _markGoal(active, GoalStatus.complete),
                      onIncomplete: () =>
                          _markGoal(active, GoalStatus.incomplete),
                      onInProgress: () =>
                          _markGoal(active, GoalStatus.inProgress),
                    )
                  : _SetGoalCard(onTap: _setGoal),
            ),
          ),
          if (_thisWeekGoals.where((g) => g.isResolved).isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'EARLIER THIS WEEK',
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final resolved =
                    _thisWeekGoals.where((g) => g.isResolved).toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return _GoalHistoryTile(
                  goal: resolved[index],
                  statusColor: _statusColor(resolved[index].status),
                  statusIcon: _statusIcon(resolved[index].status),
                  weekLabel: null,
                );
              }, childCount: _thisWeekGoals.where((g) => g.isResolved).length),
            ),
          ],
          if (past.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                child: Text(
                  'PAST WEEKS',
                  style: TextStyle(
                    color: c.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final goal = past[index];
                return _GoalHistoryTile(
                  goal: goal,
                  statusColor: _statusColor(goal.status),
                  statusIcon: _statusIcon(goal.status),
                  weekLabel: _weekLabel(goal.weekStart),
                );
              }, childCount: past.length),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private Widgets
// ═══════════════════════════════════════════════════════════════════════

class _ActiveGoalCard extends StatelessWidget {
  final WeeklyGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onIncomplete;
  final VoidCallback onInProgress;

  const _ActiveGoalCard({
    required this.goal,
    required this.onEdit,
    required this.onComplete,
    required this.onIncomplete,
    required this.onInProgress,
  });

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Goal',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_rounded,
                    color: c.textTertiary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            goal.goalText,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Complete',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  onTap: onComplete,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'In Progress',
                  icon: Icons.timelapse_rounded,
                  color: Colors.amber,
                  onTap: onInProgress,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: "Didn't",
                  icon: Icons.cancel_rounded,
                  color: Colors.redAccent,
                  onTap: onIncomplete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetGoalCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SetGoalCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.surfaceLighter, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Set a goal for this week',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Optional — tap to set one',
              style: TextStyle(color: c.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalHistoryTile extends StatelessWidget {
  final WeeklyGoal goal;
  final Color statusColor;
  final IconData statusIcon;
  final String? weekLabel;

  const _GoalHistoryTile({
    required this.goal,
    required this.statusColor,
    required this.statusIcon,
    this.weekLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.goalText,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    weekLabel ?? goal.status.label,
                    style: TextStyle(color: c.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                goal.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

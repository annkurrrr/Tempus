import 'package:flutter/material.dart';
import '../models/weekly_goal.dart';
import '../services/api_key_storage.dart';
import '../services/gemini_service.dart';
import '../services/goal_storage.dart';
import '../theme/app_theme.dart';

/// Screen where the user can generate an AI-powered schedule for their goal.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _loading = true;
  bool _generating = false;
  bool _hasApiKey = false;
  String? _schedule;
  String? _error;
  WeeklyGoal? _activeGoal;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasKey = await ApiKeyStorage.hasApiKey();
    final goals = GoalStorage.loadCachedGoals();
    final monday = GoalStorage.mondayOf(DateTime.now());
    final thisWeek = goals.where(
      (g) =>
          g.weekStart.year == monday.year &&
          g.weekStart.month == monday.month &&
          g.weekStart.day == monday.day &&
          !g.isResolved,
    );

    final activeGoal = thisWeek.isNotEmpty ? thisWeek.last : null;

    // Load previously generated schedule for this goal.
    String? savedSchedule;
    if (activeGoal != null) {
      savedSchedule = await GoalStorage.loadSchedule(activeGoal.id);
    }

    setState(() {
      _hasApiKey = hasKey;
      _activeGoal = activeGoal;
      _schedule = savedSchedule;
      _loading = false;
    });
  }

  int get _daysRemaining {
    final now = DateTime.now();
    // Sunday = 7 in ISO, Monday = 1.
    // Days remaining = 7 - weekday (Mon=1 → 6 days left, Sun=7 → 0 days).
    return 7 - now.weekday;
  }

  Future<void> _showApiKeyDialog() async {
    final c = TempusColors.of(context);
    final controller = TextEditingController();
    final existing = await ApiKeyStorage.loadApiKey();
    if (existing != null) controller.text = existing;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Gemini API Key',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Google Gemini API key to enable AI-powered schedules.',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Get one free at aistudio.google.com',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: const InputDecoration(hintText: 'AIza...'),
              obscureText: true,
              maxLines: 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final key = controller.text.trim();
              if (key.isEmpty) return;
              Navigator.pop(ctx, key);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ApiKeyStorage.saveApiKey(result);
      setState(() => _hasApiKey = true);
    }
  }

  Future<void> _generateSchedule() async {
    if (_activeGoal == null) return;

    final apiKey = await ApiKeyStorage.loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      await _showApiKeyDialog();
      final recheckKey = await ApiKeyStorage.loadApiKey();
      if (recheckKey == null || recheckKey.isEmpty) return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _schedule = null;
    });

    try {
      final key = (await ApiKeyStorage.loadApiKey())!;
      final result = await GeminiService.generateSchedule(
        apiKey: key,
        goalText: _activeGoal!.goalText,
        daysRemaining: _daysRemaining,
        userContext:
            'Today is ${_dayName(DateTime.now().weekday)}. The goal was set on ${_dayName(_activeGoal!.createdAt.weekday)}.',
      );
      setState(() {
        _schedule = result;
        _generating = false;
      });
      // Persist the schedule so it survives navigation.
      await GoalStorage.saveSchedule(_activeGoal!.id, result);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _generating = false;
      });
    }
  }

  String _dayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tempus AI',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showApiKeyDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.key_rounded,
                        color: _hasApiKey ? AppTheme.primary : c.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(height: 16, color: c.surfaceLighter),
          ),

          // ── No Goal State ────────────────────────────────────────
          if (_activeGoal == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 56,
                        color: c.textTertiary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active goal',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Set a weekly goal first, then come here to generate an AI-powered schedule.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Active Goal + Generate Button ────────────────────────
          if (_activeGoal != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Goal',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: c.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_daysRemaining days left',
                              style: TextStyle(
                                color: c.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _activeGoal!.goalText,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: _generating
                              ? AppTheme.primary.withValues(alpha: 0.3)
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _generating ? null : _generateSchedule,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_generating)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _generating
                                        ? 'Generating...'
                                        : 'Generate Schedule',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Error State ────────────────────────────────────────
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Schedule Result ────────────────────────────────────
            if (_schedule != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your Schedule',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _generateSchedule,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: c.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  color: c.textTertiary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ScheduleContent(text: _schedule!),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Bottom padding if no schedule yet ──────────────────
            if (_schedule == null && _error == null && !_generating)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 48,
                          color: c.textTertiary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tap "Generate Schedule" to get a personalised daily plan from AI.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Renders the schedule text with simple styling.
class _ScheduleContent extends StatelessWidget {
  final String text;
  const _ScheduleContent({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 8);

        // Day headers (lines ending with colon or starting with Day/Monday etc.)
        final isDayHeader = _isDayHeader(trimmed);

        return Padding(
          padding: EdgeInsets.only(
            bottom: 4,
            left:
                trimmed.startsWith('•') ||
                    trimmed.startsWith('–') ||
                    trimmed.startsWith('-')
                ? 8
                : 0,
          ),
          child: Text(
            trimmed,
            style: TextStyle(
              color: isDayHeader ? AppTheme.primary : c.textPrimary,
              fontSize: isDayHeader ? 15 : 14,
              fontWeight: isDayHeader ? FontWeight.w700 : FontWeight.w400,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isDayHeader(String line) {
    final lower = line.toLowerCase();
    final dayPatterns = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
      'day 1',
      'day 2',
      'day 3',
      'day 4',
      'day 5',
      'day 6',
      'day 7',
      'insights',
      'tips',
      'motivation',
    ];
    for (final pattern in dayPatterns) {
      if (lower.startsWith(pattern)) return true;
    }
    return false;
  }
}

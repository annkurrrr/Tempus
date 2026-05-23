import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../main.dart';
import '../models/session.dart';
import '../services/session_storage.dart';
import '../services/timer_notification_service.dart';
import '../services/widget_service.dart';
import '../services/session_sync_service.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/timer_display.dart';
import '../widgets/timer_controls.dart';
import '../widgets/streak_counter.dart';
import '../widgets/weekly_stats.dart';
import '../widgets/productivity_calendar.dart';

/// The main home screen with the timer, streak counter, and productivity calendar.
class HomeScreen extends StatefulWidget {
  final VoidCallback onSessionSaved;
  final List<Session> sessions;

  const HomeScreen({
    super.key,
    required this.onSessionSaved,
    required this.sessions,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _hasStarted = false;
  DateTime? _sessionStartTime;
  int _accumulatedBeforePause = 0;
  DateTime? _segmentStart;

  late AnimationController _pulseController;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _restoreTimerState();

    // Listen for data from the foreground task (e.g. pause button press).
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Called when the foreground-service isolate sends data back.
  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      final action = data['action'];
      if (action == 'pause' && _isRunning) {
        _pause();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistTimerState();
      // Start the foreground notification if the timer is running.
      if (_isRunning) {
        _startForegroundNotification();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Stop the foreground notification when the user returns.
      TimerNotificationService.stopNotification();
      _recalculateElapsed();
    }
  }

  // ── Foreground notification helpers ──────────────────────────────────

  Future<void> _requestPermissionsIfNeeded() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    await TimerNotificationService.requestPermissions();
  }

  Future<void> _startForegroundNotification() async {
    final nextNum = widget.sessions.length + 1;
    await TimerNotificationService.startNotification(
      sessionNumber: nextNum,
    );
  }

  // ── Persistence helpers ─────────────────────────────────────────────

  Future<void> _restoreTimerState() async {
    final saved = await SessionStorage.loadTimerState();
    if (saved == null || saved.sessionStart == null) return;
    setState(() {
      _sessionStartTime = saved.sessionStart;
      _accumulatedBeforePause = saved.accumulatedSeconds;
      _hasStarted = true;
      if (saved.isRunning && saved.segmentStart != null) {
        _segmentStart = saved.segmentStart;
        _isRunning = true;
        _elapsed = saved.totalElapsed;
        _startTicking();
        _pulseController.repeat(reverse: true);
      } else {
        _isRunning = false;
        _elapsed = Duration(seconds: saved.accumulatedSeconds);
      }
    });

    // If the timer was running when the app was killed, the foreground service
    // may still be active — stop it now that the UI is back.
    if (_isRunning) {
      TimerNotificationService.stopNotification();
    }
  }

  Future<void> _persistTimerState() async {
    if (!_hasStarted) {
      await SessionStorage.clearTimerState();
      return;
    }
    await SessionStorage.saveTimerState(
      isRunning: _isRunning,
      accumulatedSeconds:
          _isRunning ? _accumulatedBeforePause : _elapsed.inSeconds,
      segmentStart: _isRunning ? _segmentStart : null,
      sessionStart: _sessionStartTime,
    );
  }

  void _recalculateElapsed() {
    if (!_isRunning || _segmentStart == null) return;
    final now = DateTime.now();
    final segmentSeconds = now.difference(_segmentStart!).inSeconds;
    setState(() {
      _elapsed =
          Duration(seconds: _accumulatedBeforePause + segmentSeconds);
    });
    // Push live elapsed time to the home screen widget.
    WidgetService.updateTimerElapsed(_formatDuration(_elapsed));
  }

  // ── Timer actions ───────────────────────────────────────────────────

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recalculateElapsed();
    });
  }

  void _start() {
    _requestPermissionsIfNeeded();
    final now = DateTime.now();
    setState(() {
      _hasStarted = true;
      _isRunning = true;
      _sessionStartTime = now;
      _segmentStart = now;
      _accumulatedBeforePause = 0;
      _elapsed = Duration.zero;
    });
    _pulseController.repeat(reverse: true);
    _startTicking();
    _persistTimerState();
    _updateWidget('running');
  }

  void _pause() {
    _timer?.cancel();
    _pulseController.stop();
    final segmentSeconds = _segmentStart != null
        ? DateTime.now().difference(_segmentStart!).inSeconds
        : 0;
    _accumulatedBeforePause += segmentSeconds;
    setState(() {
      _isRunning = false;
      _elapsed = Duration(seconds: _accumulatedBeforePause);
      _segmentStart = null;
    });
    _persistTimerState();
    // Stop the foreground notification when paused.
    TimerNotificationService.stopNotification();
    _updateWidget('paused');
  }

  void _resume() {
    _requestPermissionsIfNeeded();
    final now = DateTime.now();
    setState(() {
      _isRunning = true;
      _segmentStart = now;
    });
    _pulseController.repeat(reverse: true);
    _startTicking();
    _persistTimerState();
    _updateWidget('running');
  }

  void _save() {
    if (_elapsed.inSeconds == 0) return;
    _pause();
    _showSaveDialog();
  }

  Future<void> _showSaveDialog() async {
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    final c = TempusColors.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Save Session',
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: c.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(color: c.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Session name *'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                style: TextStyle(color: c.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Comment (optional)'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a session name'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final nextNum = SessionStorage.getNextSessionNumber();
      final now = DateTime.now();
      final session = Session(
        sessionNumber: nextNum,
        sessionName: nameController.text.trim(),
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
        startTime: _sessionStartTime!,
        endTime: now,
        totalDuration: _elapsed,
        date: _sessionStartTime!,
      );
      await SessionStorage.saveSession(session);
      await SessionStorage.clearTimerState();

      // Sync to Supabase (fire-and-forget, don't block UI).
      SessionSyncService.saveSession(session).catchError((e) {
        debugPrint('Supabase sync failed: $e');
      });

      setState(() {
        _elapsed = Duration.zero;
        _isRunning = false;
        _hasStarted = false;
        _sessionStartTime = null;
        _segmentStart = null;
        _accumulatedBeforePause = 0;
      });

      widget.onSessionSaved();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session #$nextNum saved!'),
            backgroundColor: AppTheme.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Pushes current timer state to home screen widgets.
  void _updateWidget(String status) {
    final nextNum = widget.sessions.length + 1;
    WidgetService.updateWidgets(
      sessions: widget.sessions,
      timerStatus: status,
      timerElapsed: _formatDuration(_elapsed),
      currentSessionNum: nextNum,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context, TempusColors c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out?',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to sign out?',
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
              AuthService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = TempusColors.of(context);
    final appState = MyApp.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _confirmLogout(context, c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: c.textTertiary,
                      size: 22,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.hourglass_top_rounded,
                    color: AppTheme.primary, size: 26),
                const SizedBox(width: 8),
                Text(
                  'TEMPUS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: appState.toggleTheme,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      appState.isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Track your productivity',
              style: TextStyle(
                color: c.textTertiary,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 36),
            TimerDisplay(elapsed: _elapsed, isRunning: _isRunning),
            const SizedBox(height: 30),
            TimerControls(
              isRunning: _isRunning,
              hasStarted: _hasStarted,
              onStart: _start,
              onPause: _pause,
              onResume: _resume,
              onSave: _save,
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: StreakCounter(sessions: widget.sessions),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: WeeklyStats(sessions: widget.sessions),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ProductivityCalendar(sessions: widget.sessions),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

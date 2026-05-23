import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';
import 'session_sync_service.dart';

/// Handles session access through Supabase and persistent storage for timer state.
class SessionStorage {

  // ── Timer persistence keys ────────────────────────────────────────────
  static const String _timerRunningKey = 'tempus_timer_running';
  static const String _timerAccumulatedKey = 'tempus_timer_accumulated_secs';
  static const String _timerSegmentStartKey = 'tempus_timer_segment_start';
  static const String _timerSessionStartKey = 'tempus_timer_session_start';

  // ── Session CRUD ──────────────────────────────────────────────────────

  /// Loads all saved sessions from Supabase.
  static Future<List<Session>> loadSessions() async {
    return await SessionSyncService.loadSessions();
  }

  /// Saves a new session to Supabase and returns the updated list.
  static Future<List<Session>> saveSession(Session session) async {
    await SessionSyncService.saveSession(session);
    return loadSessions();
  }

  /// Returns the next session number (auto-increment).
  static Future<int> getNextSessionNumber() async {
    final sessions = await loadSessions();
    if (sessions.isEmpty) return 1;
    return sessions.last.sessionNumber + 1;
  }

  /// Deletes a session by its session number and renumbers the rest in Supabase.
  static Future<List<Session>> deleteSession(int sessionNumber) async {
    await SessionSyncService.deleteSession(sessionNumber);
    return loadSessions();
  }

  // ── Timer State Persistence ───────────────────────────────────────────
  //
  // The timer state is stored as:
  //   - isRunning: whether the timer is actively counting
  //   - accumulatedSeconds: total seconds accumulated in previous segments
  //     (before pauses)
  //   - segmentStart: ISO8601 timestamp when the current running segment began
  //     (only meaningful when isRunning == true)
  //   - sessionStart: ISO8601 timestamp when the user first pressed Start

  /// Saves the current timer state so it persists across app restarts.
  static Future<void> saveTimerState({
    required bool isRunning,
    required int accumulatedSeconds,
    DateTime? segmentStart,
    DateTime? sessionStart,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_timerRunningKey, isRunning);
    await prefs.setInt(_timerAccumulatedKey, accumulatedSeconds);
    if (segmentStart != null) {
      await prefs.setString(
          _timerSegmentStartKey, segmentStart.toIso8601String());
    } else {
      await prefs.remove(_timerSegmentStartKey);
    }
    if (sessionStart != null) {
      await prefs.setString(
          _timerSessionStartKey, sessionStart.toIso8601String());
    } else {
      await prefs.remove(_timerSessionStartKey);
    }
  }

  /// Loads the persisted timer state. Returns null values if no state exists.
  static Future<TimerState?> loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasState = prefs.containsKey(_timerRunningKey);
    if (!hasState) return null;

    final isRunning = prefs.getBool(_timerRunningKey) ?? false;
    final accumulated = prefs.getInt(_timerAccumulatedKey) ?? 0;
    final segStr = prefs.getString(_timerSegmentStartKey);
    final sessStr = prefs.getString(_timerSessionStartKey);

    return TimerState(
      isRunning: isRunning,
      accumulatedSeconds: accumulated,
      segmentStart: segStr != null ? DateTime.parse(segStr) : null,
      sessionStart: sessStr != null ? DateTime.parse(sessStr) : null,
    );
  }

  /// Clears all persisted timer state (used after saving a session).
  static Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerRunningKey);
    await prefs.remove(_timerAccumulatedKey);
    await prefs.remove(_timerSegmentStartKey);
    await prefs.remove(_timerSessionStartKey);
  }
}

/// A snapshot of the persisted timer state.
class TimerState {
  final bool isRunning;
  final int accumulatedSeconds;
  final DateTime? segmentStart;
  final DateTime? sessionStart;

  const TimerState({
    required this.isRunning,
    required this.accumulatedSeconds,
    this.segmentStart,
    this.sessionStart,
  });

  /// Computes the total elapsed duration, including time that passed
  /// while the app was closed (if the timer was running).
  Duration get totalElapsed {
    int total = accumulatedSeconds;
    if (isRunning && segmentStart != null) {
      total += DateTime.now().difference(segmentStart!).inSeconds;
    }
    return Duration(seconds: total);
  }
}

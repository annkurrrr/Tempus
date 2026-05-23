import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';
import '../models/weekly_goal.dart';

/// Handles extremely fast local persistence of data to allow the app
/// to load instantly and function offline.
class LocalCacheService {
  LocalCacheService._();

  static const String _sessionsBox = 'sessions_box';
  static const String _goalsBox = 'goals_box';

  static const String _sessionsKey = 'sessions_list';
  static const String _goalsKey = 'goals_list';

  /// Initializes Hive and opens the required boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<List<String>>(_sessionsBox);
    await Hive.openBox<List<String>>(_goalsBox);
  }

  // ── Sessions ────────────────────────────────────────────────────────

  /// Instantly loads sessions from the local Hive cache.
  static List<Session> loadCachedSessions() {
    final box = Hive.box<List<String>>(_sessionsBox);
    final jsonList = box.get(_sessionsKey, defaultValue: <String>[]);
    if (jsonList == null) return [];
    
    final sessions = jsonList.map((e) => Session.decode(e)).toList();
    sessions.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    return sessions;
  }

  /// Saves the full list of sessions to the local cache.
  static Future<void> cacheSessions(List<Session> sessions) async {
    final box = Hive.box<List<String>>(_sessionsBox);
    final jsonList = sessions.map((e) => e.encode()).toList();
    await box.put(_sessionsKey, jsonList);
  }

  // ── Goals ───────────────────────────────────────────────────────────

  /// Instantly loads goals from the local Hive cache.
  static List<WeeklyGoal> loadCachedGoals() {
    final box = Hive.box<List<String>>(_goalsBox);
    final jsonList = box.get(_goalsKey, defaultValue: <String>[]);
    if (jsonList == null) return [];

    final goals = jsonList.map((e) => WeeklyGoal.decode(e)).toList();
    goals.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return goals;
  }

  /// Saves the full list of goals to the local cache.
  static Future<void> cacheGoals(List<WeeklyGoal> goals) async {
    final box = Hive.box<List<String>>(_goalsBox);
    final jsonList = goals.map((e) => e.encode()).toList();
    await box.put(_goalsKey, jsonList);
  }
}

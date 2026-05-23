import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_goal.dart';
import 'goal_sync_service.dart';
import 'local_cache_service.dart';

/// Handles goals access through local cache first, then Supabase.
class GoalStorage {

  /// Returns the Monday 00:00 of the week containing [date].
  static DateTime mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Instantly loads goals from the local cache.
  static List<WeeklyGoal> loadCachedGoals() {
    return LocalCacheService.loadCachedGoals();
  }

  /// Fetches goals from Supabase and updates the local cache.
  static Future<List<WeeklyGoal>> syncGoals() async {
    final goals = await GoalSyncService.loadGoals();
    await LocalCacheService.cacheGoals(goals);
    return goals;
  }

  /// Adds a new goal locally and syncs to Supabase.
  static Future<void> addGoal(WeeklyGoal goal) async {
    final cached = loadCachedGoals();
    cached.add(goal);
    await LocalCacheService.cacheGoals(cached);

    GoalSyncService.saveGoal(goal).catchError((e) {
      debugPrint('Supabase goal save sync failed: $e');
    });
  }

  /// Updates an existing goal (matched by id) locally and syncs to Supabase.
  static Future<void> updateGoal(WeeklyGoal updated) async {
    final cached = loadCachedGoals();
    final idx = cached.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      cached[idx] = updated;
      await LocalCacheService.cacheGoals(cached);
    }

    GoalSyncService.updateGoal(updated).catchError((e) {
      debugPrint('Supabase goal update sync failed: $e');
    });
  }

  /// Deletes a goal by id locally and syncs to Supabase.
  static Future<void> deleteGoal(String id) async {
    final cached = loadCachedGoals();
    cached.removeWhere((g) => g.id == id);
    await LocalCacheService.cacheGoals(cached);

    GoalSyncService.deleteGoal(id).catchError((e) {
      debugPrint('Supabase goal delete sync failed: $e');
    });
  }

  /// Returns all goals for the week containing [date] from local cache.
  static List<WeeklyGoal> goalsForWeek(DateTime date) {
    final monday = mondayOf(date);
    final goals = loadCachedGoals();
    return goals
        .where(
          (g) =>
              g.weekStart.year == monday.year &&
              g.weekStart.month == monday.month &&
              g.weekStart.day == monday.day,
        )
        .toList();
  }

  /// Returns all unresolved goals from previous weeks (before [currentMonday]) from local cache.
  static List<WeeklyGoal> unresolvedPastGoals(
    DateTime currentMonday,
  ) {
    final goals = loadCachedGoals();
    return goals
        .where((g) => g.weekStart.isBefore(currentMonday) && !g.isResolved)
        .toList();
  }

  // ── AI Schedule Persistence ───────────────────────────────────────────
  static const String _scheduleKey = 'tempus_ai_schedule';
  static const String _scheduleGoalIdKey = 'tempus_ai_schedule_goal_id';

  /// Saves the generated schedule text, linked to a specific goal ID.
  static Future<void> saveSchedule(String goalId, String schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scheduleKey, schedule);
    await prefs.setString(_scheduleGoalIdKey, goalId);
  }

  /// Loads the saved schedule if it matches the given goal ID.
  /// Returns null if no schedule exists or it belongs to a different goal.
  static Future<String?> loadSchedule(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedGoalId = prefs.getString(_scheduleGoalIdKey);
    if (savedGoalId != goalId) return null;
    return prefs.getString(_scheduleKey);
  }

  /// Clears the saved schedule (called when a goal is resolved).
  static Future<void> clearSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scheduleKey);
    await prefs.remove(_scheduleGoalIdKey);
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_goal.dart';
import 'goal_sync_service.dart';

/// Handles goals access through Supabase and persistent storage for AI schedules.
class GoalStorage {

  /// Returns the Monday 00:00 of the week containing [date].
  static DateTime mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Loads all saved goals from Supabase, sorted by weekStart (oldest first).
  static Future<List<WeeklyGoal>> loadGoals() async {
    return await GoalSyncService.loadGoals();
  }

  /// Adds a new goal to Supabase.
  static Future<void> addGoal(WeeklyGoal goal) async {
    await GoalSyncService.saveGoal(goal);
  }

  /// Updates an existing goal (matched by id) in Supabase.
  static Future<void> updateGoal(WeeklyGoal updated) async {
    await GoalSyncService.updateGoal(updated);
  }

  /// Deletes a goal by id from Supabase.
  static Future<void> deleteGoal(String id) async {
    await GoalSyncService.deleteGoal(id);
  }

  /// Returns all goals for the week containing [date].
  static Future<List<WeeklyGoal>> goalsForWeek(DateTime date) async {
    final monday = mondayOf(date);
    final goals = await loadGoals();
    return goals
        .where(
          (g) =>
              g.weekStart.year == monday.year &&
              g.weekStart.month == monday.month &&
              g.weekStart.day == monday.day,
        )
        .toList();
  }

  /// Returns all unresolved goals from previous weeks (before [currentMonday]).
  static Future<List<WeeklyGoal>> unresolvedPastGoals(
    DateTime currentMonday,
  ) async {
    final goals = await loadGoals();
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

import 'package:shared_preferences/shared_preferences.dart';
import '../models/weekly_goal.dart';

/// Handles persistent storage of weekly goals.
class GoalStorage {
  static const String _goalsKey = 'tempus_weekly_goals';

  /// Returns the Monday 00:00 of the week containing [date].
  static DateTime mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Loads all saved goals, sorted by weekStart (oldest first).
  static Future<List<WeeklyGoal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_goalsKey) ?? [];
    final goals = list.map((e) => WeeklyGoal.decode(e)).toList();
    goals.sort((a, b) => a.weekStart.compareTo(b.weekStart));
    return goals;
  }

  static Future<void> _saveAll(List<WeeklyGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _goalsKey, goals.map((g) => g.encode()).toList());
  }

  /// Adds a new goal and persists.
  static Future<void> addGoal(WeeklyGoal goal) async {
    final goals = await loadGoals();
    goals.add(goal);
    await _saveAll(goals);
  }

  /// Updates an existing goal (matched by id).
  static Future<void> updateGoal(WeeklyGoal updated) async {
    final goals = await loadGoals();
    final idx = goals.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      goals[idx] = updated;
      await _saveAll(goals);
    }
  }

  /// Deletes a goal by id.
  static Future<void> deleteGoal(String id) async {
    final goals = await loadGoals();
    goals.removeWhere((g) => g.id == id);
    await _saveAll(goals);
  }

  /// Returns all goals for the week containing [date].
  static Future<List<WeeklyGoal>> goalsForWeek(DateTime date) async {
    final monday = mondayOf(date);
    final goals = await loadGoals();
    return goals
        .where((g) =>
            g.weekStart.year == monday.year &&
            g.weekStart.month == monday.month &&
            g.weekStart.day == monday.day)
        .toList();
  }

  /// Returns all unresolved goals from previous weeks (before [currentMonday]).
  static Future<List<WeeklyGoal>> unresolvedPastGoals(
      DateTime currentMonday) async {
    final goals = await loadGoals();
    return goals
        .where((g) =>
            g.weekStart.isBefore(currentMonday) && !g.isResolved)
        .toList();
  }
}

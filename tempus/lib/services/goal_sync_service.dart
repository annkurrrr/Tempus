import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_goal.dart';

/// Syncs goals to the Supabase `weekly_goals` table.
/// Works alongside local SharedPreferences storage — Supabase is the
/// remote source of truth, local storage is the offline cache.
class GoalSyncService {
  GoalSyncService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Inserts a new goal into the remote database.
  static Future<void> saveGoal(WeeklyGoal goal) async {
    await _client.from('weekly_goals').insert({
      'id': goal.id,
      'goal_text': goal.goalText,
      'week_start': goal.weekStart.toIso8601String(),
      'created_at': goal.createdAt.toIso8601String(),
      'status': goal.status.name,
      'status_changed_at': goal.statusChangedAt?.toIso8601String(),
    });
  }

  /// Updates an existing goal in the remote database.
  static Future<void> updateGoal(WeeklyGoal goal) async {
    await _client.from('weekly_goals').update({
      'goal_text': goal.goalText,
      'week_start': goal.weekStart.toIso8601String(),
      'status': goal.status.name,
      'status_changed_at': goal.statusChangedAt?.toIso8601String(),
    }).eq('id', goal.id);
  }

  /// Deletes a goal from the remote database by id.
  static Future<void> deleteGoal(String id) async {
    await _client.from('weekly_goals').delete().eq('id', id);
  }

  /// Fetches all goals for the current user from Supabase.
  static Future<List<WeeklyGoal>> loadGoals() async {
    final data = await _client
        .from('weekly_goals')
        .select()
        .order('week_start', ascending: true);

    return data.map<WeeklyGoal>((row) {
      return WeeklyGoal(
        id: row['id'] as String,
        goalText: row['goal_text'] as String,
        weekStart: DateTime.parse(row['week_start'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
        status: GoalStatus.values.byName(row['status'] as String),
        statusChangedAt: row['status_changed_at'] != null
            ? DateTime.parse(row['status_changed_at'] as String)
            : null,
      );
    }).toList();
  }
}

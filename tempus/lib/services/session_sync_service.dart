import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/session.dart';

/// Syncs sessions to the Supabase `sessions` table.
/// Works alongside local SharedPreferences storage — Supabase is the
/// remote source of truth, local storage is the offline cache.
class SessionSyncService {
  SessionSyncService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Inserts a session into the remote database.
  /// The `user_id` column is auto-filled by Supabase via `auth.uid()`.
  static Future<void> saveSession(Session session) async {
    await _client.from('sessions').insert({
      'session_number': session.sessionNumber,
      'session_name': session.sessionName,
      'comment': session.comment,
      'start_time': session.startTime.toIso8601String(),
      'end_time': session.endTime.toIso8601String(),
      'total_duration_seconds': session.totalDuration.inSeconds,
      'session_date': session.date.toIso8601String(),
    });
  }

  /// Deletes a session by its session number for the current user,
  /// then renumbers remaining sessions to close gaps.
  static Future<void> deleteSession(int sessionNumber) async {
    await _client.from('sessions').delete().eq('session_number', sessionNumber);

    // Renumber remaining sessions sequentially.
    final remaining = await _client
        .from('sessions')
        .select()
        .order('session_number', ascending: true);

    for (int i = 0; i < remaining.length; i++) {
      final row = remaining[i];
      final newNum = i + 1;
      if (row['session_number'] != newNum) {
        await _client
            .from('sessions')
            .update({'session_number': newNum})
            .eq('id', row['id']);
      }
    }
  }

  /// Fetches all sessions for the current user from Supabase.
  static Future<List<Session>> loadSessions() async {
    final data = await _client
        .from('sessions')
        .select()
        .order('session_number', ascending: true);

    return data.map<Session>((row) {
      return Session(
        sessionNumber: row['session_number'] as int,
        sessionName: row['session_name'] as String,
        comment: row['comment'] as String?,
        startTime: DateTime.parse(row['start_time'] as String),
        endTime: DateTime.parse(row['end_time'] as String),
        totalDuration: Duration(seconds: row['total_duration_seconds'] as int),
        date: DateTime.parse(row['session_date'] as String),
      );
    }).toList();
  }
}

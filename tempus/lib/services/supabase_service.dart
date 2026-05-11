import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase configuration and access.
class SupabaseService {
  SupabaseService._();

  static const String _supabaseUrl = 'https://ophrjrfmsgqwjncibtoh.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_TqHi2hAh_uyhHnPmcrxpRw_BOiFfWoX';

  /// Initialize Supabase. Call once at app startup.
  static Future<void> init() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Convenience accessor for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}

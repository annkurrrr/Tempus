import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase authentication operations.
class AuthService {
  AuthService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// The currently signed-in user, or null.
  static User? get currentUser => _client.auth.currentUser;

  /// Whether there is an active session.
  static bool get isLoggedIn => currentUser != null;

  /// Stream of auth state changes (login, logout, token refresh, etc.).
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ── Sign Up ─────────────────────────────────────────────────────────

  /// Creates a new user with email & password, then inserts a row into
  /// the public `users` table with their username and email.
  ///
  /// Throws an [AuthException] on failure.
  static Future<AuthResponse> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    // 1. Create user in Supabase Auth.
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    // 2. Insert into public.users table.
    if (response.user != null) {
      await _client.from('users').insert({
        'username': username,
        'email': email,
      });
    }

    return response;
  }

  // ── Sign In ─────────────────────────────────────────────────────────

  /// Signs in with email and password.
  ///
  /// Throws an [AuthException] on failure.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Sign Out ────────────────────────────────────────────────────────

  /// Signs out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Password Reset ──────────────────────────────────────────────────

  /// Sends a password reset email.
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}

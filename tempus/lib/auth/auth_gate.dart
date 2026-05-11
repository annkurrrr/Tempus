import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import '../screens/auth_screen.dart';

/// Listens to Supabase auth state and switches between the auth screen
/// and the authenticated app shell.
///
/// [authenticatedBuilder] builds the main app when a user is logged in.
class AuthGate extends StatelessWidget {
  final Widget Function() authenticatedBuilder;

  const AuthGate({super.key, required this.authenticatedBuilder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // While waiting for the first event, check the current session.
        if (!snapshot.hasData) {
          return AuthService.isLoggedIn
              ? authenticatedBuilder()
              : const AuthScreen();
        }

        final session = snapshot.data!.session;
        if (session != null) {
          return authenticatedBuilder();
        }
        return const AuthScreen();
      },
    );
  }
}

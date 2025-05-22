import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../homepage.dart'; // Import your HomePage
import '../login.dart'; // Import your LoginPage

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading indicator while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if there is a valid session currently
        final session = snapshot.data?.session;
        if (session != null) {
          // Authenticated, navigate to HomePage
          return HomePage();
        } else {
          // Not authenticated, navigate to LoginPage
          return LoginPage();
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../services/auth_storage.dart';
import 'login.dart';
import 'menu.dart';

/// Decides the first screen on launch: if a JWT is already stored, go straight
/// to the menu; otherwise show the login screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthStorage.readToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final token = snapshot.data;
        return (token == null || token.isEmpty) ? const LoginPage() : const Menu();
      },
    );
  }
}

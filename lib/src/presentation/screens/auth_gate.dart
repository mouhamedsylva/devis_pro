/// AuthGate – décide quel écran afficher selon l'état d'auth.
///
/// Tant que l'utilisateur n'a pas fait "Déconnexion", on le redirige vers
/// le dashboard (session restaurée via SharedPreferences).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
          case AuthStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.unauthenticated:
          case AuthStatus.failure:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return const DashboardScreen();
        }
      },
    );
  }
}


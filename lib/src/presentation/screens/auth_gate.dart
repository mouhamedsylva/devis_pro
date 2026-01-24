/// AuthGate – décide quel écran afficher selon l'état d'auth.
///
/// Affiche d'abord le splash screen animé, puis redirige vers le bon écran
/// selon l'état d'authentification.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Le splash screen gère sa propre durée et navigation
    // Mais on peut aussi le masquer après un délai si nécessaire
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Toujours afficher le splash screen au premier lancement
    if (_showSplash) {
      return const SplashScreen();
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
          case AuthStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.unauthenticated:
          case AuthStatus.failure:
          case AuthStatus.otpSent:
          case AuthStatus.otpVerifying:
          case AuthStatus.checkingDatabase:
          case AuthStatus.preparingOTP:
          case AuthStatus.sendingEmail:
            return const LoginScreen();
          case AuthStatus.authenticated:
            return const DashboardScreen();
        }
      },
    );
  }
}


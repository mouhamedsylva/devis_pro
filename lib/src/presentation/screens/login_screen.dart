/// LoginScreen – Auth par numéro de téléphone.
///
/// Pour le MVP offline, c'est un "login ou inscription" (si le numéro n'existe
/// pas, on crée l'utilisateur).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        // La navigation est gérée par AuthGate; ici on affiche uniquement les erreurs.
        if (state.status == AuthStatus.failure && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('DevisPro')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Connexion',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('Entrez votre numéro. Si c’est la première fois, le compte sera créé.'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneCtrl,
                label: 'Numéro de téléphone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final loading = state.status == AuthStatus.loading;
                  return ElevatedButton(
                    onPressed: loading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(AuthLoginRequested(_phoneCtrl.text));
                          },
                    child: Text(loading ? 'Connexion...' : 'Continuer'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


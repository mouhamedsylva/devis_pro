/// LoginScreen – Auth par numéro de téléphone avec design moderne.
///
/// Design inspiré avec fond gradient, logo et animation de bouton au survol.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../blocs/auth/auth_bloc.dart';
import '../widgets/animated_gradient_button.dart';
import 'otp_verification_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  TabController? _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _phoneFocus.addListener(() {
      setState(() {}); // rebuild quand focus change
    });
    
    // Écouter les changements d'onglet
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging && _tabController!.index == 1) {
        // Si l'utilisateur clique sur l'onglet INSCRIPTION
        // Naviguer vers RegistrationScreen
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistrationScreen(),
            ),
          ).then((_) {
            // Retourner à l'onglet CONNEXION après le retour
            if (mounted && _tabController != null) {
              _tabController!.index = 0;
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        // ✨ Navigation vers OTP si code envoyé (pour connexion)
        if (state.status == AuthStatus.loginOtpSent) {
          // Mode connexion : naviguer vers vérification OTP
          // Normaliser le numéro de téléphone pour qu'il soit cohérent
          final phoneNumber = Formatters.normalizePhoneNumber(_phoneCtrl.text.trim());
          // Utiliser un délai pour s'assurer que le contexte est toujours valide
          Future.microtask(() {
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OTPVerificationScreen(
                    phoneNumber: phoneNumber,
                    isLoginMode: true,
                  ),
                ),
              );
            }
          });
        }
        
        // Message d'échec
        if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message ?? 'Une erreur est survenue',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFD32F2F),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        
        // Message de succès
        if (state.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message ?? 'Connexion réussie !',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2D2D2D), // Noir foncé
                const Color(0xFF2D2D2D).withOpacity(0.95),
                const Color(0xFF3D3D3D), // Gris très foncé
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: isWeb ? 600 : screenWidth * 0.9,
                  padding: EdgeInsets.all(isWeb ? 40 : 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: isWeb ? 300 : 250,
                        height: isWeb ? 100 : 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Si pas de logo, afficher le texte DEVISPRO
                          return Column(
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'DEVIS',
                                      style: TextStyle(
                                        fontSize: isWeb ? 48 : 40,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.yellow,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'PRO',
                                      style: TextStyle(
                                        fontSize: isWeb ? 48 : 40,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Sous-titre
                      Text(
                        'FACILE • RAPIDE • PROFESSIONNEL',
                        style: TextStyle(
                          fontSize: isWeb ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.yellow,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Carte blanche avec le formulaire
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(0),
                          border: Border(
                            top: BorderSide(color: AppColors.yellow, width: 4),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Espacement en haut
                            SizedBox(height: isWeb ? 30 : 24),
                            
                            // Onglets CONNEXION / INSCRIPTION
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                                ),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                labelColor: const Color(0xFF2D2D2D),
                                unselectedLabelColor: const Color(0xFF9E9E9E),
                                labelStyle: TextStyle(
                                  fontSize: isWeb ? 16 : 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    color: AppColors.yellow,
                                    width: 4,
                                  ),
                                  insets: EdgeInsets.symmetric(horizontal: isWeb ? 60 : 40),
                                ),
                                tabs: const [
                                  Tab(text: 'CONNEXION'),
                                  Tab(text: 'INSCRIPTION'),
                                ],
                              ),
                            ),

                            // Contenu de l'onglet (uniquement CONNEXION)
                            SizedBox(
                              height: 400,
                              child: TabBarView(
                                controller: _tabController,
                                physics: const NeverScrollableScrollPhysics(), // Désactiver le swipe
                                children: [
                                  // Onglet CONNEXION
                                  SingleChildScrollView(
                                    padding: EdgeInsets.all(isWeb ? 40 : 30),
                                    child: Form(
                                      key: _formKey,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      child: _buildConnexionTab(context, isWeb),
                                    ),
                                  ),

                                  // Onglet INSCRIPTION (vide car navigation automatique)
                                  Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.yellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnexionTab(BuildContext context, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label
        const Text(
          'NUMÉRO DE TÉLÉPHONE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 12),

        // Indicatif + Champ téléphone
        TextFormField(
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          validator: _validatePhone,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2D2D2D),
          ),
          decoration: InputDecoration(
            // 👇 Placeholder collé à l’icône
            // hintText: '77 123 45 67',
            hintStyle: TextStyle(
              color: const Color(0xFF9E9E9E).withOpacity(0.6),
            ),

            // 👇 +221 visible UNIQUEMENT au focus
            prefixText: _phoneFocus.hasFocus ? '+221 ' : null,
            prefixStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.yellow,
            ),

            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 12),
                const Icon(
                  Icons.phone_android,
                  color: Color(0xFF9E9E9E),
                ),
                if (!_phoneFocus.hasFocus && _phoneCtrl.text.isEmpty) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '77 123 45 67',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),

            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide(color: AppColors.yellow, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Color(0xFFD32F2F)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 32),

        // Bouton SE CONNECTER avec animation
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final loading = state.status == AuthStatus.loading;
            return AnimatedGradientButton(
              onPressed: loading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        final phoneNumber = Formatters.normalizePhoneNumber(_phoneCtrl.text.trim());
                        context.read<AuthBloc>().add(
                              AuthLoginOTPRequested(phoneNumber: phoneNumber),
                            );
                      }
                    },
              text: loading ? 'ENVOI DU CODE...' : 'SE CONNECTER',
              enabled: !loading,
            );
          },
        ),

        const SizedBox(height: 20),

        // Message Email
        const Text(
          'Vous recevrez un code de vérification par email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro est requis';
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 9) {
      return 'Le numéro doit avoir 9 chiffres';
    }
    
    // Prefixes Orange (77, 78), Tigo/Free (76), Expresso (70), Promobile (75)
    final validPrefixes = ['70', '75', '76', '77', '78'];
    final prefix = cleaned.substring(0, 2);
    if (!validPrefixes.contains(prefix)) {
      return 'Numéro invalide (70, 75, 76, 77, 78)';
    }
    return null;
  }
}
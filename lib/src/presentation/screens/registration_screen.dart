/// Écran d'inscription avec validation et envoi OTP.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../blocs/auth/auth_bloc.dart';
import '../widgets/animated_gradient_button.dart';
import 'otp_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _requestOTP() {
    if (_formKey.currentState!.validate()) {
      final email = _emailCtrl.text.trim();
      final companyName = _companyNameCtrl.text.trim();

      // Déclencher la demande d'OTP
      context.read<AuthBloc>().add(
            AuthOTPRequested(
              email: email,
              companyName: companyName,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.otpSent) {
          // Naviguer vers l'écran de vérification OTP
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                email: _emailCtrl.text.trim(),
                companyName: _companyNameCtrl.text.trim(),
                phoneNumber: _phoneCtrl.text.trim(),
              ),
            ),
          );
        } else if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message ?? 'Erreur',
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
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D2D2D),
                Color(0xFF3D3D3D),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWeb ? 40 : 20),
                child: Container(
                  width: isWeb ? 600 : screenWidth * 0.9,
                  padding: EdgeInsets.all(isWeb ? 40 : 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(0),
                    border: const Border(
                      top: BorderSide(color: AppColors.yellow, width: 4),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre
                        Text(
                          'INSCRIPTION',
                          style: TextStyle(
                            fontSize: isWeb ? 28 : 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D2D2D),
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Créez votre compte en quelques étapes',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Nom de l'entreprise
                        _buildLabel('NOM DE L\'ENTREPRISE *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _companyNameCtrl,
                          decoration: _inputDecoration(
                            hintText: 'Ex: Mon Entreprise SARL',
                            icon: Icons.business,
                          ),
                          validator: _validateCompanyName,
                        ),

                        const SizedBox(height: 24),

                        // Email
                        _buildLabel('ADRESSE EMAIL *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            hintText: 'contact@monentreprise.sn',
                            icon: Icons.email,
                          ),
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 24),

                        // Téléphone
                        _buildLabel('NUMÉRO DE TÉLÉPHONE *'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: Row(
                                children: [
                                  Image.network(
                                    'https://flagcdn.com/w40/sn.png',
                                    width: 24,
                                    height: 16,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.flag, size: 20);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '+221',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.yellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  hintText: '77 123 45 67',
                                  icon: Icons.phone_android,
                                ),
                                validator: _validatePhone,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Bouton recevoir le code
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state.status == AuthStatus.loading;
                            return AnimatedGradientButton(
                              onPressed: isLoading ? null : _requestOTP,
                              text: isLoading ? 'ENVOI EN COURS...' : 'RECEVOIR LE CODE',
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Info
                        Text(
                          '📧 Un code de vérification sera envoyé à votre email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isWeb ? 12 : 11,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Lien retour connexion
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Déjà un compte ? Se connecter',
                            style: TextStyle(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D2D2D),
        letterSpacing: 1,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: const Color(0xFF9E9E9E).withOpacity(0.5),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E)),
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
        borderSide: const BorderSide(color: AppColors.yellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(0),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  String? _validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom de l\'entreprise est requis';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro est requis';
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length != 9 || !cleaned.startsWith('7')) {
      return 'Format: 7X XXX XX XX';
    }
    return null;
  }
}

/// Écran de vérification du code OTP avec countdown.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/constants/app_colors.dart';
import '../blocs/auth/auth_bloc.dart';
import '../widgets/animated_gradient_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({
    super.key,
    this.email,
    this.companyName,
    required this.phoneNumber,
    this.isLoginMode = false, // ✨ Mode connexion ou inscription
  });

  final String? email; // Nullable pour mode connexion
  final String? companyName; // Nullable pour mode connexion
  final String phoneNumber;
  final bool isLoginMode;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  int _countdown = 300; // 5 minutes en secondes
  Timer? _timer;
  bool _canResend = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    // Marquer comme disposé AVANT tout
    _disposed = true;
    
    // Annuler le timer immédiatement
    _timer?.cancel();
    _timer = null;
    
    // Disposer le controller de manière sécurisée
    try {
      _otpController.dispose();
    } catch (e) {
      // Ignorer les erreurs de disposal si déjà disposé
      debugPrint('Controller already disposed: $e');
    }
    
    super.dispose();
  }

  void _startCountdown() {
    if (_disposed) return;
    
    _canResend = false;
    _countdown = 300;
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }
      
      if (_countdown > 0) {
        if (mounted && !_disposed) {
          setState(() => _countdown--);
        }
      } else {
        if (mounted && !_disposed) {
          setState(() => _canResend = true);
        }
        timer.cancel();
      }
    });
  }

  void _verifyOTP() {
    if (_disposed || !mounted) return;
    
    try {
      if (_otpController.text.length == 6) {
        final otpCode = _otpController.text;
        
        if (widget.isLoginMode) {
          // ✨ Mode connexion
          context.read<AuthBloc>().add(
                AuthLoginWithOTP(
                  phoneNumber: widget.phoneNumber,
                  otpCode: otpCode,
                ),
              );
        } else {
          // Mode inscription
          context.read<AuthBloc>().add(
                AuthRegistrationRequested(
                  phoneNumber: widget.phoneNumber,
                  email: widget.email!,
                  companyName: widget.companyName!,
                  otpCode: otpCode,
                ),
              );
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
    }
  }

  void _resendOTP() {
    if (_canResend) {
      if (widget.isLoginMode) {
        // ✨ Mode connexion : renvoyer OTP
        context.read<AuthBloc>().add(
              AuthLoginOTPRequested(phoneNumber: widget.phoneNumber),
            );
      } else {
        // Mode inscription
        context.read<AuthBloc>().add(
              AuthResendOTP(
                email: widget.email!,
                companyName: widget.companyName!,
              ),
            );
      }
      _startCountdown();
    }
  }

  String _formatCountdown() {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          // Succès - retour à l'écran principal
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isLoginMode 
                          ? '✅ Connexion réussie !' 
                          : '✅ Inscription réussie !',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF388E3C),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          }
          
          // Retourner à l'écran principal (dashboard)
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        } else if (state.status == AuthStatus.failure) {
          if (mounted) {
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
        } else if (state.status == AuthStatus.otpSent) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.email_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '📧 Nouveau code envoyé !',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1976D2),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          _startCountdown();
          }
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
                  width: isWeb ? 500 : screenWidth * 0.9,
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
                        // Icône email
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.yellow.withOpacity(0.1),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            size: 40,
                            color: AppColors.yellow,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Titre
                        Text(
                          widget.isLoginMode ? 'CONNEXION' : 'VÉRIFICATION',
                          style: TextStyle(
                            fontSize: isWeb ? 28 : 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D2D2D),
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // Instructions
                        Text(
                          widget.isLoginMode 
                              ? 'Un code de vérification a été envoyé à votre email'
                              : 'Un code à 6 chiffres a été envoyé à :',
                          style: TextStyle(
                            fontSize: isWeb ? 14 : 12,
                            color: const Color(0xFF757575),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (!widget.isLoginMode) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.yellow,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Champ OTP avec pin_code_fields
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(0),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeFillColor: Colors.white,
                            inactiveFillColor: const Color(0xFFF5F5F5),
                            selectedFillColor: Colors.white,
                            activeColor: AppColors.yellow,
                            inactiveColor: const Color(0xFFE0E0E0),
                            selectedColor: AppColors.yellow,
                          ),
                          cursorColor: AppColors.yellow,
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          onCompleted: (_) => _verifyOTP(),
                          onChanged: (value) {},
                        ),

                        const SizedBox(height: 24),

                        // Countdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: _countdown > 60
                                  ? const Color(0xFF757575)
                                  : const Color(0xFFD32F2F),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Code valide pendant : ${_formatCountdown()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _countdown > 60
                                    ? const Color(0xFF757575)
                                    : const Color(0xFFD32F2F),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Bouton vérifier
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state.status == AuthStatus.otpVerifying;
                            return AnimatedGradientButton(
                              onPressed: isLoading ? null : _verifyOTP,
                              text: isLoading ? 'VÉRIFICATION...' : 'VÉRIFIER LE CODE',
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Renvoyer le code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Code non reçu ? ',
                              style: TextStyle(
                                fontSize: isWeb ? 13 : 12,
                                color: const Color(0xFF757575),
                              ),
                            ),
                            TextButton(
                              onPressed: _canResend ? _resendOTP : null,
                              child: Text(
                                'Renvoyer',
                                style: TextStyle(
                                  fontSize: isWeb ? 13 : 12,
                                  fontWeight: FontWeight.w700,
                                  color: _canResend
                                      ? AppColors.yellow
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Bouton retour
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, size: 16, color: AppColors.yellow),
                              SizedBox(width: 8),
                              Text(
                                'Modifier mes informations',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.yellow,
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
      ),
    );
  }
}

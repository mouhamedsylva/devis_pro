/// Écran d'inscription avec validation et envoi OTP.
/// Avec onglets CONNEXION/INSCRIPTION pour navigation cohérente
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../blocs/auth/auth_bloc.dart';
import '../widgets/animated_gradient_button.dart';
import 'otp_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  TabController? _tabController;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.index = 1; // Commencer sur l'onglet INSCRIPTION

    _phoneFocus.addListener(() {
      setState(() {});
    });
 
    // Initialiser les animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Démarrer les animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
    
    // Écouter les changements d'onglet
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging && _tabController!.index == 0) {
        // Si l'utilisateur clique sur l'onglet CONNEXION
        // Retourner à l'écran de connexion (pop)
        Future.delayed(Duration.zero, () {
          Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _tabController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  } 

  void _requestOTP() {
    if (_formKey.currentState!.validate()) {
      final email = _emailCtrl.text.trim();
      final companyName = _companyNameCtrl.text.trim();

      // Déclencher la demande d'OTP (avec numéro pour validation précoce)
      final normalizedPhone = Formatters.normalizePhoneNumber(_phoneCtrl.text.trim());
      context.read<AuthBloc>().add(
            AuthOTPRequested(
              email: email,
              companyName: companyName,
              phoneNumber: normalizedPhone,
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
        if (state.status == AuthStatus.registrationOtpSent) {
          // Naviguer vers l'écran de vérification OTP
          // Normaliser le numéro de téléphone pour qu'il soit cohérent
          final normalizedPhone = Formatters.normalizePhoneNumber(_phoneCtrl.text.trim());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                email: _emailCtrl.text.trim(),
                companyName: _companyNameCtrl.text.trim(),
                phoneNumber: normalizedPhone,
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
                child: Container(
                  width: isWeb ? 600 : screenWidth * 0.9,
                  padding: EdgeInsets.all(isWeb ? 40 : 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Circular
                      Container(
                        width: isWeb ? 180 : 150,
                        height: isWeb ? 180 : 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDB913), Color(0xFFFFD700)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo2.png',
                            fit: BoxFit.cover,
                          ),
                        ),
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

                      // Carte blanche avec onglets
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

                            // Contenu de l'onglet (uniquement INSCRIPTION)
                            SizedBox(
                              height: 580, // Augmenté pour le formulaire d'inscription
                              child: TabBarView(
                                controller: _tabController,
                                physics: const NeverScrollableScrollPhysics(), // Désactiver le swipe
                                children: [
                                  // Onglet CONNEXION (vide car navigation automatique)
                                  Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.yellow,
                                    ),
                                  ),

                                  // Onglet INSCRIPTION
                                  SingleChildScrollView(
                                    padding: EdgeInsets.all(isWeb ? 40 : 30),
                                    child: _buildInscriptionTab(context, isWeb),
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

  Widget _buildInscriptionTab(BuildContext context, bool isWeb) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom de l'entreprise
              _buildLabel('NOM DE L\'ENTREPRISE *'),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
                  // +221 seulement au focus
                  prefixText: _phoneFocus.hasFocus ? '+221 ' : null,
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.yellow,
                  ),

                  // Icône + placeholder VISUEL
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),


              const SizedBox(height: 32),

              // Bouton recevoir le code avec Diagnostic
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isChecking = state.status == AuthStatus.checkingDatabase;
                  final isPreparing = state.status == AuthStatus.preparingOTP;
                  final isSending = state.status == AuthStatus.sendingEmail;
                  final isLoading = isChecking || isPreparing || isSending || state.status == AuthStatus.loading;
                  
                  String buttonText = 'RECEVOIR LE CODE';
                  if (isChecking) buttonText = 'VÉRIFICATION...';
                  if (isPreparing) buttonText = 'PRÉPARATION...';
                  if (isSending) buttonText = 'ENVOI DE L\'EMAIL...';
                  if (state.status == AuthStatus.loading) buttonText = 'CHARGEMENT...';

                  return Column(
                    children: [
                      AnimatedGradientButton(
                        onPressed: isLoading ? null : _requestOTP,
                        text: buttonText,
                      ),
                      if (isLoading) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                state.message ?? 'Veuillez patienter...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Info
              Text(
                ' Un code de vérification sera envoyé à votre email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 12 : 11,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
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

    // ✨ Nouvelle validation : Lettres, espaces et symbole '.' seulement
    final companyRegex = RegExp(r'^[a-zA-Z\s\.]+$');
    if (!companyRegex.hasMatch(value.trim())) {
      return 'Lettres, espaces et point (.) seulement';
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

/// BLoC Auth: inscription/connexion par numéro + OTP email (offline).
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/local/auth_session_store.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/otp_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/login_with_phone.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required UserRepository userRepository,
    required OTPRepository otpRepository,
    AuthSessionStore? sessionStore,
  })  : _loginWithPhone = LoginWithPhone(userRepository: userRepository),
        _userRepository = userRepository,
        _otpRepository = otpRepository,
        _sessionStore = sessionStore ?? AuthSessionStore(),
        super(const AuthState.unknown()) {
    on<AuthStarted>((event, emit) async {
      emit(const AuthState.loading());
      final phone = await _sessionStore.getPhone();
      if (phone == null || phone.trim().isEmpty) {
        emit(const AuthState.unauthenticated());
        return;
      }
      final user = await _userRepository.findByPhone(phone.trim());
      if (user == null) {
        await _sessionStore.clear();
        emit(const AuthState.unauthenticated());
        return;
      }
      emit(AuthState.authenticated(user));
    });
    on<AuthLoginRequested>((event, emit) async {
      emit(const AuthState.loading());
      try {
        final user = await _loginWithPhone(event.phoneNumber);
        await _sessionStore.setPhone(user.phoneNumber);
        emit(AuthState.authenticated(user));
      } catch (e) {
        emit(AuthState.failure('Connexion impossible: ${e.toString()}'));
      }
    });
    on<AuthLogoutRequested>((event, emit) async {
      await _sessionStore.clear();
      emit(const AuthState.unauthenticated());
    });
    
    // ✨ Handler pour demande d'OTP avec Diagnostic Étape par Étape
    on<AuthOTPRequested>((event, emit) async {
      try {
        final email = event.email.trim().toLowerCase();
        
        // Étape 1 : Base de données
        emit(const AuthState.checkingDatabase());
        final existingUserByEmail = await _userRepository.findByEmail(email);
        if (existingUserByEmail != null) {
          emit(const AuthState.failure('Cet email est déjà utilisé'));
          return;
        }

        final existingUserByPhone = await _userRepository.findByPhone(event.phoneNumber);
        if (existingUserByPhone != null) {
          emit(const AuthState.failure('Ce numéro est déjà utilisé'));
          return;
        }
        
        // Étape 2 : Préparation sécurisée
        emit(const AuthState.preparingOTP());
        
        // Étape 3 : Envoi (avec timeout global de sécurité)
        emit(const AuthState.sendingEmail());
        
        await _otpRepository.generateAndSendOTP(email, event.companyName).timeout(
          const Duration(seconds: 25),
          onTimeout: () => throw Exception('Délai d\'envoi dépassé. Vérifiez votre connexion Internet.'),
        );
        
        emit(AuthState.otpSent(message: 'Code envoyé à $email'));
      } catch (e) {
        print('🚨 CRITICAL AUTH ERROR: $e');
        emit(AuthState.failure('Erreur : ${e.toString().replaceAll('Exception: ', '')}'));
      }
    });
    
    // ✨ Handler pour inscription avec vérification OTP
    on<AuthRegistrationRequested>((event, emit) async {
      emit(const AuthState.otpVerifying());
      try {
        final email = event.email.trim().toLowerCase();

        // 1. Vérifier l'OTP
        final isValidOTP = await _otpRepository.verifyOTP(email, event.otpCode);
        if (!isValidOTP) {
          emit(const AuthState.failure('Code invalide ou expiré'));
          return;
        }
        
        // 2. Vérifier si le numéro existe déjà
        final existingByPhone = await _userRepository.findByPhone(event.phoneNumber);
        if (existingByPhone != null) {
          emit(const AuthState.failure('Ce numéro est déjà utilisé'));
          return;
        }
        
        // 3. Créer l'utilisateur
        final user = await _userRepository.createUser(
          phoneNumber: event.phoneNumber,
          email: email,
          companyName: event.companyName,
          isVerified: true,
        );
        
        // 4. Envoyer l'email de bienvenue (Optionnel, ne pas bloquer si erreur)
        _otpRepository.sendWelcomeEmail(
          email: email,
          companyName: event.companyName,
        );

        // 5. Sauvegarder la session
        await _sessionStore.setPhone(user.phoneNumber);
        
        // 6. Authentifier
        emit(AuthState.authenticated(user));
      } catch (e) {
        emit(AuthState.failure('Erreur lors de l\'inscription: ${e.toString()}'));
      }
    });
    
    // ✨ Handler pour renvoyer l'OTP
    on<AuthResendOTP>((event, emit) async {
      emit(const AuthState.loading());
      try {
        final email = event.email.trim().toLowerCase();
        await _otpRepository.generateAndSendOTP(email, event.companyName);
        emit(AuthState.otpSent(message: 'Code renvoyé à $email'));
      } catch (e) {
        emit(AuthState.failure('Erreur lors du renvoi: ${e.toString()}'));
      }
    });
    
    // ✨ Handler pour demande d'OTP de connexion
    on<AuthLoginOTPRequested>((event, emit) async {
      emit(const AuthState.loading());
      try {
        // 1. Vérifier si l'utilisateur existe
        final user = await _userRepository.findByPhone(event.phoneNumber);
        if (user == null) {
          emit(const AuthState.failure('Aucun compte trouvé avec ce numéro'));
          return;
        }
        
        // 2. Vérifier si le compte est vérifié
        if (!user.isVerified) {
          emit(const AuthState.failure('Votre compte n\'est pas vérifié'));
          return;
        }
        
        // 3. Vérifier que l'utilisateur a un email
        if (user.email == null || user.email!.isEmpty) {
          emit(const AuthState.failure('Aucun email associé à ce compte'));
          return;
        }
        
        // 4. Générer et envoyer l'OTP
        await _otpRepository.generateAndSendOTP(
          user.email!,
          user.companyName ?? 'Utilisateur',
        );
        
        emit(AuthState.otpSent(message: 'Code envoyé à ${user.email}'));
      } catch (e) {
        emit(AuthState.failure('Erreur lors de l\'envoi: ${e.toString()}'));
      }
    });
    
    // ✨ Handler pour connexion avec OTP
    on<AuthLoginWithOTP>((event, emit) async {
      emit(const AuthState.otpVerifying());
      try {
        // 1. Récupérer l'utilisateur
        final user = await _userRepository.findByPhone(event.phoneNumber);
        if (user == null) {
          emit(const AuthState.failure('Compte introuvable'));
          return;
        }
        
        // 2. Vérifier l'OTP
        final isValidOTP = await _otpRepository.verifyOTP(
          user.email!,
          event.otpCode,
        );
        
        if (!isValidOTP) {
          emit(const AuthState.failure('Code invalide ou expiré'));
          return;
        }
        
        // 3. Mettre à jour la dernière connexion
        await _userRepository.updateLastLogin(user.id);
        
        // 4. Sauvegarder la session
        await _sessionStore.setPhone(user.phoneNumber);
        
        // 5. Authentifier
        emit(AuthState.authenticated(user));
      } catch (e) {
        emit(AuthState.failure('Erreur lors de la connexion: ${e.toString()}'));
      }
    });
  }

  final LoginWithPhone _loginWithPhone;
  final UserRepository _userRepository;
  final OTPRepository _otpRepository;
  final AuthSessionStore _sessionStore;
}


part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.user,
    this.message,
  });

  const AuthState.unknown() : this._(status: AuthStatus.unknown);
  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.unauthenticated() : this._(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(User user) : this._(status: AuthStatus.authenticated, user: user);
  const AuthState.failure(String message) : this._(status: AuthStatus.failure, message: message);
  
  // ✨ Nouveaux états de diagnostic
  const AuthState.checkingDatabase() : this._(status: AuthStatus.checkingDatabase, message: 'Vérification de la base de données...');
  const AuthState.preparingOTP() : this._(status: AuthStatus.preparingOTP, message: 'Préparation du code de sécurité...');
  const AuthState.sendingEmail() : this._(status: AuthStatus.sendingEmail, message: 'Connexion au serveur Gmail...');
  const AuthState.otpSent({String? message}) 
      : this._(status: AuthStatus.otpSent, message: message ?? 'Code envoyé par email');
  const AuthState.otpVerifying() : this._(status: AuthStatus.otpVerifying, message: 'Vérification du code...');

  final AuthStatus status;
  final User? user;
  final String? message;

  @override
  List<Object?> get props => [status, user, message];
}

enum AuthStatus { 
  unknown, 
  loading, 
  unauthenticated, 
  authenticated, 
  failure,
  otpSent,        
  otpVerifying,
  checkingDatabase, // ✨
  preparingOTP,     // ✨
  sendingEmail,     // ✨
}


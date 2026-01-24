part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

// ✨ Nouveaux événements pour l'inscription avec OTP

class AuthOTPRequested extends AuthEvent {
  const AuthOTPRequested({
    required this.email,
    required this.companyName,
    required this.phoneNumber,
  });

  final String email;
  final String companyName;
  final String phoneNumber;

  @override
  List<Object?> get props => [email, companyName, phoneNumber];
}

class AuthRegistrationRequested extends AuthEvent {
  const AuthRegistrationRequested({
    required this.phoneNumber,
    required this.email,
    required this.companyName,
    required this.otpCode,
  });

  final String phoneNumber;
  final String email;
  final String companyName;
  final String otpCode;

  @override
  List<Object?> get props => [phoneNumber, email, companyName, otpCode];
}

class AuthResendOTP extends AuthEvent {
  const AuthResendOTP({
    required this.email,
    required this.companyName,
    required this.phoneNumber,
  });

  final String email;
  final String companyName;
  final String phoneNumber;

  @override
  List<Object?> get props => [email, companyName, phoneNumber];
}

// ✨ Événements pour connexion avec OTP

class AuthLoginOTPRequested extends AuthEvent {
  const AuthLoginOTPRequested({
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthLoginWithOTP extends AuthEvent {
  const AuthLoginWithOTP({
    required this.phoneNumber,
    required this.otpCode,
  });

  final String phoneNumber;
  final String otpCode;

  @override
  List<Object?> get props => [phoneNumber, otpCode];
}

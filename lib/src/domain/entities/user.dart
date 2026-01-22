/// Entité User avec informations d'inscription.
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.companyName,
    this.isVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  final int id;
  final String phoneNumber;
  final String? email;
  final String? companyName;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  
  /// Copie de l'utilisateur avec des champs modifiés
  User copyWith({
    int? id,
    String? phoneNumber,
    String? email,
    String? companyName,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  List<Object?> get props => [id, phoneNumber, email, companyName, isVerified, createdAt, lastLogin];
}


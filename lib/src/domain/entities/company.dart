/// Entité Company (1 utilisateur = 1 entreprise pour le MVP).
import 'package:equatable/equatable.dart';

class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.email,
    required this.logoPath,
    required this.currency,
    required this.vatRate,
    this.signaturePath,
  });

  final int id;
  final String name;
  final String phone;
  final String address;
  final String? email;
  final String? logoPath;
  final String currency; // FCFA (XOF/XAF label)
  final double vatRate; // ex: 0.18
  final String? signaturePath; // Chemin vers l'image de signature

  @override
  List<Object?> get props => [id, name, phone, address, email, logoPath, currency, vatRate, signaturePath];
}


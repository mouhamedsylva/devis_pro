/// Entité Company (1 utilisateur = 1 entreprise pour le MVP).
import 'package:equatable/equatable.dart';

class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.logoPath,
    required this.currency,
    required this.vatRate,
  });

  final int id;
  final String name;
  final String phone;
  final String address;
  final String? logoPath;
  final String currency; // FCFA (XOF/XAF label)
  final double vatRate; // ex: 0.18

  @override
  List<Object?> get props => [id, name, phone, address, logoPath, currency, vatRate];
}


/// Entité User (auth par numéro de téléphone).
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.phoneNumber,
    required this.createdAt,
  });

  final int id;
  final String phoneNumber;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, phoneNumber, createdAt];
}


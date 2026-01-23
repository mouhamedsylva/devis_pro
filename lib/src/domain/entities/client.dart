/// Entité Client.
import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String phone;
  final String address;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, name, phone, address, createdAt];
}


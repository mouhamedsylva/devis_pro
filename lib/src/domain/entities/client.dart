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

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, address, createdAt];
}


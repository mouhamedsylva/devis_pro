/// DTO SQLite <-> Entité Client.
import '../../domain/entities/client.dart';

class ClientModel {
  static Client fromMap(Map<String, Object?> map) {
    return Client(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static Map<String, Object?> toMap(Client c) {
    return {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'address': c.address,
      'createdAt': c.createdAt.toIso8601String(),
    };
  }

  static Map<String, Object?> toInsert({required String name, required String phone, required String address}) {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}


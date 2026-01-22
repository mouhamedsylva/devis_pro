/// Entité Client.
import 'package:equatable/equatable.dart';

class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  final int id;
  final String name;
  final String phone;
  final String address;

  @override
  List<Object?> get props => [id, name, phone, address];
}


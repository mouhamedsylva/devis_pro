/// Entité Produit / Service.
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.vatRate,
  });

  final int id;
  final String name;
  final double unitPrice;
  final double vatRate;

  @override
  List<Object?> get props => [id, name, unitPrice, vatRate];
}


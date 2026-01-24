/// Entité Produit / Service.
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.vatRate,
    required this.unit,
  });

  final int id;
  final String name;
  final double unitPrice;
  final double vatRate;
  final String unit;

  @override
  List<Object?> get props => [id, name, unitPrice, vatRate, unit];
}


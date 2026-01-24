/// DTO SQLite <-> Entité Product.
import '../../domain/entities/product.dart';

class ProductModel {
  static Product fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      unitPrice: (map['unitPrice'] as num).toDouble(),
      vatRate: (map['vatRate'] as num).toDouble(),
      unit: (map['unit'] as String?) ?? 'Unité',
    );
  }

  static Map<String, Object?> toMap(Product p) {
    return {
      'id': p.id,
      'name': p.name,
      'unitPrice': p.unitPrice,
      'vatRate': p.vatRate,
      'unit': p.unit,
    };
  }

  static Map<String, Object?> toInsert({
    required String name,
    required double unitPrice,
    required double vatRate,
    required String unit,
  }) {
    return {
      'name': name,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'unit': unit,
    };
  }
}


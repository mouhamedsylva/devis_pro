/// DTO SQLite <-> Entité Product.
import '../../domain/entities/product.dart';

class ProductModel {
  static Product fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      unitPrice: (map['unitPrice'] as num).toDouble(),
      vatRate: (map['vatRate'] as num).toDouble(),
    );
  }

  static Map<String, Object?> toMap(Product p) {
    return {
      'id': p.id,
      'name': p.name,
      'unitPrice': p.unitPrice,
      'vatRate': p.vatRate,
    };
  }

  static Map<String, Object?> toInsert({
    required String name,
    required double unitPrice,
    required double vatRate,
  }) {
    return {
      'name': name,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
    };
  }
}


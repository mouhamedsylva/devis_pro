/// Abstraction repository Produit/Service (CRUD).
import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> list();
  Future<Product> create({
    required String name,
    required double unitPrice,
    required double vatRate,
  });
  Future<void> update(Product product);
  Future<void> delete(int id);
}


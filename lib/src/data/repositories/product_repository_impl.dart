/// Impl SQLite du ProductRepository.
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Product>> list() async {
    final rows = await _db.database.query('products', orderBy: 'id DESC');
    return rows.map(ProductModel.fromMap).toList();
  }

  @override
  Future<Product> create({required String name, required double unitPrice, required double vatRate}) async {
    final id = await _db.database.insert(
      'products',
      ProductModel.toInsert(name: name, unitPrice: unitPrice, vatRate: vatRate),
    );
    final rows = await _db.database.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    return ProductModel.fromMap(rows.first);
  }

  @override
  Future<void> update(Product product) async {
    await _db.database.update('products', ProductModel.toMap(product), where: 'id = ?', whereArgs: [product.id]);
  }

  @override
  Future<void> delete(int id) async {
    await _db.database.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}


import 'package:sqflite/sqflite.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/local/app_database.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db, this._activityRepo);

  final AppDatabase _db;
  final ActivityRepository _activityRepo;

  @override
  Future<List<Product>> list() async {
    final rows = await _db.database.query('products', orderBy: 'name ASC');
    return rows.map((row) => Product(
      id: row['id'] as int,
      name: row['name'] as String,
      unitPrice: (row['unitPrice'] as num).toDouble(),
      vatRate: (row['vatRate'] as num).toDouble(),
      unit: row['unit'] as String,
    )).toList();
  }

  @override
  Future<int> getProductsCount() async {
    final count = Sqflite.firstIntValue(await _db.database.rawQuery('SELECT COUNT(*) FROM products'));
    return count ?? 0;
  }

  @override
  Future<Product> create({required String name, required double unitPrice, required double vatRate, required String unit}) async {
    final id = await _db.database.insert('products', {
      'name': name,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'unit': unit,
    });

    await _activityRepo.log(
      action: 'Nouveau produit ajouté',
      details: 'Produit: $name',
      type: 'product',
    );

    return Product(
      id: id,
      name: name,
      unitPrice: unitPrice,
      vatRate: vatRate,
      unit: unit,
    );
  }

  @override
  Future<void> update(Product product) async {
    await _db.database.update(
      'products',
      {
        'name': product.name,
        'unitPrice': product.unitPrice,
        'vatRate': product.vatRate,
        'unit': product.unit,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );

    await _activityRepo.log(
      action: 'Produit modifié',
      details: 'Produit: ${product.name}',
      type: 'product',
    );
  }

  @override
  Future<void> delete(int id) async {
    final rows = await _db.database.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    await _db.database.delete('products', where: 'id = ?', whereArgs: [id]);

    if (rows.isNotEmpty) {
      await _activityRepo.log(
        action: 'Produit supprimé',
        details: 'Produit: ${rows.first['name']}',
        type: 'product',
      );
    }
  }
}

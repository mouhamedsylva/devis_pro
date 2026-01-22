/// Impl SQLite du ClientRepository.
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/client_model.dart';

class ClientRepositoryImpl implements ClientRepository {
  const ClientRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Client>> list() async {
    final rows = await _db.database.query('clients', orderBy: 'id DESC');
    return rows.map(ClientModel.fromMap).toList();
  }

  @override
  Future<Client?> findById(int id) async {
    final rows = await _db.database.query('clients', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return ClientModel.fromMap(rows.first);
  }

  @override
  Future<Client> create({required String name, required String phone, required String address}) async {
    final id = await _db.database.insert(
      'clients',
      ClientModel.toInsert(name: name, phone: phone, address: address),
    );
    final rows = await _db.database.query('clients', where: 'id = ?', whereArgs: [id], limit: 1);
    return ClientModel.fromMap(rows.first);
  }

  @override
  Future<void> update(Client client) async {
    await _db.database.update('clients', ClientModel.toMap(client), where: 'id = ?', whereArgs: [client.id]);
  }

  @override
  Future<void> delete(int id) async {
    await _db.database.delete('clients', where: 'id = ?', whereArgs: [id]);
  }
}


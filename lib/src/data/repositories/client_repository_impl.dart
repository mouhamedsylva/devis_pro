import 'package:sqflite/sqflite.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/local/app_database.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl(this._db, this._activityRepo);

  final AppDatabase _db;
  final ActivityRepository _activityRepo;

  @override
  Future<List<Client>> list() async {
    final rows = await _db.database.query('clients', orderBy: 'name ASC');
    return rows.map((row) => Client(
      id: row['id'] as int,
      name: row['name'] as String,
      phone: row['phone'] as String,
      address: row['address'] as String,
      createdAt: DateTime.parse(row['createdAt'] as String),
    )).toList();
  }

  @override
  Future<int> getClientsCount() async {
    final count = Sqflite.firstIntValue(await _db.database.rawQuery('SELECT COUNT(*) FROM clients'));
    return count ?? 0;
  }

  @override
  Future<Client> create({required String name, required String phone, required String address}) async {
    final id = await _db.database.insert('clients', {
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await _activityRepo.log(
      action: 'Nouveau client ajouté',
      details: 'Client: $name',
      type: 'client',
    );

    return Client(
      id: id,
      name: name,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> update(Client client) async {
    await _db.database.update(
      'clients',
      {
        'name': client.name,
        'phone': client.phone,
        'address': client.address,
      },
      where: 'id = ?',
      whereArgs: [client.id],
    );

    await _activityRepo.log(
      action: 'Client modifié',
      details: 'Client: ${client.name}',
      type: 'client',
    );
  }

  @override
  Future<void> delete(int id) async {
    final client = await findById(id);
    await _db.database.delete('clients', where: 'id = ?', whereArgs: [id]);

    if (client != null) {
      await _activityRepo.log(
        action: 'Client supprimé',
        details: 'Client: ${client.name}',
        type: 'client',
      );
    }
  }

  @override
  Future<Client?> findById(int id) async {
    final rows = await _db.database.query('clients', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return Client(
      id: row['id'] as int,
      name: row['name'] as String,
      phone: row['phone'] as String,
      address: row['address'] as String,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }

  @override
  Future<bool> clientHasQuotes(int clientId) async {
    final result = await _db.database.rawQuery('SELECT COUNT(*) FROM quotes WHERE clientId = ?', [clientId]);
    final count = Sqflite.firstIntValue(result);
    return (count ?? 0) > 0;
  }
}

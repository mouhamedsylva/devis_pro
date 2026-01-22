/// Impl SQLite du UserRepository.
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<User?> findByPhone(String phoneNumber) async {
    final rows = await _db.database.query(
      'users',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  @override
  Future<User> createWithPhone(String phoneNumber) async {
    final id = await _db.database.insert('users', UserModel.toInsert(phoneNumber));
    final rows = await _db.database.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return UserModel.fromMap(rows.first);
  }
}


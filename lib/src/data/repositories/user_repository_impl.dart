/// Impl SQLite du UserRepository.
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/database_interface.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._db);

  final DatabaseInterface _db;

  @override
  Future<User?> findByPhone(String phoneNumber) async {
    final rows = await _db.query(
      'users',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  @override
  Future<User?> findByEmail(String email) async {
    final rows = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  @override
  Future<User> createWithPhone(String phoneNumber) async {
    final id = await _db.insert(
      'users',
      UserModel.toInsert(phoneNumber: phoneNumber),
    );
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return UserModel.fromMap(rows.first);
  }

  @override
  Future<User> createUser({
    required String phoneNumber,
    required String email,
    String? companyName,
    bool isVerified = false,
  }) async {
    final id = await _db.insert(
      'users',
      UserModel.toInsert(
        phoneNumber: phoneNumber,
        email: email,
        companyName: companyName,
        isVerified: isVerified,
      ),
    );
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return UserModel.fromMap(rows.first);
  }

  @override
  Future<void> updateLastLogin(int userId) async {
    await _db.update(
      'users',
      {'lastLogin': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}


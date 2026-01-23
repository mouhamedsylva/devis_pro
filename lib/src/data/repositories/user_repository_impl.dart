/// Impl SQLite du UserRepository.
import '../../core/utils/formatters.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/database_interface.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._db);

  final DatabaseInterface _db;

  @override
  Future<User?> findByPhone(String phoneNumber) async {
    // Normaliser le numéro pour la recherche
    final normalized = Formatters.normalizePhoneNumber(phoneNumber);
    
    // Chercher avec le numéro normalisé
    var rows = await _db.query(
      'users',
      where: 'phoneNumber = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    
    // Si pas trouvé, essayer aussi sans le préfixe +221 (pour compatibilité avec anciens numéros)
    if (rows.isEmpty && normalized.startsWith('+221')) {
      final withoutPrefix = normalized.substring(4); // Enlever "+221"
      rows = await _db.query(
        'users',
        where: 'phoneNumber = ?',
        whereArgs: [withoutPrefix],
        limit: 1,
      );
    }
    
    // Si toujours pas trouvé, essayer avec juste les chiffres (sans +221)
    if (rows.isEmpty) {
      final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length == 9) {
        rows = await _db.query(
          'users',
          where: 'phoneNumber = ?',
          whereArgs: [digitsOnly],
          limit: 1,
        );
      }
    }
    
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
    // Normaliser le numéro avant de le stocker
    final normalized = Formatters.normalizePhoneNumber(phoneNumber);
    final id = await _db.insert(
      'users',
      UserModel.toInsert(phoneNumber: normalized),
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
    // Normaliser le numéro avant de le stocker
    final normalized = Formatters.normalizePhoneNumber(phoneNumber);
    final id = await _db.insert(
      'users',
      UserModel.toInsert(
        phoneNumber: normalized,
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


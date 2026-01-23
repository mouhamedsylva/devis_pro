/// Implémentation de la base de données pour mobile (Android/iOS/Desktop).
///
/// Utilise sqflite comme backend.
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_interface.dart';

class DatabaseMobile implements DatabaseInterface {
  DatabaseMobile._();

  static DatabaseMobile? _instance;
  Database? _database;

  static const _dbName = 'devispro.db';
  static const _dbVersion = 3; // ✨ Version 3 : ajout createdAt à clients

  factory DatabaseMobile() {
    _instance ??= DatabaseMobile._();
    return _instance!;
  }

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final path = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeSchema(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    // ✨ Table users avec nouveaux champs
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phoneNumber TEXT NOT NULL UNIQUE,
  email TEXT,
  companyName TEXT,
  isVerified INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  lastLogin TEXT
);
''');

    // ✨ Table OTP pour vérification par email
    await db.execute('''
CREATE TABLE otp_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expiresAt TEXT NOT NULL,
  isUsed INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL
);
''');

    // Index pour recherche rapide des OTP
    await db.execute('''
CREATE INDEX idx_otp_email ON otp_codes(email);
''');

    await db.execute('''
CREATE TABLE company (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  logoPath TEXT,
  currency TEXT NOT NULL,
  vatRate REAL NOT NULL
);
''');

    await db.execute('''
CREATE TABLE clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
''');

    await db.execute('''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  unitPrice REAL NOT NULL,
  vatRate REAL NOT NULL
);
''');

    await db.execute('''
CREATE TABLE quotes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quoteNumber TEXT NOT NULL UNIQUE,
  clientId INTEGER NOT NULL,
  date TEXT NOT NULL,
  status TEXT NOT NULL,
  totalHT REAL NOT NULL,
  totalVAT REAL NOT NULL,
  totalTTC REAL NOT NULL,
  FOREIGN KEY (clientId) REFERENCES clients(id) ON DELETE RESTRICT
);
''');

    await db.execute('''
CREATE TABLE quote_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quoteId INTEGER NOT NULL,
  productName TEXT NOT NULL,
  unitPrice REAL NOT NULL,
  quantity REAL NOT NULL,
  vatRate REAL NOT NULL,
  total REAL NOT NULL,
  FOREIGN KEY (quoteId) REFERENCES quotes(id) ON DELETE CASCADE
);
''');

    // Valeurs par défaut
    await db.insert('company', {
      'name': 'Mon entreprise',
      'phone': '',
      'address': '',
      'logoPath': null,
      'currency': 'FCFA',
      'vatRate': 0.18,
    });
  }

  /// Migration de la base de données
  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration de v1 à v2 : ajout des nouveaux champs users + table OTP
      await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN companyName TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN isVerified INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN lastLogin TEXT');

      // Créer la table OTP
      await db.execute('''
CREATE TABLE otp_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expiresAt TEXT NOT NULL,
  isUsed INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL
);
''');

      await db.execute('CREATE INDEX idx_otp_email ON otp_codes(email);');
      
      print('✅ Migration v1 → v2 réussie');
    }
    if (oldVersion < 3) {
      // Migration de v2 à v3 : ajout de la colonne createdAt à la table clients
      await db.execute('ALTER TABLE clients ADD COLUMN createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP');
      print('✅ Migration v2 → v3 réussie : ajout de createdAt à clients');
    }
  }

  Database get _db {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    return await _db.insert(table, values);
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    return await _db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    return await _db.rawQuery(sql, arguments);
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    await _db.execute(sql, arguments);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseInterface txn) action) async {
    return await _db.transaction((txn) async {
      final txnWrapper = _TransactionWrapper(txn);
      return await action(txnWrapper);
    });
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

/// Wrapper pour les transactions sqflite
class _TransactionWrapper implements DatabaseInterface {
  _TransactionWrapper(this._txn);

  final DatabaseExecutor _txn;

  @override
  Future<void> initialize() async {
    // Déjà initialisé
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    return await _txn.insert(table, values);
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _txn.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _txn.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    return await _txn.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    return await _txn.rawQuery(sql, arguments);
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    await _txn.execute(sql, arguments);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseInterface txn) action) async {
    throw UnimplementedError('Nested transactions not supported');
  }

  @override
  Future<void> close() async {
    // Ne pas fermer une transaction
  }
}

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
  static const _dbVersion = 101; // ✨ Incrémenté pour la table activity_logs

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
    // ✨ Table users
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

    // ✨ Table OTP
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

    await db.execute('''
CREATE TABLE company (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  email TEXT,
  logoPath TEXT,
  currency TEXT NOT NULL,
  vatRate REAL NOT NULL,
  signaturePath TEXT
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
  vatRate REAL NOT NULL,
  unit TEXT NOT NULL DEFAULT 'Unité'
);
''');

    await db.execute('''
CREATE TABLE quotes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  quoteNumber TEXT NOT NULL UNIQUE,
  clientId INTEGER,
  clientName TEXT,
  clientPhone TEXT,
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
  unit TEXT,
  total REAL NOT NULL,
  FOREIGN KEY (quoteId) REFERENCES quotes(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  isCustom INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  validityDays INTEGER,
  termsAndConditions TEXT,
  createdAt TEXT NOT NULL
);
''');

    await db.execute('CREATE INDEX idx_templates_category ON templates(category);');

    await db.execute('''
CREATE TABLE template_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  templateId INTEGER NOT NULL,
  productName TEXT NOT NULL,
  description TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  vatRate REAL NOT NULL,
  displayOrder INTEGER NOT NULL,
  unit TEXT,
  FOREIGN KEY (templateId) REFERENCES templates(id) ON DELETE CASCADE
);
''');

    await db.execute('CREATE INDEX idx_template_items_templateId ON template_items(templateId);');

    // ✨ Table activity_logs
    await db.execute('''
CREATE TABLE activity_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,
  details TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  type TEXT NOT NULL
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
      'signaturePath': null,
    });
  }

  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 101) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS activity_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  action TEXT NOT NULL,
  details TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  type TEXT NOT NULL
);
''');
    }
    print('🔍 Mise à jour vers v$newVersion...');
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

class _TransactionWrapper implements DatabaseInterface {
  _TransactionWrapper(this._txn);

  final DatabaseExecutor _txn;

  @override
  Future<void> initialize() async {}

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
  Future<void> close() async {}
}

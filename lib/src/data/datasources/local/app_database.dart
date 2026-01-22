/// Base de données locale DevisPro (SQLite).
///
/// - Offline-first: toutes les données sont stockées localement.
/// - Schéma conforme au cahier des charges: users, company, clients, products,
///   quotes, quote_items.
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static const _dbName = 'devispro.db';
  static const _dbVersion = 1;

  static Future<AppDatabase> open() async {
    // Sur Web, getDatabasesPath n'est pas supporté. Le backend web (IndexedDB)
    // ignore le "path" et utilise le nom comme identifiant.
    final path = kIsWeb ? _dbName : p.join(await getDatabasesPath(), _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Important pour l’intégrité (quotes -> clients, items -> quotes).
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );

    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phoneNumber TEXT NOT NULL UNIQUE,
  createdAt TEXT NOT NULL
);
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
  address TEXT NOT NULL
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

    // Valeurs par défaut: entreprise "vide" (modifiable dans Paramètres).
    await db.insert('company', {
      'name': 'Mon entreprise',
      'phone': '',
      'address': '',
      'logoPath': null,
      'currency': 'FCFA',
      'vatRate': 0.18,
    });
  }
}


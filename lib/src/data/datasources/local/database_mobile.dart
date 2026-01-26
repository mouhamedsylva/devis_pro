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
  static const _dbVersion = 99; // ✨ Version de dépannage pour forcer la migration

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

    // ✨ Table templates pour les modèles de devis
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

    // Index pour recherche rapide par catégorie
    await db.execute('''
CREATE INDEX idx_templates_category ON templates(category);
''');

    // ✨ Table template_items pour les items des templates
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
  FOREIGN KEY (templateId) REFERENCES templates(id) ON DELETE CASCADE
);
''');

    // Index pour recherche rapide par template
    await db.execute('''
CREATE INDEX idx_template_items_templateId ON template_items(templateId);
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

  /// Migration de la base de données
  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    // Cette migration englobe toutes les précédentes et force l'ajout si manquant.
    // C'est une stratégie de "récupération" pour les BD mal migrées.
    if (oldVersion < 99) {
      print('🔍 Tentative de migration de récupération vers v99...');

      // --- Migration v1 -> v2: Ajout de champs users + table OTP (répétée pour robustesse) ---
      // Si oldVersion était < 2, ces champs pourraient manquer.
      var usersTableInfo = await db.rawQuery('PRAGMA table_info(users);');
      var usersColumnNames = usersTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();
      if (!usersColumnNames.contains('email')) {
        await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
      }
      if (!usersColumnNames.contains('companyname')) {
        await db.execute('ALTER TABLE users ADD COLUMN companyName TEXT');
      }
      if (!usersColumnNames.contains('isverified')) {
        await db.execute('ALTER TABLE users ADD COLUMN isVerified INTEGER NOT NULL DEFAULT 0');
      }
      if (!usersColumnNames.contains('lastlogin')) {
        await db.execute('ALTER TABLE users ADD COLUMN lastLogin TEXT');
      }
      // Vérifier si la table otp_codes existe, sinon la créer
      var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='otp_codes';");
      if (tables.isEmpty) {
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
      }
      print('✅ Migration (récup.) champs users et otp_codes vérifiés.');


      // --- Migration v2 -> v3: Ajout de createdAt à clients ---
      var clientsTableInfo = await db.rawQuery('PRAGMA table_info(clients);');
      var clientsColumnNames = clientsTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();
      if (!clientsColumnNames.contains('createdat')) {
        await db.execute('ALTER TABLE clients ADD COLUMN createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP');
      }
      print('✅ Migration (récup.) createdAt à clients vérifié.');


      // --- Migration v3 -> v4: Ajout de signaturePath à company ---
      var companyTableInfo = await db.rawQuery('PRAGMA table_info(company);');
      var companyColumnNames = companyTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();
      if (!companyColumnNames.contains('signaturepath')) {
        await db.execute('ALTER TABLE company ADD COLUMN signaturePath TEXT');
      }
      print('✅ Migration (récup.) signaturePath à company vérifié.');


      // --- Migration v4 -> v5: Ajout des tables templates et template_items ---
      // Vérifier si la table templates existe, sinon la créer
      tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='templates';");
      if (tables.isEmpty) {
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
      }
      // Vérifier si la table template_items existe, sinon la créer
      tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='template_items';");
      if (tables.isEmpty) {
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
  FOREIGN KEY (templateId) REFERENCES templates(id) ON DELETE CASCADE
);
''');
        await db.execute('CREATE INDEX idx_template_items_templateId ON template_items(templateId);');
      }
      print('✅ Migration (récup.) tables templates vérifiées.');


      // --- Migration v5 -> v6: Rendre clientId nullable et ajouter clientName/clientPhone dans quotes ---
      // Cette migration est complexe car elle recrée la table. Si elle n'a pas eu lieu,
      // la table 'quotes' n'aura pas clientName/clientPhone et clientId sera NOT NULL.
      // Plutôt que de recréer ici, on va s'assurer que si 'quotes' existe, elle a les colonnes.
      // Si la table quotes est trop ancienne (pas de clientName/Phone), la solution la plus simple
      // pour éviter la complexité des recréations multiples est de faire un ALTER TABLE ADD COLUMN.
      // On assume que si la v6 n'a pas été faite, c'est la structure qui manque.
      var quotesTableInfo = await db.rawQuery('PRAGMA table_info(quotes);');
      var quotesColumnNames = quotesTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();

      if (!quotesColumnNames.contains('clientname')) {
        await db.execute('ALTER TABLE quotes ADD COLUMN clientName TEXT');
      }
      if (!quotesColumnNames.contains('clientphone')) {
        await db.execute('ALTER TABLE quotes ADD COLUMN clientPhone TEXT');
      }
      // Note: Rendre clientId nullable via ALTER COLUMN n'est pas direct en SQLite.
      // La recréation de table est gérée par la v6. Si la v6 n'a pas été faite,
      // on ne peut pas facilement modifier la nullabilité ici. On se concentre sur les colonnes.
      print('✅ Migration (récup.) champs clients dans quotes vérifiés.');


      // --- Migration v6 -> v7: Ajout de la colonne 'unit' ---
      var productsTableInfo = await db.rawQuery('PRAGMA table_info(products);');
      var productsColumnNames = productsTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();
      if (!productsColumnNames.contains('unit')) {
        await db.execute("ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'Unité'");
      }

      var quoteItemsTableInfo = await db.rawQuery('PRAGMA table_info(quote_items);');
      var quoteItemsColumnNames = quoteItemsTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();
      if (!quoteItemsColumnNames.contains('unit')) {
        await db.execute("ALTER TABLE quote_items ADD COLUMN unit TEXT");
      }

      var templateItemsTableInfo = await db.rawQuery('PRAGMA table_info(template_items);');
      var templateItemsColumnNames = templateItemsTableInfo.map((row) => row['name'].toString().toLowerCase()).toList();
      if (!templateItemsColumnNames.contains('unit')) {
        await db.execute("ALTER TABLE template_items ADD COLUMN unit TEXT");
      }
      print('✅ Migration (récup.) champ unit vérifié.');


      // --- Migration v7 -> v8 & v8 -> v9: Ajout des champs de synchronisation pour le mode offline ---
      // (is_synced, synced_at, pending_sync)
      if (!quotesColumnNames.contains('is_synced')) {
        await db.execute('ALTER TABLE quotes ADD COLUMN is_synced INTEGER DEFAULT 1');
      }
      if (!quotesColumnNames.contains('synced_at')) {
        await db.execute('ALTER TABLE quotes ADD COLUMN synced_at TEXT');
      }
      if (!quotesColumnNames.contains('pending_sync')) {
        await db.execute('ALTER TABLE quotes ADD COLUMN pending_sync INTEGER DEFAULT 0');
      }
      print('✅ Migration (récup.) champs offline sync vérifiés.');


      // --- Migration v9 -> v10: Ajout du champ email à la table company ---
      if (!companyColumnNames.contains('email')) {
        await db.execute('ALTER TABLE company ADD COLUMN email TEXT');
      }
      print('✅ Migration (récup.) champ email à company vérifié.');

      print('🎉 Migration de récupération vers v99 terminée.');
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

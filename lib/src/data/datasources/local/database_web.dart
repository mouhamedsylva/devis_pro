/// Implémentation de la base de données pour le web.
///
/// Utilise IndexedDB via idb_shim comme backend.
import 'package:idb_shim/idb_browser.dart';

import 'database_interface.dart';

class DatabaseWeb implements DatabaseInterface {
  DatabaseWeb._();

  static DatabaseWeb? _instance;
  Database? _database;

  static const _dbName = 'devispro';
  static const _dbVersion = 7; // ✨ Version 7 : ajout du champ 'unit' (unité)

  factory DatabaseWeb() {
    _instance ??= DatabaseWeb._();
    return _instance!;
  }

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final idbFactory = getIdbFactory()!;

    _database = await idbFactory.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (VersionChangeEvent event) {
        final db = event.database;
        _createSchema(db);
      },
    );

    // Initialiser les données par défaut si nécessaire
    await _initializeDefaultData();
  }

  void _createSchema(Database db) {
    // Créer les object stores (équivalent des tables SQL)
    if (!db.objectStoreNames.contains('users')) {
      final usersStore = db.createObjectStore('users', keyPath: 'id', autoIncrement: true);
      usersStore.createIndex('phoneNumber', 'phoneNumber', unique: true);
      // Les nouveaux champs (email, companyName, isVerified, lastLogin) seront ajoutés aux documents
    }

    // ✨ Table OTP pour vérification par email
    if (!db.objectStoreNames.contains('otp_codes')) {
      final otpStore = db.createObjectStore('otp_codes', keyPath: 'id', autoIncrement: true);
      otpStore.createIndex('email', 'email', unique: false);
    }

    if (!db.objectStoreNames.contains('company')) {
      db.createObjectStore('company', keyPath: 'id', autoIncrement: true);
    }

    if (!db.objectStoreNames.contains('clients')) {
      db.createObjectStore('clients', keyPath: 'id', autoIncrement: true);
    }

    if (!db.objectStoreNames.contains('products')) {
      db.createObjectStore('products', keyPath: 'id', autoIncrement: true);
    }

    if (!db.objectStoreNames.contains('quotes')) {
      final quotesStore = db.createObjectStore('quotes', keyPath: 'id', autoIncrement: true);
      quotesStore.createIndex('quoteNumber', 'quoteNumber', unique: true);
      quotesStore.createIndex('clientId', 'clientId', unique: false);
    }

    if (!db.objectStoreNames.contains('quote_items')) {
      final itemsStore = db.createObjectStore('quote_items', keyPath: 'id', autoIncrement: true);
      itemsStore.createIndex('quoteId', 'quoteId', unique: false);
    }

    // ✨ Table templates pour les modèles de devis
    if (!db.objectStoreNames.contains('templates')) {
      final templatesStore = db.createObjectStore('templates', keyPath: 'id', autoIncrement: true);
      templatesStore.createIndex('category', 'category', unique: false);
    }

    // ✨ Table template_items pour les items des templates
    if (!db.objectStoreNames.contains('template_items')) {
      final templateItemsStore = db.createObjectStore('template_items', keyPath: 'id', autoIncrement: true);
      templateItemsStore.createIndex('templateId', 'templateId', unique: false);
    }
  }

  Future<void> _initializeDefaultData() async {
    // Vérifier si la table company a déjà des données
    final companies = await query('company');
    if (companies.isEmpty) {
      await insert('company', {
        'name': 'Mon entreprise',
        'phone': '',
        'address': '',
        'logoPath': null,
        'currency': 'FCFA',
        'vatRate': 0.18,
        'signaturePath': null,
      });
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
    final txn = _db.transaction(table, 'readwrite');
    final store = txn.objectStore(table);
    
    final key = await store.add(values);
    await txn.completed;
    
    return key as int;
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Pour IndexedDB, on doit récupérer l'objet par sa clé puis le mettre à jour
    if (where != null && where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs[0];
      final txn = _db.transaction(table, 'readwrite');
      final store = txn.objectStore(table);
      
      // Récupérer l'objet existant
      final existing = await store.getObject(id) as Map<String, dynamic>?;
      if (existing != null) {
        // Fusionner les valeurs
        final updated = {...existing, ...values, 'id': id};
        await store.put(updated);
        await txn.completed;
        return 1;
      }
      return 0;
    }

    // Pour les autres cas, on doit faire une requête puis mettre à jour
    final items = await query(table, where: where, whereArgs: whereArgs);
    if (items.isEmpty) return 0;

    final txn = _db.transaction(table, 'readwrite');
    final store = txn.objectStore(table);
    
    for (final item in items) {
      final updated = {...item, ...values};
      await store.put(updated);
    }
    await txn.completed;
    
    return items.length;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (where != null && where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs[0];
      final txn = _db.transaction(table, 'readwrite');
      final store = txn.objectStore(table);
      
      await store.delete(id);
      await txn.completed;
      return 1;
    }

    // Pour les autres cas, on doit faire une requête puis supprimer
    final items = await query(table, where: where, whereArgs: whereArgs);
    if (items.isEmpty) return 0;

    final txn = _db.transaction(table, 'readwrite');
    final store = txn.objectStore(table);
    
    for (final item in items) {
      await store.delete(item['id']);
    }
    await txn.completed;
    
    return items.length;
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
    final txn = _db.transaction(table, 'readonly');
    final store = txn.objectStore(table);
    
    List<Map<String, dynamic>> results = [];

    // Si on a une condition WHERE simple sur id
    if (where != null && where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final id = whereArgs[0];
      final obj = await store.getObject(id);
      if (obj != null) {
        results.add(obj as Map<String, dynamic>);
      }
    } else if (where != null && _isIndexedField(table, where)) {
      // Si on a une condition sur un champ indexé
      final indexName = _extractIndexName(where);
      if (indexName != null && whereArgs != null && whereArgs.isNotEmpty) {
        final index = store.index(indexName);
        final obj = await index.get(whereArgs[0]);
        if (obj != null) {
          results.add(obj as Map<String, dynamic>);
        }
      }
    } else {
      // Récupérer tous les objets
      final cursor = store.openCursor(autoAdvance: true);
      await for (final cursorWithValue in cursor) {
        final obj = cursorWithValue.value as Map<String, dynamic>;
        
        // Filtrer selon la clause WHERE si présente
        if (where == null || _matchesWhere(obj, where, whereArgs)) {
          results.add(obj);
        }
      }
    }

    await txn.completed;

    // Appliquer le tri si nécessaire
    if (orderBy != null) {
      results = _applyOrderBy(results, orderBy);
    }

    // Appliquer la limite si nécessaire
    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }

    // Filtrer les colonnes si nécessaire
    if (columns != null) {
      results = results.map((row) {
        return Map.fromEntries(
          row.entries.where((e) => columns.contains(e.key)),
        );
      }).toList();
    }

    return results;
  }

  bool _isIndexedField(String table, String where) {
    if (table == 'users' && where.contains('phoneNumber')) return true;
    if (table == 'quotes' && (where.contains('quoteNumber') || where.contains('clientId'))) return true;
    if (table == 'quote_items' && where.contains('quoteId')) return true;
    return false;
  }

  String? _extractIndexName(String where) {
    if (where.contains('phoneNumber')) return 'phoneNumber';
    if (where.contains('quoteNumber')) return 'quoteNumber';
    if (where.contains('clientId')) return 'clientId';
    if (where.contains('quoteId')) return 'quoteId';
    return null;
  }

  bool _matchesWhere(Map<String, dynamic> obj, String where, List<dynamic>? whereArgs) {
    // Implémentation simple pour les cas courants
    if (whereArgs == null || whereArgs.isEmpty) return true;

    if (where.contains('id = ?')) {
      return obj['id'] == whereArgs[0];
    }
    if (where.contains('phoneNumber = ?')) {
      return obj['phoneNumber'] == whereArgs[0];
    }
    if (where.contains('clientId = ?')) {
      return obj['clientId'] == whereArgs[0];
    }
    if (where.contains('quoteId = ?')) {
      return obj['quoteId'] == whereArgs[0];
    }

    return true; // Par défaut, accepter
  }

  List<Map<String, dynamic>> _applyOrderBy(List<Map<String, dynamic>> results, String orderBy) {
    final parts = orderBy.split(' ');
    final field = parts[0];
    final isDesc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

    results.sort((a, b) {
      final aVal = a[field];
      final bVal = b[field];

      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return isDesc ? 1 : -1;
      if (bVal == null) return isDesc ? -1 : 1;

      final comparison = (aVal as Comparable).compareTo(bVal);
      return isDesc ? -comparison : comparison;
    });

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    // IndexedDB ne supporte pas SQL brut
    // On pourrait parser le SQL mais c'est complexe
    // Pour l'instant, on lance une exception
    throw UnimplementedError('Raw SQL queries not supported on web. Use query() instead.');
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    // IndexedDB ne supporte pas SQL brut
    throw UnimplementedError('Raw SQL execution not supported on web.');
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseInterface txn) action) async {
    // Pour l'instant, on exécute l'action directement
    // Une vraie implémentation nécessiterait de gérer les transactions IndexedDB
    return await action(this);
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }
}

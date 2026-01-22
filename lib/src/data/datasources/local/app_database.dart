/// Base de données locale DevisPro.
///
/// - Offline-first: toutes les données sont stockées localement.
/// - Mobile (Android/iOS/Desktop) : utilise sqflite
/// - Web : utilise IndexedDB via idb_shim
/// - Schéma conforme au cahier des charges: users, company, clients, products,
///   quotes, quote_items.

import 'database_factory.dart';
import 'database_interface.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final DatabaseInterface database;

  static Future<AppDatabase> open() async {
    final db = createDatabase();
    await db.initialize();
    return AppDatabase._(db);
  }
}


/// Interface abstraite pour la base de données.
///
/// Cette interface permet d'avoir deux implémentations :
/// - Mobile (Android/iOS/Desktop) : sqflite
/// - Web : IndexedDB via idb_shim

abstract class DatabaseInterface {
  /// Initialise la base de données
  Future<void> initialize();

  /// Insère une ligne dans une table
  Future<int> insert(String table, Map<String, dynamic> values);

  /// Met à jour des lignes dans une table
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Supprime des lignes d'une table
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  });

  /// Requête SELECT
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  });

  /// Exécute une requête SQL brute
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]);

  /// Exécute une commande SQL brute (INSERT, UPDATE, DELETE, CREATE TABLE, etc.)
  Future<void> execute(String sql, [List<dynamic>? arguments]);

  /// Transaction
  Future<T> transaction<T>(Future<T> Function(DatabaseInterface txn) action);

  /// Ferme la base de données
  Future<void> close();
}

/// Factory qui crée la bonne implémentation de base de données selon la plateforme.
///
/// - Mobile (Android/iOS/Desktop) : sqflite
/// - Web : IndexedDB via idb_shim

import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_mobile.dart'
    if (dart.library.html) 'database_factory_web.dart' as impl;
import 'database_interface.dart';

DatabaseInterface createDatabase() => impl.createDatabase();

/// Initialisation SQLite selon plateforme.
///
/// - Android/iOS: sqflite est prêt, rien à faire.
/// - Desktop (Windows/macOS/Linux): utilise sqflite_common_ffi.
/// - Web: utilise sqflite_common_ffi_web (IndexedDB).
import 'sqflite_bootstrap_stub.dart'
    if (dart.library.io) 'sqflite_bootstrap_io.dart'
    if (dart.library.html) 'sqflite_bootstrap_web.dart' as impl;

/// Point d'entrée unique appelé depuis `main.dart`.
Future<void> initSqflite() => impl.initSqflite();


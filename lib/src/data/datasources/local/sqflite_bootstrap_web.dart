import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: utilise IndexedDB via sqflite_common_ffi_web.
Future<void> initSqflite() async {
  databaseFactory = databaseFactoryFfiWeb;
}


/// Factory pour mobile (Android/iOS/Desktop).
import 'database_interface.dart';
import 'database_mobile.dart';

DatabaseInterface createDatabase() {
  return DatabaseMobile();
}

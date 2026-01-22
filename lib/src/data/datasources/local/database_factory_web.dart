/// Factory pour web.
import 'database_interface.dart';
import 'database_web.dart';

DatabaseInterface createDatabase() {
  return DatabaseWeb();
}

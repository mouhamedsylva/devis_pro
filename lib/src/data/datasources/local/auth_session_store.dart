/// Stockage léger de session (SharedPreferences).
///
/// MVP: on garde uniquement le numéro de téléphone "connecté" pour restaurer
/// l'état au démarrage. (Offline-first)
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  static const _kPhone = 'auth_phone';

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPhone);
  }

  Future<void> setPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhone, phone);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPhone);
  }
}


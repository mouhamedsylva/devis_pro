/// Helpers de formatage (date + monnaie FCFA).
import 'package:intl/intl.dart';

class Formatters {
  /// Format simple: 21/01/2026
  static String dateShort(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  /// Affichage monnaie en FCFA (XOF/XAF).
  ///
  /// Exemple: 12500 -> "12 500 FCFA"
  static String moneyCfa(num amount, {String currencyLabel = 'FCFA'}) {
    final f = NumberFormat('#,##0', 'fr_FR');
    return '${f.format(amount)} $currencyLabel';
  }

  /// Normalise un numéro de téléphone sénégalais.
  ///
  /// - Enlève tous les caractères non numériques (sauf +)
  /// - Ajoute le préfixe +221 si absent
  /// - Exemple: "77 123 45 67" -> "+221771234567"
  /// - Exemple: "+221771234567" -> "+221771234567"
  static String normalizePhoneNumber(String phoneNumber) {
    // Nettoyer le numéro (enlever espaces, tirets, etc.)
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Si le numéro commence déjà par +221, le retourner tel quel
    if (cleaned.startsWith('+221')) {
      return cleaned;
    }
    
    // Si le numéro commence par 221, ajouter le +
    if (cleaned.startsWith('221')) {
      return '+$cleaned';
    }
    
    // Sinon, ajouter +221 au début
    return '+221$cleaned';
  }

  const Formatters._();
}


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

  const Formatters._();
}


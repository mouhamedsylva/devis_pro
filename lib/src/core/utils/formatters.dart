/// Helpers de formatage (date + monnaie FCFA).
import 'package:intl/intl.dart';

class Formatters {
  /// Format simple: 21/01/2026
  static String dateShort(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  /// Format complet: 21/01/2026 à 14:30
  static String dateTimeFull(DateTime dt) => DateFormat('dd/MM/yyyy à HH:mm').format(dt);

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

  /// Formate une date en texte relatif (ex: "Il y a 2 heures", "Hier", "Il y a 3 jours").
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'À l\'instant';
        }
        return 'Il y a ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
      }
      return 'Il y a ${difference.inHours} ${difference.inHours == 1 ? 'heure' : 'heures'}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks ${weeks == 1 ? 'semaine' : 'semaines'}';
    } else {
      return dateShort(dateTime);
    }
  }

  const Formatters._();
}

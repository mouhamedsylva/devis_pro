/// Entité OTP (One-Time Password) pour la vérification par email.
class OTP {
  final int? id;
  final String email;
  final String code;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  const OTP({
    this.id,
    required this.email,
    required this.code,
    required this.expiresAt,
    this.isUsed = false,
    required this.createdAt,
  });

  /// Vérifie si le code est expiré
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Vérifie si le code est valide (non utilisé et non expiré)
  bool get isValid => !isUsed && !isExpired;
  
  /// Temps restant avant expiration en secondes
  int get secondsUntilExpiry {
    final now = DateTime.now();
    if (isExpired) return 0;
    return expiresAt.difference(now).inSeconds;
  }
}

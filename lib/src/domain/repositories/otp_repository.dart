/// Interface du repository OTP.
abstract class OTPRepository {
  /// Génère un OTP et l'envoie par email
  Future<void> generateAndSendOTP(String email, String companyName);
  
  /// Vérifie un code OTP
  Future<bool> verifyOTP(String email, String otpCode);

  /// Envoie un email de bienvenue après inscription
  Future<void> sendWelcomeEmail({
    required String email,
    required String companyName,
  });
  
  /// Nettoie les OTP expirés
  Future<void> clearExpiredOTPs();
}

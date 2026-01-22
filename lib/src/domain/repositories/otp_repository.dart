/// Interface du repository OTP.
abstract class OTPRepository {
  /// Génère un OTP et l'envoie par email
  Future<void> generateAndSendOTP(String email, String companyName);
  
  /// Vérifie un code OTP
  Future<bool> verifyOTP(String email, String otpCode);
  
  /// Nettoie les OTP expirés
  Future<void> clearExpiredOTPs();
}

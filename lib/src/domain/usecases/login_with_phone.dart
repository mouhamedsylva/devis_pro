/// Use case: inscription/connexion par numéro de téléphone (offline).
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class LoginWithPhone {
  const LoginWithPhone({required this.userRepository});

  final UserRepository userRepository;

  Future<User> call(String phoneNumber) async {
    final normalized = phoneNumber.trim();
    final existing = await userRepository.findByPhone(normalized);
    
    if (existing != null) {
      // ✨ Vérifier si le compte est vérifié
      if (!existing.isVerified) {
        throw Exception('Votre compte n\'est pas vérifié. Veuillez vérifier votre email.');
      }
      
      // Mettre à jour la dernière connexion
      await userRepository.updateLastLogin(existing.id);
      return existing;
    }
    
    // Si pas de compte existant, créer un compte non vérifié (legacy pour compatibilité)
    return userRepository.createWithPhone(normalized);
  }
}


/// Use case: inscription/connexion par numéro de téléphone (offline).
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class LoginWithPhone {
  const LoginWithPhone({required this.userRepository});

  final UserRepository userRepository;

  Future<User> call(String phoneNumber) async {
    final normalized = phoneNumber.trim();
    final existing = await userRepository.findByPhone(normalized);
    if (existing != null) return existing;
    return userRepository.createWithPhone(normalized);
  }
}


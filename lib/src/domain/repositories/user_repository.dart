/// Abstraction du repository User (auth offline).
import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> findByPhone(String phoneNumber);
  Future<User?> findByEmail(String email);
  Future<User> createWithPhone(String phoneNumber);
  Future<User> createUser({
    required String phoneNumber,
    required String email,
    String? companyName,
    bool isVerified = false,
  });
  Future<void> updateLastLogin(int userId);
}


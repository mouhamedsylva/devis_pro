/// Abstraction du repository User (auth offline).
import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> findByPhone(String phoneNumber);
  Future<User> createWithPhone(String phoneNumber);
}


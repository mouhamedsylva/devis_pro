/// DTO SQLite <-> Entité User.
import '../../domain/entities/user.dart';

class UserModel {
  static User fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      phoneNumber: map['phoneNumber'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static Map<String, Object?> toInsert(String phoneNumber) {
    return {
      'phoneNumber': phoneNumber,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}


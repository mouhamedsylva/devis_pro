/// DTO SQLite <-> Entité User.
import '../../domain/entities/user.dart';

class UserModel {
  static User fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      phoneNumber: map['phoneNumber'] as String,
      email: map['email'] as String?,
      companyName: map['companyName'] as String?,
      isVerified: (map['isVerified'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.parse(map['lastLogin'] as String) 
          : null,
    );
  }

  static Map<String, Object?> toInsert({
    required String phoneNumber,
    String? email,
    String? companyName,
    bool isVerified = false,
  }) {
    return {
      'phoneNumber': phoneNumber,
      'email': email,
      'companyName': companyName,
      'isVerified': isVerified ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
      'lastLogin': null,
    };
  }
}


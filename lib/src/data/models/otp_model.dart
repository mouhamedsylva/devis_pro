/// DTO SQLite <-> Entité OTP.
import '../../domain/entities/otp.dart';

class OTPModel {
  static OTP fromMap(Map<String, Object?> map) {
    return OTP(
      id: map['id'] as int,
      email: map['email'] as String,
      code: map['code'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      isUsed: (map['isUsed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static Map<String, Object?> toInsert({
    required String email,
    required String code,
    required DateTime expiresAt,
  }) {
    return {
      'email': email,
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

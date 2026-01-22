/// Implémentation du repository OTP avec envoi par email.
import 'dart:math';

import '../../core/services/email_service.dart';
import '../../domain/repositories/otp_repository.dart';
import '../datasources/local/database_interface.dart';

class OTPRepositoryImpl implements OTPRepository {
  const OTPRepositoryImpl(this._db, this._emailService);

  final DatabaseInterface _db;
  final EmailService _emailService;

  @override
  Future<void> generateAndSendOTP(String email, String companyName) async {
    // 1. Invalider les anciens codes pour cet email
    await _db.update(
      'otp_codes',
      {'isUsed': 1},
      where: 'email = ? AND isUsed = 0',
      whereArgs: [email],
    );

    // 2. Générer un code à 6 chiffres
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();

    // 3. Expiration dans 5 minutes
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 5));

    // 4. Insérer dans la base
    await _db.insert('otp_codes', {
      'email': email,
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': 0,
      'createdAt': now.toIso8601String(),
    });

    // 5. Envoyer l'email avec le code
    try {
      await _emailService.sendOTP(
        recipientEmail: email,
        recipientName: companyName,
        otpCode: code,
      );
      print('✅ OTP envoyé à $email : $code'); // Pour debug
    } catch (e) {
      print('❌ Erreur envoi OTP : $e');
      throw Exception('Impossible d\'envoyer l\'email. Vérifiez votre connexion.');
    }
  }

  @override
  Future<bool> verifyOTP(String email, String code) async {
    final rows = await _db.query(
      'otp_codes',
      where: 'email = ? AND code = ? AND isUsed = 0',
      whereArgs: [email, code],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      print('❌ Code introuvable ou déjà utilisé');
      return false;
    }

    final row = rows.first;
    final expiresAt = DateTime.parse(row['expiresAt'] as String);

    // Vérifier l'expiration
    if (DateTime.now().isAfter(expiresAt)) {
      print('❌ Code expiré');
      // Marquer comme utilisé
      await _db.update(
        'otp_codes',
        {'isUsed': 1},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      return false;
    }

    // Marquer comme utilisé
    await _db.update(
      'otp_codes',
      {'isUsed': 1},
      where: 'id = ?',
      whereArgs: [row['id']],
    );

    print('✅ Code vérifié avec succès');
    return true;
  }

  @override
  Future<void> clearExpiredOTPs() async {
    final now = DateTime.now();
    await _db.delete(
      'otp_codes',
      where: 'expiresAt < ? OR isUsed = 1',
      whereArgs: [now.toIso8601String()],
    );
  }
}

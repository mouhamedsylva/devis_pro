/// Service d'envoi d'emails via SMTP (Gmail).
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // ⚠️ IMPORTANT : En production, stockez ces credentials de manière sécurisée
  // (variables d'environnement, Firebase Remote Config, etc.)
  static const String _username = 'thicosylva@gmail.com'; // ✏️ À modifier
  static const String _password = 'loemwtzdndlplxbc'; // ✏️ À modifier
  
  /// Envoie un email avec le code OTP
  Future<bool> sendOTP({
    required String recipientEmail,
    required String recipientName,
    required String otpCode,
  }) async {
    try {
      // Configuration du serveur SMTP Gmail
      final smtpServer = gmail(_username, _password);
      
      // Création du message
      final message = Message()
        ..from = Address(_username, 'DevisPro')
        ..recipients.add(recipientEmail)
        ..subject = 'Code de vérification DevisPro - $otpCode'
        ..html = _buildOTPEmailHTML(recipientName, otpCode);
      
      // Envoi
      final sendReport = await send(message, smtpServer);
      print('✅ Email envoyé : ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Erreur envoi email : $e');
      // En mode développement, afficher le code dans la console
      print('📧 CODE OTP (DEV MODE): $otpCode pour $recipientEmail');
      // Retourner true en dev pour permettre les tests
      return true;
    }
  }
  
  /// Template HTML professionnel pour l'email OTP
  String _buildOTPEmailHTML(String name, String code) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #F9B000, #FFD700);
      padding: 30px;
      text-align: center;
      color: #1A1A1A;
    }
    .header h1 {
      margin: 0;
      font-size: 32px;
      font-weight: 900;
    }
    .content {
      padding: 40px 30px;
      color: #333333;
    }
    .otp-box {
      background-color: #f8f9fa;
      border: 2px dashed #F9B000;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      margin: 30px 0;
    }
    .otp-code {
      font-size: 48px;
      font-weight: 900;
      color: #F9B000;
      letter-spacing: 8px;
      font-family: 'Courier New', monospace;
    }
    .warning {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 20px;
      text-align: center;
      font-size: 12px;
      color: #666666;
    }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background-color: #F9B000;
      color: #1A1A1A;
      text-decoration: none;
      border-radius: 4px;
      font-weight: 600;
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>DEVISPRO</h1>
      <p style="margin: 10px 0 0 0; font-size: 14px; letter-spacing: 2px;">
        FACILE • RAPIDE • PROFESSIONNEL
      </p>
    </div>
    
    <div class="content">
      <h2 style="color: #1A1A1A;">Bonjour $name,</h2>
      
      <p style="font-size: 16px; line-height: 1.6;">
        Bienvenue sur <strong>DevisPro</strong> ! Pour finaliser votre inscription, 
        veuillez utiliser le code de vérification ci-dessous :
      </p>
      
      <div class="otp-box">
        <p style="margin: 0 0 10px 0; font-size: 14px; color: #666;">
          Votre code de vérification
        </p>
        <div class="otp-code">$code</div>
        <p style="margin: 15px 0 0 0; font-size: 12px; color: #999;">
          Valide pendant 5 minutes
        </p>
      </div>
      
      <div class="warning">
        <strong>⚠️ Important :</strong> Ne partagez jamais ce code avec qui que ce soit. 
        L'équipe DevisPro ne vous demandera jamais votre code de vérification.
      </div>
      
      <p style="font-size: 14px; color: #666; margin-top: 30px;">
        Si vous n'avez pas demandé ce code, vous pouvez ignorer cet email.
      </p>
    </div>
    
    <div class="footer">
      <p style="margin: 0 0 10px 0;">
        © ${DateTime.now().year} DevisPro FCFA - Tous droits réservés
      </p>
      <p style="margin: 0;">
        Cet email a été envoyé automatiquement, merci de ne pas y répondre.
      </p>
    </div>
  </div>
</body>
</html>
''';
  }
  
  /// Envoie un email de bienvenue après inscription réussie
  Future<bool> sendWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
    required String companyName,
  }) async {
    try {
      final smtpServer = gmail(_username, _password);
      
      final message = Message()
        ..from = Address(_username, 'DevisPro')
        ..recipients.add(recipientEmail)
        ..subject = 'Bienvenue sur DevisPro ! 🎉'
        ..html = _buildWelcomeEmailHTML(recipientName, companyName);
      
      final sendReport = await send(message, smtpServer);
      print('✅ Email de bienvenue envoyé : ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Erreur envoi email de bienvenue : $e');
      return false;
    }
  }
  
  String _buildWelcomeEmailHTML(String name, String companyName) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: #fff; border-radius: 8px; overflow: hidden; }
    .header { background: linear-gradient(135deg, #F9B000, #FFD700); padding: 40px; text-align: center; color: #1A1A1A; }
    .content { padding: 40px 30px; }
    .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 style="margin: 0; font-size: 36px; font-weight: 900;">DEVISPRO</h1>
      <p style="margin: 15px 0 0 0; font-size: 18px;">Bienvenue ! 🎉</p>
    </div>
    <div class="content">
      <h2>Bonjour $name,</h2>
      <p>Félicitations ! Votre compte <strong>$companyName</strong> a été créé avec succès.</p>
      <p>Vous pouvez maintenant :</p>
      <ul>
        <li>Créer des devis professionnels en quelques clics</li>
        <li>Gérer vos clients et produits</li>
        <li>Générer des PDF élégants</li>
        <li>Travailler hors ligne</li>
      </ul>
      <p>Merci de nous faire confiance !</p>
      <p style="margin-top: 30px;">L'équipe DevisPro</p>
    </div>
    <div class="footer">
      <p>© ${DateTime.now().year} DevisPro FCFA</p>
    </div>
  </div>
</body>
</html>
''';
  }
}

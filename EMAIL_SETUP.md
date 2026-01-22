# 📧 Configuration de l'envoi d'emails (Gmail)

Pour que l'envoi d'OTP par email fonctionne, vous devez configurer un compte Gmail avec un mot de passe d'application.

## 🔧 Étapes de configuration

### 1. Créer un compte Gmail dédié (recommandé)

Créez un compte Gmail séparé pour votre application (ex: `devispro.app@gmail.com`)

### 2. Activer la validation en deux étapes

1. Allez sur [myaccount.google.com](https://myaccount.google.com/)
2. Sécurité → Validation en deux étapes
3. Activez la validation en deux étapes

### 3. Générer un mot de passe d'application

1. Allez sur [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
2. Sélectionnez "Autre (nom personnalisé)"
3. Tapez "DevisPro" puis Générer
4. **Copiez le mot de passe généré** (16 caractères)

### 4. Configurer dans votre code

Ouvrez `lib/src/core/services/email_service.dart` et remplacez :

```dart
static const String _username = 'votre.email@gmail.com'; // ✏️ Votre email Gmail
static const String _password = 'votre_mot_de_passe_app'; // ✏️ Mot de passe d'application (16 caractères)
```

## 🚀 Test

Une fois configuré, l'envoi d'OTP fonctionnera automatiquement lors de l'inscription.

## ⚠️ Sécurité - IMPORTANT !

**NE JAMAIS** commiter vos identifiants dans le code !

### Option 1 : Variables d'environnement (Recommandé)

Créez un fichier `.env` (à ajouter dans `.gitignore`) :

```env
SMTP_USERNAME=devispro.app@gmail.com
SMTP_PASSWORD=abcd efgh ijkl mnop
```

Utilisez le package `flutter_dotenv` :

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// Dans email_service.dart
static final String _username = dotenv.env['SMTP_USERNAME']!;
static final String _password = dotenv.env['SMTP_PASSWORD']!;
```

### Option 2 : Firebase Remote Config (Production)

Stockez les credentials dans Firebase Remote Config pour une meilleure sécurité.

## 🌍 Alternatives à Gmail

### Sendinblue (Brevo)
- 300 emails/jour gratuits
- API REST simple
- Package: `dio` pour les appels API

### Mailgun
- 5,000 emails/mois gratuits
- Bon pour la production

### EmailJS
- Gratuit jusqu'à 200 emails/mois
- Pas besoin de backend
- https://www.emailjs.com/

## 📝 Mode Développement

En mode développement, si l'envoi échoue, le code OTP est affiché dans la console :

```
📧 CODE OTP (DEV MODE): 123456 pour user@example.com
```

Vous pouvez utiliser ce code pour tester l'inscription.

# 📧 Configuration de l'Email pour l'Inscription OTP

## ⚠️ **IMPORTANT - À FAIRE AVANT DE LANCER L'APPLICATION**

L'inscription avec OTP par email nécessite une configuration SMTP. Voici comment procéder :

---

## 📝 **Étape 1 : Configurer Gmail**

### 1.1. Activer la validation en 2 étapes

1. Allez sur [https://myaccount.google.com](https://myaccount.google.com)
2. Cliquez sur **Sécurité** dans le menu de gauche
3. Sous "Comment vous connecter à Google", cliquez sur **Validation en 2 étapes**
4. Suivez les instructions pour l'activer

### 1.2. Générer un mot de passe d'application

1. Retournez sur [https://myaccount.google.com](https://myaccount.google.com)
2. Cliquez sur **Sécurité**
3. Sous "Comment vous connecter à Google", cliquez sur **Mots de passe des applications**
4. Si vous ne voyez pas cette option, assurez-vous que la validation en 2 étapes est activée
5. Sélectionnez **Autre (nom personnalisé)** et entrez "DevisPro"
6. Cliquez sur **Générer**
7. **Copiez le mot de passe généré** (16 caractères) - vous en aurez besoin !

---

## 🔧 **Étape 2 : Configurer l'Application**

Ouvrez le fichier `lib/main.dart` et modifiez la configuration de l'`EmailService` :

```dart
final emailService = EmailService(
  host: 'smtp.gmail.com',
  port: 587,
  username: 'votre.email@gmail.com', // ⬅️ Remplacez par votre email Gmail
  password: 'abcd efgh ijkl mnop',   // ⬅️ Remplacez par le mot de passe d'application
  ssl: false, // TLS pour port 587
);
```

### Exemple avec des vraies valeurs :

```dart
final emailService = EmailService(
  host: 'smtp.gmail.com',
  port: 587,
  username: 'amadou.diallo@gmail.com',
  password: 'xyzw abcd efgh ijkl',
  ssl: false,
);
```

---

## 🧪 **Étape 3 : Tester**

1. Lancez l'application : `flutter run -d chrome`
2. Cliquez sur **CRÉER MON COMPTE**
3. Remplissez le formulaire avec :
   - Nom de l'entreprise : `Test SARL`
   - Email : **VOTRE EMAIL RÉEL** (vous y recevrez le code)
   - Téléphone : `77 123 45 67`
4. Cliquez sur **RECEVOIR LE CODE**
5. Vérifiez votre boîte email (parfois dans les spam)
6. Entrez le code à 6 chiffres
7. Validez !

---

## 🐛 **Dépannage**

### Le code n'arrive pas ?

1. **Vérifiez les spams** dans votre boîte email
2. **Vérifiez la console** : les codes OTP sont affichés pour le debug
3. **Vérifiez vos identifiants** dans `main.dart`
4. **Testez avec votre propre email** (pas un email générique)

### Erreur "Message not sent" ?

- Vérifiez que la validation en 2 étapes est activée
- Vérifiez que le mot de passe d'application est correct (16 caractères)
- Vérifiez votre connexion Internet

### Erreur de connexion SMTP ?

- Port 587 + TLS (ssl: false) est la configuration standard pour Gmail
- Si ça ne fonctionne pas, essayez port 465 + SSL (ssl: true)

---

## 🔒 **Sécurité**

⚠️ **NE JAMAIS COMMITTER** vos identifiants dans Git !

Pour la production, utilisez plutôt :
- Des variables d'environnement
- Un fichier `.env` (et ajoutez-le à `.gitignore`)
- Un service backend dédié

---

## 🎯 **Prochaines Étapes**

Une fois que l'inscription fonctionne :

1. L'utilisateur crée son compte avec son email professionnel
2. Il reçoit un code OTP par email (valide 5 minutes)
3. Il entre le code pour vérifier son compte
4. Son compte est marqué comme `isVerified = true`
5. Il peut maintenant se connecter avec son numéro de téléphone
6. Il reçoit un email de bienvenue

---

## 📚 **Flux Complet**

```
┌─────────────────┐
│ INSCRIPTION     │
│ (Registration)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ 1. Entrer les infos     │
│    - Entreprise         │
│    - Email              │
│    - Téléphone          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ 2. Envoi OTP par email  │
│    Code : 123456        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ 3. Vérification OTP     │
│    (5 min countdown)    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ 4. Compte créé !        │
│    isVerified = true    │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ 5. Email de bienvenue   │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ CONNEXION avec numéro   │
└─────────────────────────┘
```

---

## ✅ **C'est tout !**

Votre système d'inscription professionnel avec OTP par email est maintenant opérationnel ! 🎉

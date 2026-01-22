# DevisPro (FCFA) – Génération de devis offline-first

Application mobile Flutter destinée aux artisans, PME, freelances et commerçants africains pour **générer des devis professionnels en FCFA**, sans connexion permanente.

## Fonctionnalités MVP

- **Authentification offline**: connexion/inscription via **numéro de téléphone** (local SQLite)
- **Entreprise**: nom, téléphone, adresse, devise (label FCFA), TVA
- **Clients**: ajout / modification / suppression
- **Produits / services**: ajout / modification / suppression (PU + TVA)
- **Devis**:
  - numérotation automatique `DV-YYYYMMDD-####`
  - calculs automatiques HT/TVA/TTC
  - statuts: Brouillon / Envoyé / Accepté
  - export PDF + partage (WhatsApp via feuille de partage système)

## Tech

- **Clean Architecture**: `lib/src/{domain,data,presentation,core}`
- **State management**: `flutter_bloc`
- **Stockage**: SQLite (`sqflite`)
- **PDF**: `pdf` + `printing`
- **Formatage**: `intl`

## Structure

- `lib/src/domain`: entités + repositories abstraits + usecases
- `lib/src/data`: datasources SQLite + models + repositories impl
- `lib/src/presentation`: blocs + screens + widgets + services (PDF)
- `lib/src/core`: thème, couleurs, utilitaires

## Lancer le projet

### 📱 Android/iOS (recommandé)

```bash
flutter pub get

# Connecter un appareil ou lancer un émulateur, puis :
flutter devices  # Lister les appareils disponibles
flutter run -d <device_id>

# Ou simplement (Flutter choisira le premier appareil)
flutter run
```

### 🌐 Web (Chrome) - Limitations

DevisPro fonctionne sur **mobile (Android/iOS)** sans configuration. Pour le **Web**, SQLite nécessite des binaires WebAssembly supplémentaires :

```bash
# Setup Web (optionnel, complexe)
dart run sqflite_common_ffi_web:setup
dart compile js web/sqflite_sw.dart -o web/sqflite_sw.js
flutter run -d chrome
```

**Note** : Pour le MVP, privilégiez Android/iOS (objectif prioritaire du cahier des charges).

## Notes (évolutions prévues)

- Facturation
- Paiement Mobile Money
- Multi-utilisateurs
- Synchronisation Cloud (future)

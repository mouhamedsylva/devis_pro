# Implémentation des Modèles de Devis (Templates)

## 📋 Vue d'ensemble

Un système complet de templates de devis a été implémenté, permettant de :
- **Créer des devis rapidement** à partir de modèles prédéfinis
- **Personnaliser** ses propres modèles
- **Organiser** les modèles par secteur d'activité
- **Réutiliser** des configurations de devis fréquentes

---

## 🏗️ Architecture

### 1. Entités (Domain Layer)

#### `QuoteTemplate`
```dart
lib/src/domain/entities/template.dart
```
Propriétés:
- `id`: Identifiant unique
- `name`: Nom du template
- `description`: Description courte
- `category`: Secteur d'activité (BTP, IT, Consulting, Commerce, Service, Autre)
- `isCustom`: Distingue templates prédéfinis (false) des personnalisés (true)
- `notes`: Notes par défaut
- `validityDays`: Durée de validité par défaut
- `termsAndConditions`: Conditions générales par défaut
- `createdAt`: Date de création

#### `TemplateItem`
```dart
lib/src/domain/entities/template.dart
```
Propriétés:
- `id`: Identifiant unique
- `templateId`: Référence au template parent
- `productName`: Nom du produit/service
- `description`: Description détaillée
- `quantity`: Quantité
- `unitPrice`: Prix unitaire
- `vatRate`: Taux de TVA
- `displayOrder`: Ordre d'affichage dans le template

---

### 2. Base de données

#### Schéma SQL (Mobile - SQLite)

**Table `templates`:**
```sql
CREATE TABLE templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  isCustom INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  validityDays INTEGER,
  termsAndConditions TEXT,
  createdAt TEXT NOT NULL
);
```

**Table `template_items`:**
```sql
CREATE TABLE template_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  templateId INTEGER NOT NULL,
  productName TEXT NOT NULL,
  description TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unitPrice REAL NOT NULL,
  vatRate REAL NOT NULL,
  displayOrder INTEGER NOT NULL,
  FOREIGN KEY (templateId) REFERENCES templates(id) ON DELETE CASCADE
);
```

**Indexes:**
- `idx_templates_category` sur `templates(category)`
- `idx_template_items_templateId` sur `template_items(templateId)`

#### Schéma Web (IndexedDB)

Object stores équivalents avec les mêmes champs.

---

### 3. Repository

#### `TemplateRepository` (Interface)
```dart
lib/src/domain/repositories/template_repository.dart
```
Méthodes:
- `getAllTemplates()`: Récupère tous les templates
- `getTemplatesByCategory(String category)`: Filtre par catégorie
- `getTemplateById(int id)`: Récupère un template spécifique
- `getPredefinedTemplates()`: Templates prédéfinis uniquement
- `getCustomTemplates()`: Templates personnalisés uniquement
- `createTemplate(QuoteTemplate, List<TemplateItem>)`: Crée un nouveau template
- `updateTemplate(QuoteTemplate, List<TemplateItem>)`: Met à jour un template
- `deleteTemplate(int id)`: Supprime un template
- `getTemplateItems(int templateId)`: Récupère les items d'un template
- `initializePredefinedTemplates()`: Initialise les templates au premier lancement

#### `TemplateRepositoryImpl` (Implémentation)
```dart
lib/src/data/repositories/template_repository_impl.dart
```
Implémente toutes les méthodes et inclut les **templates prédéfinis** pour chaque secteur.

---

### 4. BLoC (State Management)

#### Events (`TemplateEvent`)
```dart
lib/src/presentation/blocs/template/template_event.dart
```
- `TemplateLoadAll`: Charge tous les templates
- `TemplateLoadByCategory(category)`: Charge par catégorie
- `TemplateLoadPredefined`: Charge les prédéfinis
- `TemplateLoadCustom`: Charge les personnalisés
- `TemplateLoadDetails(templateId)`: Charge un template avec ses items
- `TemplateCreate(template, items)`: Crée un template
- `TemplateUpdate(template, items)`: Met à jour un template
- `TemplateDelete(templateId)`: Supprime un template
- `TemplateInitializePredefined`: Initialise les templates au démarrage

#### States (`TemplateState`)
```dart
lib/src/presentation/blocs/template/template_state.dart
```
- `TemplateInitial`: État initial
- `TemplateLoading`: Chargement en cours
- `TemplateListLoaded(templates)`: Liste chargée
- `TemplateDetailsLoaded(template, items)`: Détails chargés
- `TemplateCreated(templateId)`: Template créé
- `TemplateUpdated`: Template mis à jour
- `TemplateDeleted`: Template supprimé
- `TemplatePredefinedInitialized`: Templates prédéfinis initialisés
- `TemplateError(message)`: Erreur

#### BLoC (`TemplateBloc`)
```dart
lib/src/presentation/blocs/template/template_bloc.dart
```
Gère la logique métier et les transitions d'états.

---

## 🎨 Interface utilisateur

### 1. Écran de gestion des templates (`TemplatesScreen`)

**Fonctionnalités:**
- **Onglets de filtrage** par catégorie (Tous, BTP, IT, Consulting, Commerce, Service, Personnalisés)
- **Carte pour chaque template** affichant:
  - Nom et description
  - Badge de catégorie avec code couleur
  - Type (Prédéfini ⭐ / Personnalisé 👤)
  - Durée de validité
  - Actions (Voir détails, Supprimer si personnalisé)
- **Bottom sheet de détails** avec:
  - Informations complètes (notes, conditions)
  - Liste des articles/services
  - Total HT, TVA, TTC
  - Bouton "Utiliser" pour créer un devis à partir du template
- **Bouton FAB** pour créer un template personnalisé (onglet "Personnalisés")
- **Empty state** avec logo DevisPro

**Accès:**
Depuis le Dashboard → Section "Raccourcis" → Carte "Modèles" 🟣

**Fichier:**
```dart
lib/src/presentation/screens/templates_screen.dart
```

---

### 2. Intégration dans `QuoteEditorScreen`

**Fonctionnalités:**
- **Bouton dans l'AppBar** (icône `note_add`) pour utiliser un template
- **Modal de sélection** affichant tous les templates disponibles
- **Pré-remplissage automatique** des lignes du devis avec les items du template sélectionné
- **Message de confirmation** indiquant le nombre d'articles chargés

**Workflow:**
1. L'utilisateur clique sur "Utiliser un modèle" 📄
2. Sélectionne un template dans la liste
3. Les articles du template sont automatiquement ajoutés au devis
4. L'utilisateur peut modifier/compléter avant validation

**Modifications:**
```dart
lib/src/presentation/screens/quote_editor_screen.dart
- Ajout du bouton dans l'AppBar
- Fonction _showTemplatesDialog()
- Fonction _loadTemplateData()
```

---

### 3. Sauvegarde depuis `QuotesScreen`

**Fonctionnalités:**
- **Nouveau bouton d'action** 🔖 sur chaque carte de devis (couleur violette)
- **Dialogue de création** demandant:
  - Nom du template
  - Description
  - Catégorie (liste déroulante)
- **Conversion automatique** d'un devis en template personnalisé
- **Notification de succès** avec action "Voir"

**Workflow:**
1. L'utilisateur clique sur 🔖 "Sauvegarder comme modèle"
2. Remplit le formulaire de création
3. Le devis est converti en template réutilisable
4. Notification de succès

**Modifications:**
```dart
lib/src/presentation/screens/quotes_screen.dart
- Ajout du bouton dans _buildQuoteCard()
- Fonction _saveAsTemplate()
```

---

## 📚 Templates prédéfinis

### BTP
1. **Construction Maison Individuelle**
   - Gros œuvre (8 500 000 FCFA)
   - Charpente et couverture (3 200 000 FCFA)
   - Menuiseries extérieures (1 800 000 FCFA)
   - Électricité (1 200 000 FCFA)
   - Plomberie et sanitaires (1 500 000 FCFA)

2. **Rénovation Appartement**
   - Démolition et évacuation (450 000 FCFA)
   - Création cloisons (680 000 FCFA)
   - Revêtements sols (920 000 FCFA)
   - Peinture (580 000 FCFA)

### IT
1. **Site Web Vitrine**
   - Conception et design (850 000 FCFA)
   - Développement (1 200 000 FCFA)
   - Intégration CMS (650 000 FCFA)
   - Référencement SEO (350 000 FCFA)
   - Hébergement et maintenance 1 an (180 000 FCFA)

2. **Application Mobile (Android/iOS)**
   - Analyse et spécifications (1 200 000 FCFA)
   - Design UI/UX (1 500 000 FCFA)
   - Développement Flutter (4 500 000 FCFA)
   - Backend et API (2 800 000 FCFA)
   - Tests et publication (950 000 FCFA)

### Consulting
1. **Audit et Conseil Stratégique**
   - Audit initial (1 500 000 FCFA)
   - Élaboration stratégie (2 200 000 FCFA)
   - Accompagnement mise en œuvre × 3 mois (850 000 FCFA/mois)

### Commerce
1. **Boutique E-commerce**
   - Setup e-commerce (950 000 FCFA)
   - Design boutique (1 400 000 FCFA)
   - Intégration paiement (550 000 FCFA)
   - Formation (280 000 FCFA)

### Service
1. **Formation Professionnelle**
   - Conception programme (650 000 FCFA)
   - Supports pédagogiques (450 000 FCFA)
   - Animation formation 5 jours (180 000 FCFA/jour)
   - Évaluation et certification (220 000 FCFA)

---

## 🚀 Initialisation

Les templates prédéfinis sont automatiquement créés au **premier lancement** de l'application via:
```dart
main.dart → TemplateBloc → TemplateInitializePredefined
```

Le BLoC vérifie si des templates prédéfinis existent déjà pour éviter les doublons.

---

## 🔧 Utilisation

### Pour l'utilisateur final

#### 1. Consulter les modèles
1. Dashboard → Raccourcis → "Modèles" 🟣
2. Choisir un onglet (Tous / BTP / IT / etc.)
3. Cliquer sur une carte pour voir les détails
4. Bouton "Utiliser" pour créer un devis basé sur ce modèle

#### 2. Créer un devis depuis un modèle
1. Dashboard → "Nouveau devis" ou Devis → "+"
2. Cliquer sur l'icône 📄 dans l'AppBar
3. Sélectionner un modèle
4. Les articles sont pré-remplis automatiquement
5. Compléter et valider le devis

#### 3. Sauvegarder un devis comme modèle
1. Aller dans l'onglet "Devis"
2. Sur un devis existant, cliquer sur 🔖
3. Remplir: Nom, Description, Catégorie
4. Confirmer → Le modèle est créé
5. Accessible dans "Modèles" → "Personnalisés"

#### 4. Supprimer un modèle personnalisé
1. Modèles → Personnalisés
2. Cliquer sur l'icône 🗑️ sur une carte
3. Confirmer la suppression

---

## 📱 Navigation

```
Dashboard
    ├─ Raccourcis → Modèles
    │       └─ TemplatesScreen
    │           ├─ Onglets (Tous, BTP, IT, etc.)
    │           ├─ Liste des templates
    │           ├─ Bottom sheet détails
    │           └─ FAB "Nouveau template"
    │
    ├─ Nouveau devis
    │       └─ QuoteEditorScreen
    │           └─ Bouton AppBar "Utiliser un modèle"
    │               └─ Modal sélection template
    │
    └─ Onglet Devis
            └─ QuotesScreen
                └─ Bouton 🔖 "Sauvegarder comme modèle"
                    └─ Dialogue création template
```

---

## 🎯 Avantages

### Pour l'utilisateur
- ✅ **Gain de temps** : Créer un devis en quelques clics
- ✅ **Cohérence** : Standardiser les offres par secteur
- ✅ **Personnalisation** : Créer ses propres modèles
- ✅ **Organisation** : Classer par catégorie

### Technique
- ✅ **Architecture Clean** : Séparation Domain/Data/Presentation
- ✅ **BLoC Pattern** : State management robuste
- ✅ **Offline-first** : Fonctionne sans connexion
- ✅ **Cross-platform** : SQLite (mobile) + IndexedDB (web)
- ✅ **Évolutif** : Facile d'ajouter de nouveaux templates

---

## 🛠️ Développement futur

### Fonctionnalités possibles
- [ ] **Modification de templates prédéfinis** (créer une copie personnalisée)
- [ ] **Partage de templates** entre utilisateurs
- [ ] **Import/Export de templates** (JSON)
- [ ] **Statistiques d'utilisation** des templates
- [ ] **Templates favoris** ⭐
- [ ] **Recherche et tri** avancés
- [ ] **Duplication de templates** personnalisés
- [ ] **Prévisualisation PDF** d'un template
- [ ] **Modèles multi-langues**
- [ ] **Tags personnalisés** pour les templates

---

## 📝 Modifications apportées

### Fichiers créés
1. `lib/src/domain/entities/template.dart`
2. `lib/src/data/models/template_model.dart`
3. `lib/src/domain/repositories/template_repository.dart`
4. `lib/src/data/repositories/template_repository_impl.dart`
5. `lib/src/presentation/blocs/template/template_event.dart`
6. `lib/src/presentation/blocs/template/template_state.dart`
7. `lib/src/presentation/blocs/template/template_bloc.dart`
8. `lib/src/presentation/screens/templates_screen.dart`
9. `TEMPLATES_IMPLEMENTATION.md` (ce fichier)

### Fichiers modifiés
1. `lib/src/data/datasources/local/database_mobile.dart` (v4 → v5)
2. `lib/src/data/datasources/local/database_web.dart` (v4 → v5)
3. `lib/main.dart` (ajout TemplateRepository et TemplateBloc)
4. `lib/src/presentation/screens/dashboard_screen.dart` (ajout raccourci Modèles)
5. `lib/src/presentation/screens/quote_editor_screen.dart` (bouton "Utiliser un modèle")
6. `lib/src/presentation/screens/quotes_screen.dart` (bouton "Sauvegarder comme modèle")

---

## ✅ Tests recommandés

### Tests fonctionnels
1. Vérifier l'initialisation des templates prédéfinis au premier lancement
2. Créer un template personnalisé depuis un devis
3. Utiliser un template pour créer un nouveau devis
4. Filtrer les templates par catégorie
5. Supprimer un template personnalisé
6. Vérifier que les templates prédéfinis ne peuvent pas être supprimés

### Tests techniques
1. Migration de base de données (v4 → v5)
2. Cascade delete sur template_items
3. Persistance des templates après fermeture de l'app
4. Compatibilité web (IndexedDB)

---

## 🎉 Conclusion

Un système complet de templates de devis a été implémenté avec succès, offrant une expérience utilisateur fluide et professionnelle. L'architecture permet une évolution facile et l'ajout de nouvelles fonctionnalités.

**Toutes les tâches sont terminées ✅**

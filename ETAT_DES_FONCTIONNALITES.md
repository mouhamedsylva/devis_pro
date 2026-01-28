# État des Fonctionnalités - DevisPro

Ce document récapitule les fonctionnalités implémentées dans la version actuelle et les pistes d'évolution pour la V2.

## ✅ Fonctionnalités Implémentées (V1)

### 1. Gestion des Devis
- **Éditeur dynamique** : Création de devis avec ajout/suppression d'articles en temps réel.
- **Calcul automatique** : Calcul automatique du Total HT, de la TVA et du Total TTC.
- **Génération PDF** : Moteur de génération de PDF professionnel avec logo de l'entreprise.
- **Aperçu Instantané** : Visualisation du document avant enregistrement/partage.
- **Statuts** : Gestion des devis par état (Brouillon, Envoyé, Payé, Annulé).

### 2. Gestion des Clients & Produits
- **Répertoire Client** : Importation depuis les contacts du téléphone ou création manuelle.
- **Catalogue Produits** : Enregistrement des articles récurrents avec prix unitaires et unités (Heures, Forfait, Unité).
- **Recherche rapide** : Filtres de recherche dans l'éditeur pour sélectionner clients et produits.

### 3. Modèles (Templates)
- **Système de Modèles** : Utilisation de modèles prédéfinis par secteur (BTP, IT, Service).
- **Personnalisation** : Possibilité de créer ses propres modèles pour gagner du temps.

### 4. Authentification & Sécurité
- **OTP (One-Time Password)** : Système de connexion/inscription sécurisé par email.
- **Profil Entreprise** : Configuration des informations légales, logo et signature numérique.

### 5. Infrastructure Technique
- **Base de données locale (SQLite)** : Fonctionnement 100% hors-ligne.
- **Architecture Clean** : Séparation nette entre données (Data), métier (Domain) et interface (Presentation).
- **Responsive Design** : Adaptation à toutes les tailles d'écran (via Sizer).

---

## 🚀 Fonctionnalités suggérées pour la V2

### 1. Cloud & Synchronisation
- **Synchronisation Multi-appareils** : Sauvegarde sur le Cloud (Firebase/Supabase) pour retrouver ses données sur tablette et mobile.
- **Mode Travail d'Équipe** : Possibilité de partager un compte entre plusieurs collaborateurs.

### 2. Paiement & Facturation
- **Conversion Devis en Facture** : Transformer un devis validé en facture d'un seul clic.
- **QR Code de Paiement** : Intégration de QR codes (Wave, Orange Money, PayPal) directement sur le PDF.
- **Suivi des Paiements** : Relances automatiques pour les devis en attente de paiement.

### 3. Analyses & Rapports
- **Tableau de Bord Avancé** : Graphiques de revenus mensuels, statistiques sur les produits les plus vendus.
- **Export Comptable** : Exportation des données au format Excel ou CSV pour le comptable.

### 4. Intelligence Artificielle
- **Saisie Intelligente** : Prédiction des prix basées sur l'historique.
- **Assistant de Rédaction** : Génération de descriptions de services par IA.

### 5. Communication
- **Envoi Direct WhatsApp** : Partage du PDF via WhatsApp directement depuis l'application.
- **Historique d'Activité** : Journal des modifications détaillé pour chaque devis.

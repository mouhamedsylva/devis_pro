import '../../domain/entities/template.dart';
import '../../domain/repositories/template_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/template_model.dart';

/// Implémentation du TemplateRepository.
class TemplateRepositoryImpl implements TemplateRepository {
  const TemplateRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<QuoteTemplate>> getAllTemplates() async {
    final results = await _db.database.query('templates', orderBy: 'createdAt DESC');
    return results.map((e) => QuoteTemplateModel.fromMap(e)).toList();
  }

  @override
  Future<List<QuoteTemplate>> getTemplatesByCategory(String category) async {
    final results = await _db.database.query(
      'templates',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return results.map((e) => QuoteTemplateModel.fromMap(e)).toList();
  }

  @override
  Future<QuoteTemplate?> getTemplateById(int id) async {
    final results = await _db.database.query(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return QuoteTemplateModel.fromMap(results.first);
  }

  @override
  Future<List<QuoteTemplate>> getPredefinedTemplates() async {
    final results = await _db.database.query(
      'templates',
      where: 'isCustom = ?',
      whereArgs: [0],
      orderBy: 'category ASC, name ASC',
    );
    return results.map((e) => QuoteTemplateModel.fromMap(e)).toList();
  }

  @override
  Future<List<QuoteTemplate>> getCustomTemplates() async {
    final results = await _db.database.query(
      'templates',
      where: 'isCustom = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return results.map((e) => QuoteTemplateModel.fromMap(e)).toList();
  }

  @override
  Future<int> createTemplate(QuoteTemplate template, List<TemplateItem> items) async {
    return await _db.database.transaction((txn) async {
      // Insérer le template
      final templateModel = QuoteTemplateModel(
        id: template.id,
        name: template.name,
        description: template.description,
        category: template.category,
        isCustom: template.isCustom,
        createdAt: template.createdAt,
        notes: template.notes,
        validityDays: template.validityDays,
        termsAndConditions: template.termsAndConditions,
      );

      final templateId = await txn.insert('templates', templateModel.toInsert());

      // Insérer les items
      for (final item in items) {
        final itemModel = TemplateItemModel(
          id: item.id,
          templateId: templateId,
          productName: item.productName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          displayOrder: item.displayOrder,
        );
        await txn.insert('template_items', itemModel.toInsert());
      }

      return templateId;
    });
  }

  @override
  Future<void> updateTemplate(QuoteTemplate template, List<TemplateItem> items) async {
    await _db.database.transaction((txn) async {
      // Mettre à jour le template
      final templateModel = QuoteTemplateModel(
        id: template.id,
        name: template.name,
        description: template.description,
        category: template.category,
        isCustom: template.isCustom,
        createdAt: template.createdAt,
        notes: template.notes,
        validityDays: template.validityDays,
        termsAndConditions: template.termsAndConditions,
      );

      await txn.update(
        'templates',
        templateModel.toMap(),
        where: 'id = ?',
        whereArgs: [template.id],
      );

      // Supprimer les anciens items
      await txn.delete(
        'template_items',
        where: 'templateId = ?',
        whereArgs: [template.id],
      );

      // Insérer les nouveaux items
      for (final item in items) {
        final itemModel = TemplateItemModel(
          id: 0, // Will be auto-incremented
          templateId: template.id,
          productName: item.productName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          displayOrder: item.displayOrder,
        );
        await txn.insert('template_items', itemModel.toInsert());
      }
    });
  }

  @override
  Future<void> deleteTemplate(int id) async {
    // Les items seront supprimés automatiquement grâce à ON DELETE CASCADE
    await _db.database.delete(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<TemplateItem>> getTemplateItems(int templateId) async {
    final results = await _db.database.query(
      'template_items',
      where: 'templateId = ?',
      whereArgs: [templateId],
      orderBy: 'displayOrder ASC',
    );
    return results.map((e) => TemplateItemModel.fromMap(e)).toList();
  }

  @override
  Future<void> initializePredefinedTemplates() async {
    // Vérifier si des templates prédéfinis existent déjà
    final existingTemplates = await getPredefinedTemplates();
    if (existingTemplates.isNotEmpty) {
      return; // Les templates sont déjà initialisés
    }

    // Créer les templates prédéfinis pour chaque secteur
    await _createBTPTemplates();
    await _createITTemplates();
    await _createConsultingTemplates();
    await _createCommerceTemplates();
    await _createServiceTemplates();
  }

  // =====================================================================
  // Templates prédéfinis par secteur
  // =====================================================================

  Future<void> _createBTPTemplates() async {
    // Template 1: Construction Maison
    final template1 = QuoteTemplateModel(
      id: 0,
      name: 'Construction Maison Individuelle',
      description: 'Devis complet pour la construction d\'une maison',
      category: 'BTP',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Devis valable sous réserve de l\'étude technique du terrain.',
      validityDays: 60,
      termsAndConditions: 'Paiement échelonné selon avancement des travaux. Acompte de 30% à la signature.',
    );

    final items1 = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Gros œuvre',
        description: 'Fondations, murs porteurs, dalle béton',
        quantity: 1,
        unitPrice: 8500000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Charpente et couverture',
        description: 'Charpente bois, tuiles, isolation',
        quantity: 1,
        unitPrice: 3200000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Menuiseries extérieures',
        description: 'Portes et fenêtres aluminium',
        quantity: 1,
        unitPrice: 1800000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Électricité',
        description: 'Installation complète, tableau électrique',
        quantity: 1,
        unitPrice: 1200000,
        vatRate: 0.18,
        displayOrder: 4,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Plomberie et sanitaires',
        description: 'Réseau eau, évacuation, équipements',
        quantity: 1,
        unitPrice: 1500000,
        vatRate: 0.18,
        displayOrder: 5,
      ),
    ];

    await createTemplate(template1, items1);

    // Template 2: Rénovation Appartement
    final template2 = QuoteTemplateModel(
      id: 0,
      name: 'Rénovation Appartement',
      description: 'Rénovation complète d\'un appartement',
      category: 'BTP',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Devis établi après visite sur place.',
      validityDays: 30,
      termsAndConditions: 'Acompte de 40% à la commande. Délai de réalisation: 8 semaines.',
    );

    final items2 = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Démolition et évacuation',
        description: 'Démolition cloisons, évacuation gravats',
        quantity: 1,
        unitPrice: 450000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Création cloisons',
        description: 'Cloisons placo, isolation phonique',
        quantity: 1,
        unitPrice: 680000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Revêtements sols',
        description: 'Carrelage, parquet stratifié',
        quantity: 1,
        unitPrice: 920000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Peinture',
        description: 'Peinture murs et plafonds, 2 couches',
        quantity: 1,
        unitPrice: 580000,
        vatRate: 0.18,
        displayOrder: 4,
      ),
    ];

    await createTemplate(template2, items2);
  }

  Future<void> _createITTemplates() async {
    // Template 1: Site Web Vitrine
    final template1 = QuoteTemplateModel(
      id: 0,
      name: 'Site Web Vitrine',
      description: 'Création d\'un site web vitrine professionnel',
      category: 'IT',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Hébergement et maintenance la première année inclus.',
      validityDays: 45,
      termsAndConditions: 'Paiement 50% à la commande, 50% à la livraison. Délai: 6 semaines.',
    );

    final items1 = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Conception et design',
        description: 'Maquettes, charte graphique, UX/UI',
        quantity: 1,
        unitPrice: 850000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Développement',
        description: 'Développement HTML/CSS/JS responsive',
        quantity: 1,
        unitPrice: 1200000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Intégration CMS',
        description: 'WordPress avec back-office personnalisé',
        quantity: 1,
        unitPrice: 650000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Référencement SEO',
        description: 'Optimisation SEO on-page, sitemap',
        quantity: 1,
        unitPrice: 350000,
        vatRate: 0.18,
        displayOrder: 4,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Hébergement et maintenance',
        description: 'Hébergement premium + maintenance 1 an',
        quantity: 1,
        unitPrice: 180000,
        vatRate: 0.18,
        displayOrder: 5,
      ),
    ];

    await createTemplate(template1, items1);

    // Template 2: Application Mobile
    final template2 = QuoteTemplateModel(
      id: 0,
      name: 'Application Mobile (Android/iOS)',
      description: 'Développement d\'une application mobile native',
      category: 'IT',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Inclut la publication sur Play Store et App Store.',
      validityDays: 60,
      termsAndConditions: 'Paiement en 3 fois: 40% commande, 40% beta, 20% livraison.',
    );

    final items2 = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Analyse et spécifications',
        description: 'Cahier des charges, wireframes, user stories',
        quantity: 1,
        unitPrice: 1200000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Design UI/UX',
        description: 'Maquettes haute fidélité, prototypes',
        quantity: 1,
        unitPrice: 1500000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Développement mobile',
        description: 'Développement Flutter (Android + iOS)',
        quantity: 1,
        unitPrice: 4500000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Backend et API',
        description: 'API REST, base de données, authentification',
        quantity: 1,
        unitPrice: 2800000,
        vatRate: 0.18,
        displayOrder: 4,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Tests et publication',
        description: 'Tests QA, publication stores, documentation',
        quantity: 1,
        unitPrice: 950000,
        vatRate: 0.18,
        displayOrder: 5,
      ),
    ];

    await createTemplate(template2, items2);
  }

  Future<void> _createConsultingTemplates() async {
    // Template: Audit et Conseil
    final template = QuoteTemplateModel(
      id: 0,
      name: 'Audit et Conseil Stratégique',
      description: 'Mission d\'audit et recommandations stratégiques',
      category: 'Consulting',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Prestation sur site ou à distance selon besoins.',
      validityDays: 30,
      termsAndConditions: 'Facturation mensuelle. Engagement minimum 3 mois.',
    );

    final items = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Audit initial',
        description: 'Analyse de l\'existant, identification problématiques',
        quantity: 1,
        unitPrice: 1500000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Élaboration stratégie',
        description: 'Plan d\'action, roadmap, recommandations',
        quantity: 1,
        unitPrice: 2200000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Accompagnement mise en œuvre',
        description: 'Suivi mensuel, ajustements, reporting',
        quantity: 3,
        unitPrice: 850000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
    ];

    await createTemplate(template, items);
  }

  Future<void> _createCommerceTemplates() async {
    // Template: E-commerce
    final template = QuoteTemplateModel(
      id: 0,
      name: 'Boutique E-commerce',
      description: 'Création d\'une boutique en ligne complète',
      category: 'Commerce',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Formation à la gestion de la boutique incluse.',
      validityDays: 45,
      termsAndConditions: 'Paiement: 40% commande, 40% mise en ligne, 20% formation.',
    );

    final items = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Setup e-commerce',
        description: 'Installation Shopify/WooCommerce, configuration',
        quantity: 1,
        unitPrice: 950000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Design boutique',
        description: 'Thème personnalisé, pages produits, panier',
        quantity: 1,
        unitPrice: 1400000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Intégration paiement',
        description: 'Passerelles de paiement (Stripe, PayPal, etc.)',
        quantity: 1,
        unitPrice: 550000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Formation',
        description: 'Formation gestion boutique, commandes, stock',
        quantity: 1,
        unitPrice: 280000,
        vatRate: 0.18,
        displayOrder: 4,
      ),
    ];

    await createTemplate(template, items);
  }

  Future<void> _createServiceTemplates() async {
    // Template: Formation Professionnelle
    final template = QuoteTemplateModel(
      id: 0,
      name: 'Formation Professionnelle',
      description: 'Programme de formation sur mesure',
      category: 'Service',
      isCustom: false,
      createdAt: DateTime.now(),
      notes: 'Formation en présentiel ou distanciel. Supports fournis.',
      validityDays: 30,
      termsAndConditions: 'Acompte 30% à l\'inscription. Groupe de 5 à 15 personnes.',
    );

    final items = [
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Conception programme',
        description: 'Analyse besoins, programme pédagogique',
        quantity: 1,
        unitPrice: 650000,
        vatRate: 0.18,
        displayOrder: 1,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Supports pédagogiques',
        description: 'Présentation, exercices, documentation',
        quantity: 1,
        unitPrice: 450000,
        vatRate: 0.18,
        displayOrder: 2,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Animation formation',
        description: 'Formation en salle, 5 jours (35h)',
        quantity: 5,
        unitPrice: 180000,
        vatRate: 0.18,
        displayOrder: 3,
      ),
      const TemplateItem(
        id: 0,
        templateId: 0,
        productName: 'Évaluation et certification',
        description: 'Tests, évaluation, certificats',
        quantity: 1,
        unitPrice: 220000,
        vatRate: 0.18,
        displayOrder: 4,
      ),
    ];

    await createTemplate(template, items);
  }
}

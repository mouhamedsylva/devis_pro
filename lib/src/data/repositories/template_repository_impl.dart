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
          id: 0,
          templateId: templateId,
          productName: item.productName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          displayOrder: item.displayOrder,
          unit: item.unit,
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
          id: 0,
          templateId: template.id,
          productName: item.productName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          displayOrder: item.displayOrder,
          unit: item.unit,
        );
        await txn.insert('template_items', itemModel.toInsert());
      }
    });
  }

  @override
  Future<void> deleteTemplate(int id) async {
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
    final existingTemplates = await getPredefinedTemplates();
    if (existingTemplates.isNotEmpty) return;

    await _createBTPTemplates();
    await _createITTemplates();
    await _createConsultingTemplates();
    await _createCommerceTemplates();
    await _createServiceTemplates();
  }

  // Helper pour créer un template prédéfini proprement
  Future<void> _createPredefinedTemplate(String name, String desc, String cat, List<TemplateItem> items, {int? validity, String? notes, String? terms}) async {
    final template = QuoteTemplate(
      id: 0,
      name: name,
      description: desc,
      category: cat,
      isCustom: false,
      createdAt: DateTime.now(),
      validityDays: validity,
      notes: notes,
      termsAndConditions: terms,
    );
    await createTemplate(template, items);
  }

  Future<void> _createBTPTemplates() async {
    await _createPredefinedTemplate(
      'Construction Maison Individuelle',
      'Devis complet pour la construction d\'une maison',
      'BTP',
      [
        const TemplateItem(id: 0, templateId: 0, productName: 'Gros œuvre', description: 'Fondations, murs porteurs', quantity: 1, unitPrice: 8500000, vatRate: 0.18, displayOrder: 1, unit: 'Forfait'),
        const TemplateItem(id: 0, templateId: 0, productName: 'Charpente', description: 'Charpente bois, tuiles', quantity: 1, unitPrice: 3200000, vatRate: 0.18, displayOrder: 2, unit: 'Forfait'),
      ],
      validity: 60,
    );
  }

  Future<void> _createITTemplates() async {
    await _createPredefinedTemplate(
      'Site Web Vitrine',
      'Création d\'un site web professionnel',
      'IT',
      [
        const TemplateItem(id: 0, templateId: 0, productName: 'Design UX/UI', description: 'Maquettes, charte graphique', quantity: 1, unitPrice: 850000, vatRate: 0.18, displayOrder: 1, unit: 'Service'),
        const TemplateItem(id: 0, templateId: 0, productName: 'Développement', description: 'HTML/CSS/JS responsive', quantity: 1, unitPrice: 1200000, vatRate: 0.18, displayOrder: 2, unit: 'Service'),
      ],
      validity: 45,
    );
  }

  Future<void> _createConsultingTemplates() async {
    await _createPredefinedTemplate(
      'Audit et Conseil Stratégique',
      'Mission d\'audit et recommandations',
      'Consulting',
      [
        const TemplateItem(id: 0, templateId: 0, productName: 'Audit initial', description: 'Analyse de l\'existant', quantity: 1, unitPrice: 1500000, vatRate: 0.18, displayOrder: 1, unit: 'Mission'),
      ],
      validity: 30,
    );
  }

  Future<void> _createCommerceTemplates() async {
    await _createPredefinedTemplate(
      'Boutique E-commerce',
      'Création d\'une boutique en ligne',
      'Commerce',
      [
        const TemplateItem(id: 0, templateId: 0, productName: 'Setup e-commerce', description: 'Configuration CMS', quantity: 1, unitPrice: 950000, vatRate: 0.18, displayOrder: 1, unit: 'Forfait'),
      ],
      validity: 45,
    );
  }

  Future<void> _createServiceTemplates() async {
    await _createPredefinedTemplate(
      'Formation Professionnelle',
      'Programme de formation sur mesure',
      'Service',
      [
        const TemplateItem(id: 0, templateId: 0, productName: 'Conception programme', description: 'Analyse besoins', quantity: 1, unitPrice: 650000, vatRate: 0.18, displayOrder: 1, unit: 'Forfait'),
      ],
      validity: 30,
    );
  }
}

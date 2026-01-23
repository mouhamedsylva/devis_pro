import '../entities/template.dart';

/// Repository abstrait pour la gestion des templates de devis.
abstract class TemplateRepository {
  /// Récupère tous les templates.
  Future<List<QuoteTemplate>> getAllTemplates();

  /// Récupère les templates par catégorie.
  Future<List<QuoteTemplate>> getTemplatesByCategory(String category);

  /// Récupère un template par son ID.
  Future<QuoteTemplate?> getTemplateById(int id);

  /// Récupère les templates prédéfinis (isCustom = false).
  Future<List<QuoteTemplate>> getPredefinedTemplates();

  /// Récupère les templates personnalisés (isCustom = true).
  Future<List<QuoteTemplate>> getCustomTemplates();

  /// Crée un nouveau template.
  Future<int> createTemplate(QuoteTemplate template, List<TemplateItem> items);

  /// Met à jour un template existant.
  Future<void> updateTemplate(QuoteTemplate template, List<TemplateItem> items);

  /// Supprime un template.
  Future<void> deleteTemplate(int id);

  /// Récupère tous les items d'un template.
  Future<List<TemplateItem>> getTemplateItems(int templateId);

  /// Initialise les templates prédéfinis (appelé au premier lancement).
  Future<void> initializePredefinedTemplates();
}

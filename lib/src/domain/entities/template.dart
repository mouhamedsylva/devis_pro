/// Entité Template - Modèle de devis prédéfini.
///
/// Permet de créer rapidement des devis basés sur des templates
/// prédéfinis ou personnalisés par secteur d'activité.
import 'package:equatable/equatable.dart';

class QuoteTemplate extends Equatable {
  const QuoteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isCustom,
    required this.createdAt,
    this.notes,
    this.validityDays,
    this.termsAndConditions,
  });

  final int id;
  final String name; // Ex: "Devis Construction Maison"
  final String description; // Description courte du template
  final String category; // BTP, IT, Consulting, Commerce, Service, Autre
  final bool isCustom; // false = prédéfini, true = créé par utilisateur
  final DateTime createdAt;
  final String? notes; // Notes par défaut pour ce type de devis
  final int? validityDays; // Durée de validité par défaut (ex: 30 jours)
  final String? termsAndConditions; // Conditions générales par défaut

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        isCustom,
        createdAt,
        notes,
        validityDays,
        termsAndConditions,
      ];
}

/// Item de template - Produit/service prédéfini dans un template.
class TemplateItem extends Equatable {
  const TemplateItem({
    required this.id,
    required this.templateId,
    required this.productName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.displayOrder,
  });

  final int id;
  final int templateId;
  final String productName;
  final String description;
  final int quantity;
  final double unitPrice;
  final double vatRate;
  final int displayOrder; // Ordre d'affichage

  double get total => quantity * unitPrice;

  @override
  List<Object?> get props => [
        id,
        templateId,
        productName,
        description,
        quantity,
        unitPrice,
        vatRate,
        displayOrder,
      ];
}

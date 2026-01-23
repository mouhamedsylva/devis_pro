import '../../domain/entities/template.dart';

/// Modèle de données pour Template avec conversion DB.
class QuoteTemplateModel extends QuoteTemplate {
  const QuoteTemplateModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.isCustom,
    required super.createdAt,
    super.notes,
    super.validityDays,
    super.termsAndConditions,
  });

  /// Crée un QuoteTemplateModel depuis une map de base de données.
  factory QuoteTemplateModel.fromMap(Map<String, dynamic> map) {
    return QuoteTemplateModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      isCustom: (map['isCustom'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      notes: map['notes'] as String?,
      validityDays: map['validityDays'] as int?,
      termsAndConditions: map['termsAndConditions'] as String?,
    );
  }

  /// Convertit le modèle en map pour l'insertion dans la DB.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'isCustom': isCustom ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'validityDays': validityDays,
      'termsAndConditions': termsAndConditions,
    };
  }

  /// Pour l'insertion (sans id auto-increment).
  Map<String, dynamic> toInsert() {
    final map = toMap();
    map.remove('id');
    return map;
  }
}

/// Modèle de données pour TemplateItem avec conversion DB.
class TemplateItemModel extends TemplateItem {
  const TemplateItemModel({
    required super.id,
    required super.templateId,
    required super.productName,
    required super.description,
    required super.quantity,
    required super.unitPrice,
    required super.vatRate,
    required super.displayOrder,
  });

  /// Crée un TemplateItemModel depuis une map de base de données.
  factory TemplateItemModel.fromMap(Map<String, dynamic> map) {
    return TemplateItemModel(
      id: map['id'] as int,
      templateId: map['templateId'] as int,
      productName: map['productName'] as String,
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      vatRate: (map['vatRate'] as num).toDouble(),
      displayOrder: map['displayOrder'] as int,
    );
  }

  /// Convertit le modèle en map pour l'insertion dans la DB.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'productName': productName,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
      'displayOrder': displayOrder,
    };
  }

  /// Pour l'insertion (sans id auto-increment).
  Map<String, dynamic> toInsert() {
    final map = toMap();
    map.remove('id');
    return map;
  }
}

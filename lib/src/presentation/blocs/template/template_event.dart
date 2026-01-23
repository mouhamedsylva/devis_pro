import 'package:equatable/equatable.dart';
import '../../../domain/entities/template.dart';

/// Événements pour le TemplateBloc.
sealed class TemplateEvent extends Equatable {
  const TemplateEvent();

  @override
  List<Object?> get props => [];
}

/// Charge tous les templates.
class TemplateLoadAll extends TemplateEvent {
  const TemplateLoadAll();
}

/// Charge les templates par catégorie.
class TemplateLoadByCategory extends TemplateEvent {
  const TemplateLoadByCategory(this.category);

  final String category;

  @override
  List<Object?> get props => [category];
}

/// Charge les templates prédéfinis.
class TemplateLoadPredefined extends TemplateEvent {
  const TemplateLoadPredefined();
}

/// Charge les templates personnalisés.
class TemplateLoadCustom extends TemplateEvent {
  const TemplateLoadCustom();
}

/// Charge un template spécifique avec ses items.
class TemplateLoadDetails extends TemplateEvent {
  const TemplateLoadDetails(this.templateId);

  final int templateId;

  @override
  List<Object?> get props => [templateId];
}

/// Crée un nouveau template personnalisé.
class TemplateCreate extends TemplateEvent {
  const TemplateCreate(this.template, this.items);

  final QuoteTemplate template;
  final List<TemplateItem> items;

  @override
  List<Object?> get props => [template, items];
}

/// Met à jour un template existant.
class TemplateUpdate extends TemplateEvent {
  const TemplateUpdate(this.template, this.items);

  final QuoteTemplate template;
  final List<TemplateItem> items;

  @override
  List<Object?> get props => [template, items];
}

/// Supprime un template.
class TemplateDelete extends TemplateEvent {
  const TemplateDelete(this.templateId);

  final int templateId;

  @override
  List<Object?> get props => [templateId];
}

/// Initialise les templates prédéfinis.
class TemplateInitializePredefined extends TemplateEvent {
  const TemplateInitializePredefined();
}

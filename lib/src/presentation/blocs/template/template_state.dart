import 'package:equatable/equatable.dart';
import '../../../domain/entities/template.dart';

/// États pour le TemplateBloc.
sealed class TemplateState extends Equatable {
  const TemplateState();

  @override
  List<Object?> get props => [];
}

/// État initial.
class TemplateInitial extends TemplateState {
  const TemplateInitial();
}

/// Chargement en cours.
class TemplateLoading extends TemplateState {
  const TemplateLoading();
}

/// Liste de templates chargée.
class TemplateListLoaded extends TemplateState {
  const TemplateListLoaded(this.templates);

  final List<QuoteTemplate> templates;

  @override
  List<Object?> get props => [templates];
}

/// Détails d'un template chargés (template + items).
class TemplateDetailsLoaded extends TemplateState {
  const TemplateDetailsLoaded(this.template, this.items);

  final QuoteTemplate template;
  final List<TemplateItem> items;

  @override
  List<Object?> get props => [template, items];
}

/// Template créé avec succès.
class TemplateCreated extends TemplateState {
  const TemplateCreated(this.templateId);

  final int templateId;

  @override
  List<Object?> get props => [templateId];
}

/// Template mis à jour avec succès.
class TemplateUpdated extends TemplateState {
  const TemplateUpdated();
}

/// Template supprimé avec succès.
class TemplateDeleted extends TemplateState {
  const TemplateDeleted();
}

/// Templates prédéfinis initialisés.
class TemplatePredefinedInitialized extends TemplateState {
  const TemplatePredefinedInitialized();
}

/// Erreur lors d'une opération.
class TemplateError extends TemplateState {
  const TemplateError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

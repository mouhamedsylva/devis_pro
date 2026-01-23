import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/template_repository.dart';
import 'template_event.dart';
import 'template_state.dart';

/// BLoC pour la gestion des templates de devis.
class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  TemplateBloc(this._templateRepository) : super(const TemplateInitial()) {
    on<TemplateLoadAll>(_onLoadAll);
    on<TemplateLoadByCategory>(_onLoadByCategory);
    on<TemplateLoadPredefined>(_onLoadPredefined);
    on<TemplateLoadCustom>(_onLoadCustom);
    on<TemplateLoadDetails>(_onLoadDetails);
    on<TemplateCreate>(_onCreate);
    on<TemplateUpdate>(_onUpdate);
    on<TemplateDelete>(_onDelete);
    on<TemplateInitializePredefined>(_onInitializePredefined);
  }

  final TemplateRepository _templateRepository;

  Future<void> _onLoadAll(
    TemplateLoadAll event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      final templates = await _templateRepository.getAllTemplates();
      emit(TemplateListLoaded(templates));
    } catch (e) {
      emit(TemplateError('Erreur lors du chargement des templates: $e'));
    }
  }

  Future<void> _onLoadByCategory(
    TemplateLoadByCategory event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      final templates = await _templateRepository.getTemplatesByCategory(event.category);
      emit(TemplateListLoaded(templates));
    } catch (e) {
      emit(TemplateError('Erreur lors du chargement des templates: $e'));
    }
  }

  Future<void> _onLoadPredefined(
    TemplateLoadPredefined event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      final templates = await _templateRepository.getPredefinedTemplates();
      emit(TemplateListLoaded(templates));
    } catch (e) {
      emit(TemplateError('Erreur lors du chargement des templates prédéfinis: $e'));
    }
  }

  Future<void> _onLoadCustom(
    TemplateLoadCustom event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      final templates = await _templateRepository.getCustomTemplates();
      emit(TemplateListLoaded(templates));
    } catch (e) {
      emit(TemplateError('Erreur lors du chargement des templates personnalisés: $e'));
    }
  }

  Future<void> _onLoadDetails(
    TemplateLoadDetails event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      final template = await _templateRepository.getTemplateById(event.templateId);
      if (template == null) {
        emit(const TemplateError('Template introuvable'));
        return;
      }
      final items = await _templateRepository.getTemplateItems(event.templateId);
      emit(TemplateDetailsLoaded(template, items));
    } catch (e) {
      emit(TemplateError('Erreur lors du chargement du template: $e'));
    }
  }

  Future<void> _onCreate(
    TemplateCreate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      final templateId = await _templateRepository.createTemplate(
        event.template,
        event.items,
      );
      emit(TemplateCreated(templateId));
    } catch (e) {
      emit(TemplateError('Erreur lors de la création du template: $e'));
    }
  }

  Future<void> _onUpdate(
    TemplateUpdate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      await _templateRepository.updateTemplate(
        event.template,
        event.items,
      );
      emit(const TemplateUpdated());
    } catch (e) {
      emit(TemplateError('Erreur lors de la mise à jour du template: $e'));
    }
  }

  Future<void> _onDelete(
    TemplateDelete event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      await _templateRepository.deleteTemplate(event.templateId);
      emit(const TemplateDeleted());
    } catch (e) {
      emit(TemplateError('Erreur lors de la suppression du template: $e'));
    }
  }

  Future<void> _onInitializePredefined(
    TemplateInitializePredefined event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(const TemplateLoading());
      await _templateRepository.initializePredefinedTemplates();
      emit(const TemplatePredefinedInitialized());
    } catch (e) {
      emit(TemplateError('Erreur lors de l\'initialisation des templates: $e'));
    }
  }
}

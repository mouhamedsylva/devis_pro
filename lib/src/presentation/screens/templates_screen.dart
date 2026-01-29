import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/template.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../blocs/template/template_state.dart';
import 'template_editor_screen.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/app_scaffold.dart';

/// Écran de gestion des templates de devis (Uniquement Personnalisés).
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    'Mes Modèles',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTemplates() {
    // On ne charge que les templates personnalisés de l'utilisateur
    context.read<TemplateBloc>().add(const TemplateLoadCustom());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mes Modèles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: BlocConsumer<TemplateBloc, TemplateState>(
        listener: (context, state) {
          if (state is TemplateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is TemplateCreated) {
            _loadTemplates();
          } else if (state is TemplateDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Modèle supprimé'),
                backgroundColor: Colors.green,
              ),
            );
            _loadTemplates();
          }
        },
        builder: (context, state) {
          if (state is TemplateLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TemplateListLoaded) {
            final customTemplates = state.templates.where((t) => t.isCustom).toList();
            if (customTemplates.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTemplatesList(customTemplates);
          }

          return const Center(child: Text('Chargement...'));
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFDB913), Color(0xFFFFD700)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateEditorScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Nouveau modèle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Aucun modèle personnalisé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez vos propres modèles pour générer\ndes devis plus rapidement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(List<QuoteTemplate> templates) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildTemplateCard(templates[index]),
    );
  }

  Widget _buildTemplateCard(QuoteTemplate template) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(template.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.yellow),
              onPressed: () => _openEditor(template),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteTemplate(template),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTemplate(QuoteTemplate template) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Supprimer le modèle',
        content: 'Voulez-vous vraiment supprimer "${template.name}" ?',
        confirmText: 'Supprimer',
        confirmColor: Colors.red,
        onConfirm: () {
          Navigator.pop(context);
          context.read<TemplateBloc>().add(TemplateDelete(template.id));
        },
      ),
    );
  }

  Future<void> _openEditor(QuoteTemplate template) async {
    // Logique d'ouverture de l'éditeur existante...
    context.read<TemplateBloc>().add(TemplateLoadDetails(template.id));
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(initialTemplate: template),
      ),
    );
    if (result == true) _loadTemplates();
  }
}

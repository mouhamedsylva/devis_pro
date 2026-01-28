import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/template.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../blocs/template/template_state.dart';
import 'template_editor_screen.dart';
import '../widgets/confirmation_dialog.dart';

/// Écran de gestion des templates de devis.
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Tous';

  final List<String> _categories = [
    'Tous',
    'BTP',
    'IT',
    'Consulting',
    'Commerce',
    'Service',
    'Personnalisés',
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
    if (_selectedCategory == 'Tous') {
      context.read<TemplateBloc>().add(const TemplateLoadAll());
    } else if (_selectedCategory == 'Personnalisés') {
      context.read<TemplateBloc>().add(const TemplateLoadCustom());
    } else {
      context.read<TemplateBloc>().add(TemplateLoadByCategory(_selectedCategory));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Modèles de Devis',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.yellow,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.yellow,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: _categories.map((category) {
                return Tab(
                  text: category,
                );
              }).toList(),
              onTap: (index) {
                setState(() {
                  _selectedCategory = _categories[index];
                });
                _loadTemplates();
              },
            ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Template créé avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            _loadTemplates();
          } else if (state is TemplateDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Template supprimé avec succès'),
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
            if (state.templates.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTemplatesList(state.templates);
          }

          return const Center(child: Text('Chargement...'));
        },
      ),
      floatingActionButton: _selectedCategory == 'Personnalisés' || _selectedCategory == 'Tous'
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFDB913),
                    Color(0xFFFFD700),
                  ],
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
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.yellow,
                  AppColors.yellow.withOpacity(0.7),
                ],
              ),
            ),
            child: const Icon(
              Icons.description,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun modèle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory == 'Personnalisés'
                ? 'Créez votre premier modèle personnalisé'
                : 'Aucun modèle dans cette catégorie',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedCategory == 'Personnalisés' || _selectedCategory == 'Tous') ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplateEditorScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un modèle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesList(List<QuoteTemplate> templates) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(QuoteTemplate template) {
    return Dismissible(
      key: ValueKey('template_${template.id}'),
      direction: template.isCustom ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Supprimer le modèle ?',
            content: 'Voulez-vous vraiment supprimer le modèle "${template.name}" ? Cette action est irréversible.',
            confirmText: 'Supprimer',
            confirmColor: Colors.red,
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        );
      },
      onDismissed: (direction) {
        context.read<TemplateBloc>().add(TemplateDelete(template.id));
      },
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showTemplateDetails(template);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(template.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getCategoryColor(template.category),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        template.category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(template.category),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      template.isCustom ? Icons.person : Icons.star,
                      size: 16,
                      color: template.isCustom ? Colors.blue : AppColors.yellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      template.isCustom ? 'Personnalisé' : 'Prédéfini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (template.validityDays != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${template.validityDays} jours',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      color: Colors.blue,
                      tooltip: 'Voir détails',
                      onPressed: () => _showTemplateDetails(template),
                    ),
                    if (template.isCustom) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.yellow,
                        tooltip: 'Modifier',
                        onPressed: () => _openEditor(template),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: 'Supprimer',
                        onPressed: () => _confirmDeleteTemplate(template),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'BTP':
        return Colors.orange;
      case 'IT':
        return Colors.blue;
      case 'Consulting':
        return Colors.purple;
      case 'Commerce':
        return Colors.green;
      case 'Service':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showTemplateDetails(QuoteTemplate template) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        // Déclencher le chargement juste avant de construire le modal
        context.read<TemplateBloc>().add(TemplateLoadDetails(template.id));
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: BlocConsumer<TemplateBloc, TemplateState>(
                listenWhen: (previous, current) => current is TemplateError,
                listener: (context, state) {
                  if (state is TemplateError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                buildWhen: (previous, current) {
                  // Ne reconstruire que pour les états pertinents pour CETTE modale
                  if (current is TemplateDetailsLoaded) {
                    return current.template.id == template.id;
                  }
                  return current is TemplateLoading || current is TemplateError;
                },
                builder: (context, state) {
                  if (state is TemplateDetailsLoaded) {
                    // Si on arrive ici, on sait que c'est le bon template grâce au `buildWhen`
                    return _buildTemplateDetailsContent(
                      state.template,
                      state.items,
                      scrollController,
                    );
                  }

                  if (state is TemplateError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                context.read<TemplateBloc>().add(
                                      TemplateLoadDetails(template.id),
                                    );
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Pour tous les autres états (initial, loading)
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        _loadTemplates();
      }
    });
  }

  Widget _buildTemplateDetailsContent(
    QuoteTemplate template,
    List<TemplateItem> items,
    ScrollController scrollController,
  ) {
    double totalHT = 0;
    for (final item in items) {
      totalHT += item.total;
    }
    final totalVAT = items.isEmpty ? 0.0 : totalHT * items.first.vatRate;
    final totalTTC = totalHT + totalVAT;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openEditor(template);
                },
                icon: Icon(template.isCustom ? Icons.edit : Icons.auto_fix_high),
                label: Text(template.isCustom ? 'Modifier' : 'Personnaliser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _useTemplate(template);
                },
                icon: const Icon(Icons.add),
                label: const Text('Utiliser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              if (template.notes != null) ...[
                _buildInfoSection('Notes', template.notes!),
                const SizedBox(height: 16),
              ],
              if (template.termsAndConditions != null) ...[
                _buildInfoSection('Conditions', template.termsAndConditions!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Articles / Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _buildItemCard(item)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Total HT', totalHT),
                    const SizedBox(height: 8),
                    _buildTotalRow('TVA', totalVAT),
                    const Divider(height: 24),
                    _buildTotalRow('Total TTC', totalTTC, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(TemplateItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qté: ${item.quantity}  ×  ${item.unitPrice.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${item.total.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.yellow : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteTemplate(QuoteTemplate template) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Supprimer le modèle',
        content: 'Êtes-vous sûr de vouloir supprimer le modèle "${template.name}" ?\n\nCette action est irréversible.',
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
    context.read<TemplateBloc>().add(TemplateLoadDetails(template.id));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final state = await context.read<TemplateBloc>().stream.firstWhere(
            (s) => s is TemplateDetailsLoaded || s is TemplateError,
          );

      if (!mounted) return;
      Navigator.pop(context);

      if (state is TemplateDetailsLoaded) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateEditorScreen(
              initialTemplate: template.isCustom ? state.template : null,
              initialItems: state.items,
            ),
          ),
        );
        if (result == true) {
          _loadTemplates();
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _useTemplate(QuoteTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modèle prêt. Allez dans "Nouveau Devis" pour l\'utiliser')),
    );
  }
}

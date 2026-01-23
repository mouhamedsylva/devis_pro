import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/template.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../blocs/template/template_state.dart';

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
      floatingActionButton: _selectedCategory == 'Personnalisés'
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Ouvrir l'écran de création de template
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Création de template personnalisé - À implémenter'),
                  ),
                );
              },
              backgroundColor: AppColors.yellow,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nouveau template',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
          // Logo DevisPro
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
            'Aucun template',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCategory == 'Personnalisés'
                ? 'Créez votre premier template personnalisé'
                : 'Aucun template dans cette catégorie',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedCategory == 'Personnalisés') ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Ouvrir l'écran de création de template
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Création de template personnalisé - À implémenter'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un template'),
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
    return Card(
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
              // Header: Nom + Badge catégorie + Actions
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
                  // Badge catégorie
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
              // Informations complémentaires
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
                  // Boutons d'action
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    color: Colors.blue,
                    tooltip: 'Voir détails',
                    onPressed: () => _showTemplateDetails(template),
                  ),
                  if (template.isCustom) ...[
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

  void _showTemplateDetails(QuoteTemplate template) {
    context.read<TemplateBloc>().add(TemplateLoadDetails(template.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              child: BlocBuilder<TemplateBloc, TemplateState>(
                builder: (context, state) {
                  if (state is TemplateLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TemplateDetailsLoaded) {
                    return _buildTemplateDetailsContent(
                      state.template,
                      state.items,
                      scrollController,
                    );
                  }

                  return const Center(child: Text('Erreur de chargement'));
                },
              ),
            );
          },
        );
      },
    ).then((_) {
      // Recharger la liste après fermeture du bottom sheet
      _loadTemplates();
    });
  }

  Widget _buildTemplateDetailsContent(
    QuoteTemplate template,
    List<TemplateItem> items,
    ScrollController scrollController,
  ) {
    // Calcul du total
    double totalHT = 0;
    for (final item in items) {
      totalHT += item.total;
    }
    final totalVAT = items.isEmpty ? 0.0 : totalHT * items.first.vatRate;
    final totalTTC = totalHT + totalVAT;

    return Column(
      children: [
        // Handle de drag
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
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
                  // TODO: Créer un devis à partir de ce template
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Création de devis à partir du template - À implémenter'),
                    ),
                  );
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
        // Liste des items
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Informations du template
              if (template.notes != null) ...[
                _buildInfoSection('Notes', template.notes!),
                const SizedBox(height: 16),
              ],
              if (template.termsAndConditions != null) ...[
                _buildInfoSection('Conditions', template.termsAndConditions!),
                const SizedBox(height: 16),
              ],
              // Items
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
              // Total
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
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le template'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le template "${template.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TemplateBloc>().add(TemplateDelete(template.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

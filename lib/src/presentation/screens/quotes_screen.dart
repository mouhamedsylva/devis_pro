/// QuotesScreen – liste des devis + actions (PDF / statut) + création.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/repositories/quote_repository.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../widgets/quote_preview_dialog.dart';
import 'quote_editor_screen.dart';
import 'templates_screen.dart';
import '../services/quote_pdf_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/app_scaffold.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _pdf = QuotePdfService();
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all'; // all, draft, sent, accepted
  String _currentSort = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  String _currency = 'FCFA';

  @override
  void initState() {
    super.initState();
    context.read<QuoteBloc>().add(const QuoteListRequested());
    _loadCurrency();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadCurrency() async {
    final companyRepo = context.read<CompanyRepository>();
    final company = await companyRepo.getCompany();
    if (mounted) {
      setState(() {
        _currency = company.currency;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un devis...',
            border: InputBorder.none,
            filled: false,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        actions: [
          // IconButton(
          //   tooltip: 'Modèles',
          //   icon: const Icon(Icons.note_add_rounded),
          //   onPressed: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(builder: (_) => const TemplatesScreen()),
          //     );
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSortOptions(context);
            },
          ),
        ],
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: BlocBuilder<QuoteBloc, QuoteState>(
        builder: (context, state) {
          final quotes = state.quotes ?? const [];
          if (quotes.isEmpty && state.status != QuoteStatus.loading) {
            return const SizedBox.shrink();
          }
          return Container(
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
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuoteEditorScreen()),
                );
                if (!context.mounted) return;
                context.read<QuoteBloc>().add(const QuoteListRequested());
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Nouveau devis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<QuoteBloc, QuoteState>(
              listenWhen: (p, c) => c.status == QuoteStatus.failure && c.message != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message!),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              builder: (context, state) {
                if (state.status == QuoteStatus.loading) {
                  return _buildLoadingSkeleton();
                }
                
                var quotes = state.quotes ?? const [];
                
                // Filtrer par recherche
                final searchTerm = _searchController.text.toLowerCase();
                if (searchTerm.isNotEmpty) {
                  quotes = quotes.where((q) => 
                    q.quoteNumber.toLowerCase().contains(searchTerm) ||
                    (q.clientName?.toLowerCase().contains(searchTerm) ?? false)
                  ).toList();
                }
                
                // Filtrer par statut
                if (_currentFilter != 'all') {
                  final statusFilter = switch (_currentFilter) {
                    'draft' => 'Brouillon',
                    'sent' => 'Envoyé',
                    'accepted' => 'Accepté',
                    _ => '',
                  };
                  quotes = quotes.where((q) => q.status == statusFilter).toList();
                }
                
                // Appliquer le tri
                quotes = _applySorting(quotes);
                
                if (quotes.isEmpty) {
                  return _buildEmptyState(context, searchTerm);
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: quotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final q = quotes[i];
                    return _buildQuoteCard(context, q);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, dynamic quote) {
    final statusColor = _getStatusColor(quote.status);
    final statusIcon = _getStatusIcon(quote.status);
    final clientName = quote.clientName ?? 'Client non spécifié';
    final isDraft = quote.status == 'Brouillon';
    
    return Dismissible(
      key: ValueKey('quote_${quote.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.6},
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Supprimer le devis ?',
            content: 'Voulez-vous vraiment supprimer le devis ${quote.quoteNumber} ? Cette action est irréversible.',
            confirmText: 'Supprimer',
            confirmColor: Colors.red,
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        );
      },
      onDismissed: (direction) {
        context.read<QuoteBloc>().add(QuoteDeleteRequested(quote.id));
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQuotePreview(context, quote),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Numéro du devis
                      Text(
                        quote.quoteNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      // Statut (Affiché uniquement si pas Brouillon)
                      if (!isDraft)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                quote.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Icône Client
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_rounded, color: AppColors.yellow, size: 20),
                      ),
                      const SizedBox(width: 12),
                      // Infos Client & Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D2D2D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.dateShort(quote.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Montant
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.moneyCfa(quote.totalTTC, currencyLabel: _currency),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.yellow,
                            ),
                          ),
                          const Text(
                            'Montant TTC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuotePreview(BuildContext context, dynamic quote) async {
    final companyRepo = context.read<CompanyRepository>();
    final clientRepo = context.read<ClientRepository>();
    final quoteRepo = context.read<QuoteRepository>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final company = await companyRepo.getCompany();
      Client? client;
      if (quote.clientId != null) {
        client = await clientRepo.findById(quote.clientId);
      }
      final items = await quoteRepo.listItems(quote.id);

      if (!context.mounted) return;
      Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (_) => QuotePreviewDialog(
          quote: quote,
          items: items,
          company: company,
          client: client,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Brouillon' => const Color(0xFFFF9800),
      'Envoyé' => const Color(0xFF2196F3),
      'Accepté' => const Color(0xFF4CAF50),
      _ => Colors.grey,
    };
  }

  IconData _getStatusIcon(String status) {
    return switch (status) {
      'Brouillon' => Icons.edit_note_rounded,
      'Envoyé' => Icons.send_rounded,
      'Accepté' => Icons.check_circle_rounded,
      _ => Icons.description_rounded,
    };
  }

  void _showFilterSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  title: const Text('Filtrer par statut'),
                  tileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                RadioListTile<String>(
                  title: const Text('Tous les devis'),
                  value: 'all',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Brouillons'),
                  value: 'draft',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Envoyés'),
                  value: 'sent',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Acceptés'),
                  value: 'accepted',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Trier par'),
                  tileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                RadioListTile<String>(
                  title: const Text('Date (récent → ancien)'),
                  value: 'date_desc',
                  groupValue: _currentSort,
                  onChanged: (value) {
                    setState(() {
                      _currentSort = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Date (ancien → récent)'),
                  value: 'date_asc',
                  groupValue: _currentSort,
                  onChanged: (value) {
                    setState(() {
                      _currentSort = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Montant (croissant)'),
                  value: 'amount_asc',
                  groupValue: _currentSort,
                  onChanged: (value) {
                    setState(() {
                      _currentSort = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Montant (décroissant)'),
                  value: 'amount_desc',
                  groupValue: _currentSort,
                  onChanged: (value) {
                    setState(() {
                      _currentSort = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Numéro de devis'),
                  value: 'number',
                  groupValue: _currentSort,
                  onChanged: (value) {
                    setState(() {
                      _currentSort = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<T> _applySorting<T>(List<T> quotes) {
    final sorted = List<T>.from(quotes);
    switch (_currentSort) {
      case 'date_desc':
        sorted.sort((a, b) => (b as dynamic).date.compareTo((a as dynamic).date));
        break;
      case 'date_asc':
        sorted.sort((a, b) => (a as dynamic).date.compareTo((b as dynamic).date));
        break;
      case 'amount_desc':
        sorted.sort((a, b) => (b as dynamic).totalTTC.compareTo((a as dynamic).totalTTC));
        break;
      case 'amount_asc':
        sorted.sort((a, b) => (a as dynamic).totalTTC.compareTo((b as dynamic).totalTTC));
        break;
      case 'number':
        sorted.sort((a, b) => (a as dynamic).quoteNumber.compareTo((b as dynamic).quoteNumber));
        break;
    }
    return sorted;
  }

  Widget _buildEmptyState(BuildContext context, String searchTerm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFDB913),
                    Color(0xFFFFD700),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.description,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              searchTerm.isEmpty 
                  ? (_currentFilter != 'all' 
                      ? 'Aucun devis avec ce statut.' 
                      : 'Aucun devis enregistré.')
                  : 'Aucun devis trouvé pour "$searchTerm".',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (searchTerm.isEmpty && _currentFilter == 'all')
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuoteEditorScreen()),
                  );
                  if (!context.mounted) return;
                  context.read<QuoteBloc>().add(const QuoteListRequested());
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer un devis'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

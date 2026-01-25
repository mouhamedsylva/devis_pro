/// QuotesScreen – liste des devis + actions (PDF / statut) + création.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/template.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/repositories/quote_repository.dart';
import '../../domain/repositories/template_repository.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../widgets/quote_preview_dialog.dart';
import '../../core/services/connectivity_service.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/connectivity_wrapper.dart';
import 'quote_editor_screen.dart';
import 'templates_screen.dart';
import '../services/quote_pdf_service.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _pdf = QuotePdfService();
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all'; // all, draft, sent, accepted, sync
  String _currentSort = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  
  // Connectivity
  bool _isOnline = true;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    context.read<QuoteBloc>().add(const QuoteListRequested());
    _searchController.addListener(() {
      setState(() {});
    });
    
    // Monitoring connectivité
    _connectivityService.startMonitoring();
    _connectivityService.connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
    _connectivityService.checkConnection().then((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {}); // Rafraîchir la liste filtrée
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Modèles',
            icon: const Icon(Icons.note_add_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSortOptions(context);
            },
          ),
          // Sync button (only if online and there are pending quotes - logic simplified here)
          if (_isOnline)
            BlocBuilder<QuoteBloc, QuoteState>(
              builder: (context, state) {
                final hasPending = state.quotes?.any((q) => q.pendingSync) ?? false;
                if (!hasPending) return const SizedBox.shrink();
                
                return IconButton(
                  tooltip: 'Synchroniser maintenant',
                  icon: const Icon(Icons.sync, color: AppColors.yellow),
                  onPressed: () {
                    context.read<QuoteBloc>().add(const QuoteSyncPendingRequested());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Synchronisation lancée...')),
                    );
                  },
                );
              },
            ),
        ],
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButton: BlocBuilder<QuoteBloc, QuoteState>(
        builder: (context, state) {
          final quotes = state.quotes ?? const [];
          // Masquer le FAB quand il n'y a pas de devis (même pendant le chargement)
          if (quotes.isEmpty) {
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
                
                // Filtrer par recherche (numéro de devis)
                final searchTerm = _searchController.text.toLowerCase();
                if (searchTerm.isNotEmpty) {
                  quotes = quotes.where((q) => 
                    q.quoteNumber.toLowerCase().contains(searchTerm)
                  ).toList();
                }
                
                // Filtrer par statut
                if (_currentFilter != 'all') {
                  if (_currentFilter == 'sync') {
                    quotes = quotes.where((q) => q.pendingSync).toList();
                  } else {
                    final statusFilter = switch (_currentFilter) {
                      'draft' => 'Brouillon',
                      'sent' => 'Envoyé',
                      'accepted' => 'Accepté',
                      _ => '',
                    };
                    quotes = quotes.where((q) => q.status == statusFilter).toList();
                  }
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                // Icône + Info principale
                Expanded(
                  child: Row(
                    children: [
                      // Icône
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.yellow, AppColors.yellow.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Numéro + Date
                            Text(
                              quote.quoteNumber,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (quote.pendingSync) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.cloud_off, size: 12, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    'En attente de sync',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 2),
                            // Date
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.dateShort(quote.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Client
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    clientName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Montant + Statut
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Montant
                    Text(
                      Formatters.moneyCfa(quote.totalTTC, currencyLabel: ''),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badge statut compact
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            quote.status,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1.0,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
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

    // Afficher un loader pendant le chargement des données
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
      Navigator.pop(context); // Fermer le loader

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
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildStatusMenu(BuildContext context, dynamic quote) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        if (v == 'draft' || v == 'sent' || v == 'accepted') {
          final status = switch (v) {
            'draft' => 'Brouillon',
            'sent' => 'Envoyé',
            _ => 'Accepté',
          };
          context.read<QuoteBloc>().add(
            QuoteStatusUpdated(quoteId: quote.id, status: status),
          );
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 45),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.yellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.yellow.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: AppColors.yellow,
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'draft',
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFFFF9800)),
              SizedBox(width: 12),
              Text('Brouillon'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sent',
          child: Row(
            children: [
              Icon(Icons.send_rounded, size: 20, color: Color(0xFF2196F3)),
              SizedBox(width: 12),
              Text('Envoyé'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'accepted',
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF4CAF50)),
              SizedBox(width: 12),
              Text('Accepté'),
            ],
          ),
        ),
      ],
    );
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
                // Section Filtrer
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
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('Non synchronisés'),
                      const SizedBox(width: 8),
                      Icon(Icons.cloud_off, size: 16, color: Colors.blue),
                    ],
                  ),
                  value: 'sync',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    setState(() {
                      _currentFilter = value!;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                  },
                ),
                
                // Section Trier
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
            // Logo DEVISPRO
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

  Future<void> _exportPdf(BuildContext context, int quoteId, int? clientId) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion internet requise pour le partage PDF (images, etc)'),
          backgroundColor: Colors.orange,
        ),
      );
      // On continue quand même car la génération est locale, mais ça prévient l'utilisateur
      // Si on veut bloquer : return;
    }

    final companyRepo = context.read<CompanyRepository>();
    final clientRepo = context.read<ClientRepository>();
    final quoteRepo = context.read<QuoteRepository>();

    final company = await companyRepo.getCompany();
    Client? client;
    if (clientId != null) {
      client = await clientRepo.findById(clientId);
    }

    final items = await quoteRepo.listItems(quoteId);
    final quotes = await quoteRepo.list();
    final quote = quotes.firstWhere((q) => q.id == quoteId);

    final bytes = await _pdf.buildPdf(company: company, client: client, quote: quote, items: items);
    final filename = '${quote.quoteNumber}.pdf';
    await _pdf.share(pdfBytes: bytes, filename: filename);
  }

  Future<void> _shareToWhatsApp(BuildContext context, int quoteId, int? clientId) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion internet requise pour WhatsApp'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final companyRepo = context.read<CompanyRepository>();
    final clientRepo = context.read<ClientRepository>();
    final quoteRepo = context.read<QuoteRepository>();

    final company = await companyRepo.getCompany();
    Client? client;
    String? clientName;
    
    if (clientId != null) {
      client = await clientRepo.findById(clientId);
      clientName = client?.name;
    } else {
      // Utiliser clientName du quote si disponible
      final quotes = await quoteRepo.list();
      final quote = quotes.firstWhere((q) => q.id == quoteId);
      clientName = quote.clientName;
    }

    final items = await quoteRepo.listItems(quoteId);
    final quotes = await quoteRepo.list();
    final quote = quotes.firstWhere((q) => q.id == quoteId);

    final bytes = await _pdf.buildPdf(company: company, client: client, quote: quote, items: items);
    final filename = '${quote.quoteNumber}.pdf';
    
    // Partager via WhatsApp avec le nom du client
    await _pdf.shareToWhatsApp(
      pdfBytes: bytes,
      filename: filename,
      clientName: clientName,
    );
  }

  Future<void> _saveAsTemplate(BuildContext context, int quoteId) async {
    // Afficher un dialogue pour demander les informations du template
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'BTP';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.bookmark_add, color: AppColors.yellow),
                  const SizedBox(width: 12),
                  const Text('Créer un modèle'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sauvegarder ce devis comme modèle réutilisable',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du modèle *',
                        hintText: 'Ex: Construction Villa',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Ex: Devis complet pour construction',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BTP', child: Text('BTP')),
                        DropdownMenuItem(value: 'IT', child: Text('IT')),
                        DropdownMenuItem(value: 'Consulting', child: Text('Consulting')),
                        DropdownMenuItem(value: 'Commerce', child: Text('Commerce')),
                        DropdownMenuItem(value: 'Service', child: Text('Service')),
                        DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir tous les champs'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Créer le modèle'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    // Charger les données du devis
    final quoteRepo = context.read<QuoteRepository>();
    final quotes = await quoteRepo.list();
    final quote = quotes.firstWhere((q) => q.id == quoteId);
    final items = await quoteRepo.listItems(quoteId);

    if (!context.mounted) return;

    // Créer le template
    final template = QuoteTemplate(
      id: 0,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory,
      isCustom: true,
      createdAt: DateTime.now(),
    );

    final templateItems = items
        .map((item) => TemplateItem(
              id: 0,
              templateId: 0,
              productName: item.productName,
              description: item.productName,
              quantity: item.quantity.toInt(),
              unitPrice: item.unitPrice,
              vatRate: item.vatRate,
              displayOrder: items.indexOf(item) + 1,
            ))
        .toList();

    // Sauvegarder le template via le BLoC
    if (context.mounted) {
      context.read<TemplateBloc>().add(TemplateCreate(template, templateItems));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modèle "${template.name}" créé avec succès'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              );
            },
          ),
        ),
      );
    }
  }
}


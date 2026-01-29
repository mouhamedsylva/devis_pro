/// QuotesScreen – liste des devis + actions (PDF / statut) + création.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/quote.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/repositories/quote_repository.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../widgets/quote_preview_dialog.dart';
import 'quote_editor_screen.dart';
import '../services/quote_pdf_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/app_scaffold.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all';
  String _currentSort = 'date_desc';
  String _currency = 'FCFA';

  @override
  void initState() {
    super.initState();
    context.read<QuoteBloc>().add(const QuoteListRequested());
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final companyRepo = context.read<CompanyRepository>();
    final company = await companyRepo.getCompany();
    if (mounted) setState(() => _currency = company.currency);
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
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Rechercher un devis...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSortOptions(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuoteEditorScreen()),
          );
          if (!mounted) return;
          context.read<QuoteBloc>().add(const QuoteListRequested());
        },
        backgroundColor: AppColors.yellow,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau devis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<QuoteBloc, QuoteState>(
        builder: (context, state) {
          if (state.status == QuoteStatus.loading) return const Center(child: CircularProgressIndicator());

          var quotes = state.quotes ?? const [];

          // Filtres
          final search = _searchController.text.toLowerCase();
          if (search.isNotEmpty) {
            quotes = quotes.where((q) => q.quoteNumber.toLowerCase().contains(search) || (q.clientName?.toLowerCase().contains(search) ?? false)).toList();
          }
          if (_currentFilter != 'all') {
            final status = _currentFilter == 'draft' ? 'Brouillon' : 'Envoyé';
            quotes = quotes.where((q) => q.status == status).toList();
          }

          if (quotes.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _buildQuoteCard(context, quotes[i]),
          );
        },
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Quote quote) {
    final bool isSent = quote.status == 'Envoyé';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openQuote(quote),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(quote.quoteNumber, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                    _buildStatusBadge(quote.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quote.clientName ?? 'Client inconnu',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Formatters.moneyCfa(quote.totalTTC),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.yellow),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(Formatters.dateShort(quote.date), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const Spacer(),
                    Icon(isSent ? Icons.visibility : Icons.edit, size: 16, color: isSent ? Colors.blue : Colors.grey),
                    const SizedBox(width: 4),
                    Text(isSent ? 'Voir' : 'Modifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSent ? Colors.blue : Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isSent = status == 'Envoyé';
    final Color color = isSent ? Colors.blue : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSent ? Icons.send : Icons.edit_note, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _openQuote(Quote quote) async {
    final quoteRepo = context.read<QuoteRepository>();
    final items = await quoteRepo.listItems(quote.id);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuoteEditorScreen(quote: quote, initialItems: items),
      ),
    );

    if (mounted) context.read<QuoteBloc>().add(const QuoteListRequested());
  }

  Widget _buildEmptyState() => Center(child: Text('Aucun devis trouvé', style: TextStyle(color: Colors.grey[600])));

  void _showFilterSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Tous les devis'), onTap: () { setState(() => _currentFilter = 'all'); Navigator.pop(context); }),
          ListTile(title: const Text('Brouillons'), onTap: () { setState(() => _currentFilter = 'draft'); Navigator.pop(context); }),
          ListTile(title: const Text('Envoyés'), onTap: () { setState(() => _currentFilter = 'sent'); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

/// QuotesScreen – liste des devis + actions (PDF / statut) + création.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/formatters.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/repositories/quote_repository.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../services/quote_pdf_service.dart';
import 'quote_editor_screen.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _pdf = QuotePdfService();

  @override
  void initState() {
    super.initState();
    context.read<QuoteBloc>().add(const QuoteListRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devis')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuoteEditorScreen()));
          if (!context.mounted) return;
          context.read<QuoteBloc>().add(const QuoteListRequested());
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: BlocConsumer<QuoteBloc, QuoteState>(
        listenWhen: (p, c) => c.status == QuoteStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          if (state.status == QuoteStatus.loading) return const Center(child: CircularProgressIndicator());
          final quotes = state.quotes ?? const [];
          if (quotes.isEmpty) return const Center(child: Text('Aucun devis. Créez votre premier devis.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: quotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final q = quotes[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(q.quoteNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${Formatters.dateShort(q.date)} • ${q.status}\nTTC: ${q.totalTTC.toStringAsFixed(0)}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'pdf') {
                        await _exportPdf(context, q.id, q.clientId);
                      } else if (v == 'draft' || v == 'sent' || v == 'accepted') {
                        final status = switch (v) {
                          'draft' => 'Brouillon',
                          'sent' => 'Envoyé',
                          _ => 'Accepté',
                        };
                        context.read<QuoteBloc>().add(QuoteStatusUpdated(quoteId: q.id, status: status));
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'pdf', child: Text('Exporter PDF / Partager')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'draft', child: Text('Statut: Brouillon')),
                      PopupMenuItem(value: 'sent', child: Text('Statut: Envoyé')),
                      PopupMenuItem(value: 'accepted', child: Text('Statut: Accepté')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, int quoteId, int clientId) async {
    final companyRepo = context.read<CompanyRepository>();
    final clientRepo = context.read<ClientRepository>();
    final quoteRepo = context.read<QuoteRepository>();

    final company = await companyRepo.getCompany();
    final client = await clientRepo.findById(clientId);
    if (client == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client introuvable')));
      return;
    }

    final items = await quoteRepo.listItems(quoteId);
    final quotes = await quoteRepo.list();
    final quote = quotes.firstWhere((q) => q.id == quoteId);

    final bytes = await _pdf.buildPdf(company: company, client: client, quote: quote, items: items);
    final filename = '${quote.quoteNumber}.pdf';
    await _pdf.share(pdfBytes: bytes, filename: filename);
  }
}


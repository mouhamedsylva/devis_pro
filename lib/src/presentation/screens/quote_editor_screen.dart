/// QuoteEditorScreen – création d'un devis (sélection client + lignes).
///
/// MVP: on choisit un client + on ajoute des produits (quantité).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/quote_repository.dart';
import '../blocs/quotes/quote_bloc.dart';

class QuoteEditorScreen extends StatefulWidget {
  const QuoteEditorScreen({super.key});

  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  int? _clientId;
  final List<_Line> _lines = [];

  bool _loading = true;
  List<Client> _clients = const [];
  List<Product> _products = const [];

  @override
  void initState() {
    super.initState();
    _loadPickers();
  }

  Future<void> _loadPickers() async {
    final clientRepo = context.read<ClientRepository>();
    final productRepo = context.read<ProductRepository>();
    final clients = await clientRepo.list();
    final products = await productRepo.list();
    if (!mounted) return;
    setState(() {
      _clients = clients;
      _products = products;
      _clientId = clients.isNotEmpty ? clients.first.id : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalHT = _lines.fold<double>(0, (sum, l) => sum + l.unitPrice * l.quantity);
    final totalVAT = _lines.fold<double>(0, (sum, l) => sum + (l.unitPrice * l.quantity * l.vatRate));
    final totalTTC = totalHT + totalVAT;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau devis')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_clients.isEmpty) const Text('Ajoutez d’abord un client.'),
                  if (_products.isEmpty) const Text('Ajoutez d’abord un produit/service.'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_clientId),
                    initialValue: _clientId,
                    decoration: const InputDecoration(labelText: 'Client'),
                    items: _clients
                        .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                        .toList(growable: false),
                    onChanged: (v) => setState(() => _clientId = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _products.isEmpty ? null : () => _addLineDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une ligne'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _lines.isEmpty
                        ? const Center(child: Text('Aucune ligne.'))
                        : ListView.separated(
                            itemCount: _lines.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final l = _lines[i];
                              final lineHT = l.unitPrice * l.quantity;
                              final lineVAT = lineHT * l.vatRate;
                              final lineTotal = lineHT + lineVAT;
                              return ListTile(
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text('Qté: ${l.quantity} • PU: ${l.unitPrice} • TVA: ${(l.vatRate * 100).toStringAsFixed(0)}%'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(Formatters.moneyCfa(lineTotal)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => setState(() => _lines.removeAt(i)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Total HT: ${Formatters.moneyCfa(totalHT)}'),
                          Text('TVA: ${Formatters.moneyCfa(totalVAT)}'),
                          Text('Total TTC: ${Formatters.moneyCfa(totalTTC)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<QuoteBloc, QuoteState>(
                    builder: (context, state) {
                      final saving = state.status == QuoteStatus.loading;
                      return ElevatedButton(
                        onPressed: saving || _clientId == null || _lines.isEmpty
                            ? null
                            : () {
                                final items = _lines
                                    .map(
                                      (l) => QuoteItemDraft(
                                        productName: l.name,
                                        unitPrice: l.unitPrice,
                                        quantity: l.quantity,
                                        vatRate: l.vatRate,
                                      ),
                                    )
                                    .toList(growable: false);
                                context.read<QuoteBloc>().add(
                                      QuoteCreateRequested(
                                        clientId: _clientId!,
                                        date: DateTime.now(),
                                        items: items,
                                        status: 'Brouillon',
                                      ),
                                    );
                                Navigator.of(context).pop();
                              },
                        child: Text(saving ? 'Enregistrement...' : 'Créer le devis'),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _addLineDialog(BuildContext context) async {
    int? productId = _products.isNotEmpty ? _products.first.id : null;
    final qtyCtrl = TextEditingController(text: '1');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter une ligne'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              key: ValueKey(productId),
              initialValue: productId,
              decoration: const InputDecoration(labelText: 'Produit/Service'),
              items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) => productId = v,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );

    if (ok == true && productId != null) {
      final p = _products.firstWhere((x) => x.id == productId);
      final q = double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.')) ?? 1;
      setState(() {
        _lines.add(_Line(name: p.name, unitPrice: p.unitPrice, vatRate: p.vatRate, quantity: q));
      });
    }
  }
}

class _Line {
  _Line({required this.name, required this.unitPrice, required this.vatRate, required this.quantity});

  final String name;
  final double unitPrice;
  final double vatRate;
  final double quantity;
}


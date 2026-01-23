/// QuoteEditorScreen – création d'un devis avec design moderne et épuré.
///
/// Design professionnel avec étapes visuelles, cards élégantes et calculs en temps réel.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Nouveau Devis'),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_loading && _clients.isNotEmpty && _products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showHelp(context),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty || _products.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Étape 1: Sélection client
                            _buildStepCard(
                              stepNumber: 1,
                              title: 'Sélectionner le client',
                              icon: Icons.person,
                              child: _buildClientSelector(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Étape 2: Ajouter des lignes
                            _buildStepCard(
                              stepNumber: 2,
                              title: 'Ajouter des articles',
                              icon: Icons.shopping_cart,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _addLineDialog(context),
                                      icon: const Icon(Icons.add_circle_outline),
                                      label: const Text('Ajouter un article'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.yellow,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  
                                  if (_lines.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _buildLinesList(),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Résumé des totaux
                            if (_lines.isNotEmpty) _buildTotalsSummary(totalHT, totalVAT, totalTTC),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer avec bouton de création
                    _buildFooter(totalTTC),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _clients.isEmpty
                  ? 'Aucun client disponible'
                  : 'Aucun produit disponible',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _clients.isEmpty
                  ? 'Vous devez d\'abord ajouter des clients avant de créer un devis.'
                  : 'Vous devez d\'abord ajouter des produits/services avant de créer un devis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(_clients.isEmpty ? 'Ajouter un client' : 'Ajouter un produit'),
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
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'étape
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.1),
                  AppColors.yellow.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  color: AppColors.yellow,
                  size: 28,
                ),
              ],
            ),
          ),
          
          // Contenu de l'étape
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelector() {
    final selectedClient = _clients.firstWhere(
      (c) => c.id == _clientId,
      orElse: () => _clients.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<int>(
        value: _clientId,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        hint: const Text('Choisir un client'),
        items: _clients.map((c) {
          return DropdownMenuItem<int>(
            value: c.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (c.phone.isNotEmpty)
                  Text(
                    c.phone,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          );
        }).toList(growable: false),
        onChanged: (v) => setState(() => _clientId = v),
        isExpanded: true,
      ),
    );
  }

  Widget _buildLinesList() {
    return Column(
      children: List.generate(_lines.length, (i) {
        final l = _lines[i];
        final lineHT = l.unitPrice * l.quantity;
        final lineVAT = lineHT * l.vatRate;
        final lineTotal = lineHT + lineVAT;

        return Dismissible(
          key: ValueKey('${l.name}_$i'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => setState(() => _lines.removeAt(i)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.moneyCfa(lineTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.yellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('Qté: ${l.quantity}', Icons.format_list_numbered),
                    const SizedBox(width: 8),
                    _buildInfoChip('PU: ${Formatters.moneyCfa(l.unitPrice)}', Icons.attach_money),
                    const SizedBox(width: 8),
                    _buildInfoChip('TVA: ${(l.vatRate * 100).toStringAsFixed(0)}%', Icons.percent),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSummary(double totalHT, double totalVAT, double totalTTC) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.yellow.withOpacity(0.1),
            AppColors.yellow.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellow.withOpacity(0.3), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total HT',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                Formatters.moneyCfa(totalHT),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TVA',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                Formatters.moneyCfa(totalVAT),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: Colors.grey[400]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total TTC',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Text(
                Formatters.moneyCfa(totalTTC),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double totalTTC) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BlocBuilder<QuoteBloc, QuoteState>(
          builder: (context, state) {
            final saving = state.status == QuoteStatus.loading;
            final canSave = _clientId != null && _lines.isNotEmpty && !saving;

            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canSave
                    ? () {
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
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _lines.isEmpty
                                ? 'Ajouter des articles'
                                : 'Créer le devis • ${Formatters.moneyCfa(totalTTC)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_shopping_cart, color: AppColors.yellow),
            ),
            const SizedBox(width: 12),
            const Text('Ajouter un article'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produit/Service',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<int>(
                value: productId,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: _products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${Formatters.moneyCfa(p.unitPrice)} • TVA: ${(p.vatRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => productId = v,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quantité',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.yellow, width: 2),
                ),
                prefixIcon: const Icon(Icons.format_list_numbered),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ajouter'),
          ),
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

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.yellow),
            const SizedBox(width: 12),
            const Text('Aide'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '📋 Comment créer un devis ?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text('1. Sélectionnez un client'),
            SizedBox(height: 8),
            Text('2. Ajoutez des articles avec leurs quantités'),
            SizedBox(height: 8),
            Text('3. Glissez vers la gauche pour supprimer un article'),
            SizedBox(height: 8),
            Text('4. Validez pour créer le devis'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class _Line {
  _Line({required this.name, required this.unitPrice, required this.vatRate, required this.quantity});

  final String name;
  final double unitPrice;
  final double vatRate;
  final double quantity;
}
/// QuoteEditorScreen – création/édition d'un devis avec gestion des statuts.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_item.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/repositories/quote_repository.dart';
import '../../domain/repositories/company_repository.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../widgets/quote_preview_dialog.dart';
import '../widgets/success_dialog.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/quote_pdf_service.dart';
import 'package:devis_pro/src/presentation/widgets/custom_connectivity_banner.dart';

class QuoteEditorScreen extends StatefulWidget {
  final Quote? quote;
  final List<QuoteItem>? initialItems;

  const QuoteEditorScreen({
    super.key,
    this.quote,
    this.initialItems,
  });

  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  
  List<Product> _products = [];
  final List<_Line> _lines = [];
  bool _loading = true;

  bool get _isReadOnly => widget.quote?.status == 'Envoyé';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final productRepo = context.read<ProductRepository>();
    _products = await productRepo.list();

    if (widget.quote != null) {
      _clientNameController.text = widget.quote!.clientName ?? '';
      _clientPhoneController.text = widget.quote!.clientPhone ?? '';
      
      final quoteRepo = context.read<QuoteRepository>();
      final items = widget.initialItems ?? await quoteRepo.listItems(widget.quote!.id);
      for (var item in items) {
        _lines.add(_Line(
          name: item.productName,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          quantity: item.quantity,
          unit: item.unit,
        ));
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  void _submitQuote() {
    if (_clientNameController.text.isEmpty || _clientPhoneController.text.isEmpty || _lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les informations client et ajouter des articles.')),
      );
      return;
    }

    final items = _lines.map((l) => QuoteItemDraft(
      productName: l.name,
      unitPrice: l.unitPrice,
      quantity: l.quantity,
      vatRate: l.vatRate,
      unit: l.unit,
    )).toList();

    context.read<QuoteBloc>().add(
      QuoteCreateRequested(
        clientId: null,
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        date: DateTime.now(),
        items: items,
        status: 'Brouillon',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomConnectivityBanner(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(widget.quote == null ? 'Nouveau Devis' : 'Détails du Devis'),
          elevation: 0,
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text(_isReadOnly ? 'ENVOYÉ' : 'BROUILLON', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: _isReadOnly ? Colors.blue : Colors.grey[600],
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showHelp(context)),
          ],
        ),
        body: _loading ? const Center(child: CircularProgressIndicator()) : _buildEditorBody(),
      ),
    );
  }

  Widget _buildEditorBody() {
    return BlocListener<QuoteBloc, QuoteState>(
      listener: (context, state) async {
        if (state.status == QuoteStatus.success && state.createdQuote != null) {
          final companyRepo = context.read<CompanyRepository>();
          final quoteRepo = context.read<QuoteRepository>();
          final pdfService = QuotePdfService();
          final company = await companyRepo.getCompany();
          final items = await quoteRepo.listItems(state.createdQuote!.id);
          final pdfFuture = pdfService.buildPdf(company: company, quote: state.createdQuote!, items: items);

          if (!mounted) return;
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => SuccessDialog(
              title: 'Devis Généré !',
              message: 'Le devis ${state.createdQuote!.quoteNumber} a été créé avec succès.',
              buttonText: 'Voir l\'aperçu PDF',
              onConfirm: () => Navigator.of(context).pop(),
            ),
          );

          final pdfBytes = await pdfFuture;
          if (!mounted) return;
          await showDialog(context: context, builder: (_) => QuotePreviewDialog(quote: state.createdQuote!, items: items, company: company, pdfBytes: pdfBytes));
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final totalHT = _lines.fold<double>(0, (sum, l) => sum + l.unitPrice * l.quantity);
    final totalVAT = _lines.fold<double>(0, (sum, l) => sum + (l.unitPrice * l.quantity * l.vatRate));
    final totalTTC = totalHT + totalVAT;
    final isStep1Complete = _clientNameController.text.trim().isNotEmpty && _clientPhoneController.text.trim().isNotEmpty;

    return Column(
      children: [
        if (_isReadOnly)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.1),
            child: Row(children: [const Icon(Icons.lock, color: Colors.blue, size: 16), const SizedBox(width: 8), const Expanded(child: Text('Ce devis a été envoyé et ne peut plus être modifié.', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600)))]),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepCard(stepNumber: 1, title: 'Informations du client', icon: Icons.person, child: _buildClientInput()),
                const SizedBox(height: 16),
                _buildStepCard(
                  stepNumber: 2,
                  title: 'Articles du devis',
                  icon: Icons.shopping_cart,
                  isDisabled: !isStep1Complete,
                  child: Column(
                    children: [
                      if (!_isReadOnly)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isStep1Complete ? () => _addLineDialog(context) : null,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Ajouter un article'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      if (_lines.isNotEmpty) ...[const SizedBox(height: 16), _buildLinesList()],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_lines.isNotEmpty) _buildTotalsSummary(totalHT, totalVAT, totalTTC),
              ],
            ),
          ),
        ),
        if (!_isReadOnly) _buildFooter(totalTTC),
      ],
    );
  }

  Widget _buildClientInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('Nom / Prénom'),
        const SizedBox(height: 8),
        TextField(controller: _clientNameController, enabled: !_isReadOnly, onChanged: (_) => setState(() {}), decoration: _inputDecoration('Ex: Jean Dupont', Icons.person_outline)),
        const SizedBox(height: 16),
        _buildLabel('Numéro de téléphone'),
        const SizedBox(height: 8),
        TextField(controller: _clientPhoneController, enabled: !_isReadOnly, onChanged: (_) => setState(() {}), keyboardType: TextInputType.phone, decoration: _inputDecoration('Ex: +221 77 123 45 67', Icons.phone_outlined)),
        if (!_isReadOnly) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showClientPicker(),
            icon: const Icon(Icons.person_search_rounded, size: 20),
            label: const Text('Choisir Client'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87));

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    filled: true,
    fillColor: _isReadOnly ? Colors.grey[100] : Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.yellow, width: 2)),
    prefixIcon: Icon(icon),
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  Widget _buildStepCard({required int stepNumber, required String title, required IconData icon, required Widget child, bool isDisabled = false}) {
    final effectiveDisabled = isDisabled || (_isReadOnly && stepNumber == 2 && _lines.isEmpty);
    return Opacity(
      opacity: effectiveDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: LinearGradient(colors: effectiveDisabled ? [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)] : [AppColors.yellow.withOpacity(0.1), AppColors.yellow.withOpacity(0.05)]), borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: effectiveDisabled ? Colors.grey[400] : AppColors.yellow, shape: BoxShape.circle), child: Center(child: Text(stepNumber.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: effectiveDisabled ? Colors.grey[600] : Colors.black87))),
              Icon(icon, color: effectiveDisabled ? Colors.grey[400] : AppColors.yellow, size: 28),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ]),
      ),
    );
  }

  Widget _buildLinesList() {
    return Column(
      children: List.generate(_lines.length, (i) {
        final l = _lines[i];
        final lineTotal = (l.unitPrice * l.quantity) * (1 + l.vatRate);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text('${l.quantity} ${l.unit ?? ''} x ${Formatters.moneyCfa(l.unitPrice)}', style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
              Text(Formatters.moneyCfa(lineTotal), style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow)),
              if (!_isReadOnly) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _lines.removeAt(i))),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTotalsSummary(double totalHT, double totalVAT, double totalTTC) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.yellow.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.yellow.withOpacity(0.2))),
      child: Column(children: [_totalRow('Total HT', Formatters.moneyCfa(totalHT)), _totalRow('TVA', Formatters.moneyCfa(totalVAT)), const Divider(), _totalRow('Total TTC', Formatters.moneyCfa(totalTTC), isBold: true)]),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)), Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14))]),
  );

  Widget _buildFooter(double totalTTC) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
      child: SafeArea(
        child: BlocBuilder<QuoteBloc, QuoteState>(
          builder: (context, state) {
            final loading = state.status == QuoteStatus.loading;
            return SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: loading ? null : _submitQuote, style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: loading ? const CircularProgressIndicator(color: Colors.white) : Text('VALIDER LE DEVIS • ${Formatters.moneyCfa(totalTTC)}', style: const TextStyle(fontWeight: FontWeight.bold))));
          },
        ),
      ),
    );
  }

  Future<void> _addLineDialog(BuildContext context) async {
    if (_isReadOnly) return;
    final List<String> units = ['Unité', 'm', 'm²', 'm³', 'kg', 'Litre', 'Heure', 'Jour', 'Forfait', 'Sac', 'Voyage'];
    final FocusNode searchFocusNode = FocusNode();
    String selectedUnit = 'Unité';
    bool isVatEnabled = true;
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final vatCtrl = TextEditingController(text: '18');
    final qtyCtrl = TextEditingController(text: '1');
    int articleCount = 0;
    double lineHT = 0; double lineVAT = 0; double lineTTC = 0;

    void updateTotals(StateSetter setDialogState) {
      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
      final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final vat = isVatEnabled ? (double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 0) / 100 : 0.0;
      setDialogState(() { lineHT = price * qty; lineVAT = lineHT * vat; lineTTC = lineHT + lineVAT; });
    }

    void addArticle(StateSetter setDialogState) {
      if (nameCtrl.text.trim().isEmpty) return;
      final vat = isVatEnabled ? ((double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 18) / 100) : 0.0;
      setState(() { _lines.add(_Line(name: nameCtrl.text.trim(), unitPrice: double.tryParse(priceCtrl.text) ?? 0, vatRate: vat, quantity: double.tryParse(qtyCtrl.text) ?? 1, unit: selectedUnit)); });
      setDialogState(() { articleCount++; nameCtrl.clear(); priceCtrl.clear(); qtyCtrl.text = '1'; lineHT = 0; lineVAT = 0; lineTTC = 0; });
      searchFocusNode.requestFocus();
    }

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(builder: (builderContext, setDialogState) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [Text('Nouvel Article ($articleCount)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext))])),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                TextField(controller: nameCtrl, focusNode: searchFocusNode, decoration: const InputDecoration(labelText: 'Nom de l\'article')),
                Row(children: [
                  Expanded(child: DropdownButton<String>(value: selectedUnit, isExpanded: true, items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => setDialogState(() => selectedUnit = v ?? 'Unité'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qté'), onChanged: (_) => updateTotals(setDialogState))),
                ]),
                Row(children: [
                  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix HT'), onChanged: (_) => updateTotals(setDialogState))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: vatCtrl, enabled: isVatEnabled, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'TVA %'), onChanged: (_) => updateTotals(setDialogState))),
                ]),
                const SizedBox(height: 24),
                Container(padding: const EdgeInsets.all(16), color: AppColors.yellow.withOpacity(0.1), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total TTC Art.', style: TextStyle(fontWeight: FontWeight.bold)), Text(Formatters.moneyCfa(lineTTC), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.yellow))])),
                const SizedBox(height: 24),
                Row(children: [
                  if (articleCount > 0) Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('TERMINER'))),
                  if (articleCount > 0) const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () => addArticle(setDialogState), style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: Colors.white), child: const Text('AJOUTER'))),
                ]),
              ]),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _showClientPicker() async {
    if (_isReadOnly) return;
    final clientRepo = context.read<ClientRepository>();
    final allClients = await clientRepo.list();
    if (!mounted) return;
    final selectedClient = await showModalBottomSheet<Client>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: ListView.separated(shrinkWrap: true, padding: const EdgeInsets.all(16), itemCount: allClients.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (context, index) => ListTile(title: Text(allClients[index].name), subtitle: Text(allClients[index].phone), onTap: () => Navigator.pop(context, allClients[index]))),
      ),
    );
    if (selectedClient != null && mounted) setState(() { _clientNameController.text = selectedClient.name; _clientPhoneController.text = selectedClient.phone; });
  }

  void _showHelp(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Aide'), content: const Text('Remplissez les informations client pour activer l\'ajout d\'articles.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }
}

class _Line {
  _Line({required this.name, required this.unitPrice, required this.vatRate, required this.quantity, this.unit});
  final String name; final double unitPrice; final double vatRate; final double quantity; final String? unit;
}

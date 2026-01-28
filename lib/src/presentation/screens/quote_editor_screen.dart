/// QuoteEditorScreen – création d'un devis avec design moderne et épuré.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/client.dart'; // NOUVEAU
import '../../domain/entities/template.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/client_repository.dart'; // NOUVEAU
import '../../domain/repositories/quote_repository.dart';
import '../../domain/repositories/template_repository.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../blocs/template/template_state.dart';
import '../widgets/quote_preview_dialog.dart';
import '../widgets/success_dialog.dart';
import '../../domain/repositories/company_repository.dart';
import 'package:devis_pro/src/presentation/widgets/custom_connectivity_banner.dart';
import '../widgets/confirmation_dialog.dart';
import '../services/quote_pdf_service.dart';

class QuoteEditorScreen extends StatefulWidget {
  const QuoteEditorScreen({super.key});

  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  // Controllers pour les informations du client
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  // Data
  List<Product> _products = [];
  
  // Form Data
  DateTime _date = DateTime.now();
  final List<_Line> _lines = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final productRepo = context.read<ProductRepository>();
    final products = await productRepo.list();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  void _submitQuote() {
    if (_clientNameController.text.isEmpty || _clientPhoneController.text.isEmpty || _lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir les informations client et ajouter des articles.')),
      );
      return;
    }

    final items = _lines
        .map(
          (l) => QuoteItemDraft(
            productName: l.name,
            unitPrice: l.unitPrice,
            quantity: l.quantity,
            vatRate: l.vatRate,
            unit: l.unit,
          ),
        )
        .toList(growable: false);

    context.read<QuoteBloc>().add(
          QuoteCreateRequested(
            clientId: null,
            clientName: _clientNameController.text,
            clientPhone: _clientPhoneController.text,
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
          title: const Text('Nouveau Devis'),
          elevation: 0,
          centerTitle: true,
          actions: [
            if (!_loading) ...[
              // IconButton(
              //   icon: const Icon(Icons.note_add),
              //   tooltip: 'Utiliser un modèle',
              //   onPressed: () => _showTemplatesDialog(context),
              // ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showHelp(context),
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildEditorBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBody() {
    return BlocListener<QuoteBloc, QuoteState>(
      listener: (context, state) async {
        if (state.status == QuoteStatus.success && state.createdQuote != null) {
          // ✨ OPTIMISATION : Démarrer la génération du PDF en arrière-plan dès le succès
          final companyRepo = context.read<CompanyRepository>();
          final quoteRepo = context.read<QuoteRepository>();
          final pdfService = QuotePdfService();
          
          final company = await companyRepo.getCompany();
          final items = await quoteRepo.listItems(state.createdQuote!.id);
          
          // Lancer la génération pendant que l'utilisateur voit le modal de succès
          final pdfFuture = pdfService.buildPdf(
            company: company,
            quote: state.createdQuote!,
            items: items,
          );

          if (!mounted) return;

          // 1. Afficher le modal de succès style SweetAlert
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

          // Attendre que le PDF soit fini (souvent déjà fait à ce stade)
          final pdfBytes = await pdfFuture;

          if (!mounted) return;

          // 3. Afficher l'aperçu INSTANTANÉMENT avec les octets
          await showDialog(
            context: context,
            builder: (_) => QuotePreviewDialog(
              quote: state.createdQuote!,
              items: items,
              company: company,
              pdfBytes: pdfBytes, // ✨ PASSAGE DIRECT DES OCTETS
            ),
          );
          
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final totalHT = _lines.fold<double>(0, (sum, l) => sum + l.unitPrice * l.quantity);
    final totalVAT = _lines.fold<double>(0, (sum, l) => sum + (l.unitPrice * l.quantity * l.vatRate));
    final totalTTC = totalHT + totalVAT;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepCard(
                  stepNumber: 1,
                  title: 'Informations du client',
                  icon: Icons.person,
                  child: _buildClientInput(),
                ),
                const SizedBox(height: 16),
                _buildStepCard(
                  stepNumber: 2,
                  title: 'Ajouter des articles',
                  icon: Icons.shopping_cart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                if (_lines.isNotEmpty) _buildTotalsSummary(totalHT, totalVAT, totalTTC),
              ],
            ),
          ),
        ),
        _buildFooter(totalTTC),
      ],
    );
  }

  Widget _buildClientInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nom/Prénom du client
        const Text(
          'Nom / Prénom',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _clientNameController,
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
            prefixIcon: const Icon(Icons.person_outline),
            hintText: 'Ex: Jean Dupont',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        
        // Numéro de téléphone
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _clientPhoneController,
          keyboardType: TextInputType.phone,
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
            prefixIcon: const Icon(Icons.phone_outlined),
            hintText: 'Ex: +221 77 123 45 67',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        
        // NOUVEAU : Bouton "Choisir Client" au lieu de "Ouvrir Répertoire"
        ElevatedButton.icon(
          onPressed: () => _showClientPicker(),
          icon: const Icon(Icons.person_search_rounded, size: 20),
          label: const Text('Choisir Client'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  /// NOUVEAU : Modal de sélection de client local
  /// NOUVEAU : Modal de sélection de client local avec recherche
  Future<void> _showClientPicker() async {
    final clientRepo = context.read<ClientRepository>();
    final clients = await clientRepo.list();

    if (!mounted) return;

    final selectedClient = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // État local pour la recherche
          final searchController = TextEditingController();
          List<Client> filteredClients = clients;

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
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.people_rounded, color: AppColors.yellow),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('Sélectionner un Client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    ),
                    
                    // ✨ BARRE DE RECHERCHE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: TextField(
                        controller: searchController,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un client...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setModalState(() {
                                      searchController.clear();
                                      filteredClients = clients;
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            if (value.isEmpty) {
                              filteredClients = clients;
                            } else {
                              filteredClients = clients.where((client) {
                                final searchLower = value.toLowerCase();
                                return client.name.toLowerCase().contains(searchLower) ||
                                    client.phone.toLowerCase().contains(searchLower);
                              }).toList();
                            }
                          });
                        },
                      ),
                    ),
                    
                    const Divider(height: 1),
                    Expanded(
                      child: filteredClients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchController.text.isEmpty 
                                        ? 'Aucun client enregistré' 
                                        : 'Aucun résultat trouvé',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredClients.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final client = filteredClients[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.yellow.withOpacity(0.1),
                                    child: Text(
                                      client.name[0].toUpperCase(),
                                      style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(client.phone),
                                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                  onTap: () => Navigator.pop(context, client),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    if (selectedClient != null && mounted) {
      setState(() {
        _clientNameController.text = selectedClient.name;
        _clientPhoneController.text = selectedClient.phone;
      });
    }
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

  Widget _buildLinesList() {
    if (_lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.add_shopping_cart, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun article dans ce devis',
              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => setState(() => _lines.removeAt(i)),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmationDialog(
                title: 'Supprimer l\'article ?',
                content: 'Voulez-vous vraiment retirer "${l.name}" de ce devis ?',
                confirmText: 'Supprimer',
                confirmColor: Colors.red,
                onConfirm: () => Navigator.of(context).pop(true),
              ),
            ) ?? false;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PU: ${Formatters.moneyCfa(l.unitPrice)} ${l.unit != null ? '/ ${l.unit}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.moneyCfa(lineTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: AppColors.yellow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TVA ${(l.vatRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Quantité : ',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        Text(
                          '${l.quantity} ${l.unit ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => setState(() => _lines.removeAt(i)),
                      child: Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
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
            final canSave = _clientNameController.text.isNotEmpty && _clientPhoneController.text.isNotEmpty && _lines.isNotEmpty && !saving;

            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canSave ? _submitQuote : null,
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
    // Liste des unités courantes
    final List<String> units = ['Unité', 'm', 'm²', 'm³', 'kg', 'Litre', 'Heure', 'Jour', 'Forfait', 'Sac', 'Voyage'];
    
    // FocusNode pour gérer le focus automatique
    final FocusNode searchFocusNode = FocusNode();
    
    // État local du dialogue
    String selectedUnit = 'Unité';
    bool isVatEnabled = true;
    Product? selectedProduct;
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final vatCtrl = TextEditingController(text: '18');
    final qtyCtrl = TextEditingController(text: '1');
    
    // Compteur d'articles ajoutés
    int articleCount = 0;
    
    // Pour les calculs en temps réel
    double lineHT = 0;
    double lineVAT = 0;
    double lineTTC = 0;

    void updateTotals(StateSetter setDialogState) {
      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
      final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
      final vat = isVatEnabled ? (double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 0) / 100 : 0.0;
      
      setDialogState(() {
        lineHT = price * qty;
        lineVAT = lineHT * vat;
        lineTTC = lineHT + lineVAT;
      });
    }

    // Fonction pour vider les champs après ajout
    void resetFields(StateSetter setDialogState) {
      setDialogState(() {
        nameCtrl.clear();
        priceCtrl.clear();
        qtyCtrl.text = '1';
        // On garde selectedUnit, vatCtrl et isVatEnabled
        lineHT = 0;
        lineVAT = 0;
        lineTTC = 0;
      });
      // Focus automatique sur le champ de recherche
      searchFocusNode.requestFocus();
    }

    // Fonction pour ajouter l'article sans fermer le modal
    void addArticle(StateSetter setDialogState, {bool closeAfter = false}) {
      if (nameCtrl.text.trim().isEmpty) {
        // Feedback haptique si champ vide
        HapticFeedback.mediumImpact();
        return;
      }
      
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0;
      final vat = isVatEnabled ? ((double.tryParse(vatCtrl.text.replaceAll(',', '.')) ?? 18) / 100) : 0.0;
      final unit = selectedUnit;
      final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1;

      // Si c'est un nouveau produit, on le sauvegarde
      final isExisting = _products.any((p) => p.name.toLowerCase() == name.toLowerCase());
      if (!isExisting) {
        final productRepo = context.read<ProductRepository>();
        productRepo.create(name: name, unitPrice: price, vatRate: vat, unit: unit).then((_) => _loadProducts());
      }

      // Ajouter l'article à la liste principale
      setState(() {
        _lines.add(_Line(
          name: name,
          unitPrice: price,
          vatRate: vat,
          quantity: qty,
          unit: unit,
        ));
      });

      // Feedback haptique de succès
      HapticFeedback.lightImpact();

      // Incrémenter le compteur
      setDialogState(() {
        articleCount++;
      });

      if (closeAfter) {
        // Fermer le modal
        Navigator.pop(context);
      } else {
        // Vider les champs et continuer
        resetFields(setDialogState);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barre de drag
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Header avec compteur
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.yellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_shopping_cart, color: AppColors.yellow),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Nouvel Article',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      
                      // Compteur d'articles ajoutés avec animation
                      if (articleCount > 0) ...[
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade200, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '✓ $articleCount article${articleCount > 1 ? 's' : ''} ajouté${articleCount > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recherche / Saisie Nom
                        const Text('NOM DE L\'ARTICLE / SERVICE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Autocomplete<Product>(
                          displayStringForOption: (p) => p.name,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) return const Iterable<Product>.empty();
                            return _products.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (Product p) {
                            setDialogState(() {
                              selectedProduct = p;
                              nameCtrl.text = p.name;
                              priceCtrl.text = p.unitPrice.toString();
                              vatCtrl.text = (p.vatRate * 100).toStringAsFixed(0);
                              selectedUnit = p.unit;
                              isVatEnabled = p.vatRate > 0;
                            });
                            updateTotals(setDialogState);
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            if (nameCtrl.text.isNotEmpty && controller.text.isEmpty) {
                              controller.text = nameCtrl.text;
                            }
                            controller.addListener(() {
                              nameCtrl.text = controller.text;
                            });
                            
                            return TextField(
                              controller: controller,
                              focusNode: searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Rechercher ou saisir un nom...',
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.search, size: 20),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Unité & Quantité
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('UNITÉ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedUnit,
                                        isExpanded: true,
                                        items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                                        onChanged: (v) => setDialogState(() => selectedUnit = v ?? 'Unité'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('QTÉ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: qtyCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                    onChanged: (_) => updateTotals(setDialogState),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Prix & TVA
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PRIX UNITAIRE (HT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: priceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      suffixText: 'CFA',
                                      filled: true,
                                      fillColor: const Color(0xFFF8F9FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                                    ),
                                    onChanged: (_) => updateTotals(setDialogState),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('TVA %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                                      SizedBox(
                                        height: 20,
                                        width: 30,
                                        child: Switch(
                                          value: isVatEnabled,
                                          activeColor: AppColors.yellow,
                                          onChanged: (value) {
                                            setDialogState(() {
                                              isVatEnabled = value;
                                            });
                                            updateTotals(setDialogState);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: vatCtrl,
                                    enabled: isVatEnabled,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isVatEnabled ? const Color(0xFFF8F9FA) : Colors.grey[200],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                    onChanged: (_) => updateTotals(setDialogState),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Résumé du calcul
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.yellow.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              _buildCalculationRow('Total HT', lineHT),
                              const SizedBox(height: 8),
                              _buildCalculationRow(isVatEnabled ? 'TVA (${vatCtrl.text}%)' : 'TVA (Désactivée)', lineVAT),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL TTC ARTICLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                  Text(
                                    Formatters.moneyCfa(lineTTC),
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.yellow),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Boutons modifiés pour le mode série
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Bouton "Terminer" (visible seulement après le premier ajout)
                      if (articleCount > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              minimumSize: const Size(0, 56),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              'TERMINER',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Bouton "Ajouter"
                      Expanded(
                        flex: articleCount > 0 ? 2 : 1,
                        child: ElevatedButton(
                          onPressed: () => addArticle(setDialogState, closeAfter: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellow,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            articleCount > 0 ? 'AJOUTER ' : 'AJOUTER AU DEVIS',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildCalculationRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        Text(Formatters.moneyCfa(amount), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  // void _showTemplatesDialog(BuildContext context) {
  //   // Charger les templates
  //   context.read<TemplateBloc>().add(const TemplateLoadAll());

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (modalContext) {
  //       return DraggableScrollableSheet(
  //         initialChildSize: 0.7,
  //         minChildSize: 0.5,
  //         maxChildSize: 0.95,
  //         builder: (context, scrollController) {
  //           return Container(
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //             ),
  //             child: Column(
  //               children: [
  //                 // Handle de drag
  //                 Container(
  //                   margin: const EdgeInsets.only(top: 12, bottom: 8),
  //                   width: 40,
  //                   height: 4,
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey[300],
  //                     borderRadius: BorderRadius.circular(2),
  //                   ),
  //                 ),
  //                 // Header
  //                 Padding(
  //                   padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.note_add, color: AppColors.yellow, size: 28),
  //                       const SizedBox(width: 12),
  //                       const Expanded(
  //                         child: Text(
  //                           'Choisir un modèle',
  //                           style: TextStyle(
  //                             fontSize: 22,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                       IconButton(
  //                         icon: const Icon(Icons.close),
  //                         onPressed: () => Navigator.pop(modalContext),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 const Divider(height: 1),
  //                 // Liste des templates
  //                 Expanded(
  //                   child: BlocBuilder<TemplateBloc, TemplateState>(
  //                     builder: (context, state) {
  //                       if (state is TemplateLoading) {
  //                         return const Center(child: CircularProgressIndicator());
  //                       }

  //                       if (state is TemplateListLoaded) {
  //                         if (state.templates.isEmpty) {
  //                           return Center(
  //                             child: Column(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               children: [
  //                                 Icon(Icons.note_add_outlined,
  //                                     size: 64, color: Colors.grey[400]),
  //                                 const SizedBox(height: 16),
  //                                 Text(
  //                                   'Aucun modèle disponible',
  //                                   style: TextStyle(
  //                                     fontSize: 16,
  //                                     color: Colors.grey[600],
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           );
  //                         }

  //                         return ListView.separated(
  //                           controller: scrollController,
  //                           padding: const EdgeInsets.all(24),
  //                           itemCount: state.templates.length,
  //                           separatorBuilder: (context, index) =>
  //                               const SizedBox(height: 12),
  //                           itemBuilder: (context, index) {
  //                             final template = state.templates[index];
  //                             return _buildTemplateListItem(
  //                                 modalContext, template);
  //                           },
  //                         );
  //                       }

  //                       return const Center(child: Text('Erreur de chargement'));
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // Widget _buildTemplateListItem(BuildContext modalContext, QuoteTemplate template) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: InkWell(
  //       borderRadius: BorderRadius.circular(12),
  //       onTap: () {
  //         Navigator.pop(modalContext);
  //         _loadTemplateData(template);
  //       },
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: AppColors.yellow.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(
  //                 template.isCustom ? Icons.person : Icons.star,
  //                 color: AppColors.yellow,
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     template.name,
  //                     style: const TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     template.description,
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       color: Colors.grey[600],
  //                     ),
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //               decoration: BoxDecoration(
  //                 color: _getCategoryColor(template.category).withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(20),
  //                 border: Border.all(
  //                   color: _getCategoryColor(template.category),
  //                   width: 1.5,
  //                 ),
  //               ),
  //               child: Text(
  //                 template.category,
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.bold,
  //                   color: _getCategoryColor(template.category),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

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

  // Future<void> _loadTemplateData(QuoteTemplate template) async {
  //   // Charger les items du template
  //   final templateRepo = context.read<TemplateRepository>();
  //   final items = await templateRepo.getTemplateItems(template.id);

  //   if (!mounted) return;

  //   // Pré-remplir les lignes du devis
  //   setState(() {
  //     _lines.clear();
  //     for (final item in items) {
  //       _lines.add(_Line(
  //         name: item.productName,
  //         unitPrice: item.unitPrice,
  //         vatRate: item.vatRate,
  //         quantity: item.quantity.toDouble(),
  //         unit: item.unit,
  //       ));
  //     }
  //   });

  //   // Afficher un message de confirmation
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Modèle "${template.name}" chargé avec ${items.length} article(s)'),
  //         backgroundColor: Colors.green,
  //         duration: const Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }

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
            SizedBox(height: 16),
            Text(
              '💡 Astuce : Utilisez un modèle pour gagner du temps !',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.yellow),
            ),
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
  _Line({
    required this.name,
    required this.unitPrice,
    required this.vatRate,
    required this.quantity,
    this.unit,
  });

  final String name;
  final double unitPrice;
  final double vatRate;
  final double quantity;
  final String? unit;
}

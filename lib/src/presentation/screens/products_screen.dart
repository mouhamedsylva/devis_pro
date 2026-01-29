/// ProductsScreen – liste + ajout/modif/suppression (MVP).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/product.dart';
import '../blocs/products/product_bloc.dart';
import '../widgets/app_text_field.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/app_scaffold.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductListRequested());
    _searchController.addListener(() {
      if (mounted) { // Ensure the widget is still in the tree
        setState(() {}); // Pour mettre à jour l'icône clear
      }
    });
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
            hintText: 'Rechercher un produit...',
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
            setState(() {}); // Rafraîchir la liste filtrée
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSortOptions(context);
            },
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          final products = state.products ?? const <Product>[];
          if (products.isEmpty && state.status != ProductStatus.loading) {
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
              onPressed: () => _openProductDialog(),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Nouveau Produit',
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
      body: BlocConsumer<ProductBloc, ProductState>(
        listenWhen: (p, c) => c.status == ProductStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red, // Assuming failure snackbars are red
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 20),
            ),
          );
        },
        builder: (context, state) {
          if (state.status == ProductStatus.loading) {
            return _buildLoadingSkeleton();
          }
          
          var products = state.products ?? const <Product>[];
          
          // Filtrer par recherche
          final searchTerm = _searchController.text.toLowerCase();
          if (searchTerm.isNotEmpty) {
            products = products.where((p) => 
              p.name.toLowerCase().contains(searchTerm)
            ).toList();
          }
          
          // Appliquer le tri
          products = _applySorting(products);
          
          if (products.isEmpty) {
            return _buildEmptyState(context, searchTerm);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = products[i];
              return Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                dismissThresholds: const {DismissDirection.endToStart: 0.6},
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await _confirmDelete(p);
                },
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inventory_2_rounded, color: AppColors.yellow, size: 24),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${p.unitPrice.toStringAsFixed(0)} FCFA / ${p.unit} | TVA ${ (p.vatRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    onTap: () => _openProductDialog(existing: p),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(Product p) async {
    final bloc = context.read<ProductBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: 'Supprimer',
        content: 'Voulez-vous vraiment supprimer "${p.name}" ?',
        confirmText: 'Supprimer',
        confirmColor: Colors.red,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (ok == true) {
      bloc.add(ProductDeleteRequested(p.id));
      return true;
    }
    return false;
  }

  Future<void> _openProductDialog({Product? existing}) async {
    if (!mounted) return;
    
    final bloc = context.read<ProductBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing?.unitPrice.toStringAsFixed(0) ?? ''
    );
    final vatCtrl = TextEditingController(
      text: existing == null 
        ? '18' 
        : (existing.vatRate * 100).toStringAsFixed(0)
    );
    
    String selectedUnit = existing?.unit ?? 'Unité';
    bool isVatEnabled = existing == null ? true : existing.vatRate > 0;
    
    final List<String> units = [
      'Unité', 'm', 'm²', 'm³', 'kg', 'Litre', 
      'Heure', 'Jour', 'Forfait', 'Sac', 'Voyage'
    ];

    final saved = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenHeight = MediaQuery.of(context).size.height;
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: Container(
                      width: constraints.maxWidth > 500 
                        ? 500 
                        : constraints.maxWidth * 0.9,
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.85
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✨ HEADER MODERNE
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.yellow,
                                  AppColors.yellow.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        existing == null 
                                          ? 'Nouveau Produit' 
                                          : 'Modifier Produit',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        existing == null 
                                          ? 'Ajoutez un produit au catalogue' 
                                          : 'Modifiez les informations',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  icon: const Icon(
                                    Icons.close_rounded, 
                                    color: Colors.white, 
                                    size: 24
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          
                          // ✨ FORMULAIRE AVEC SCROLL
                          Flexible(
                            fit: FlexFit.loose,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom du produit
                                    const Text(
                                      'NOM DU PRODUIT OU SERVICE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: nameCtrl,
                                      autofocus: true,
                                      textCapitalization: TextCapitalization.words,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Ex: Ciment Portland, Consultation IT...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.inventory_2_outlined,
                                          size: 22,
                                          color: AppColors.yellow,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8F9FA),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: Colors.grey[200]!, 
                                            width: 1
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: AppColors.yellow, 
                                            width: 2
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Colors.red, 
                                            width: 1
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                            color: Colors.red, 
                                            width: 2
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, 
                                          vertical: 16
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.trim().isEmpty) 
                                        ? 'Le nom est requis' 
                                        : null,
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Prix et TVA
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Prix unitaire
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'PRIX UNITAIRE',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.grey,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: priceCtrl,
                                                keyboardType: const TextInputType.numberWithOptions(
                                                  decimal: true
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: '0',
                                                  hintStyle: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  prefixIcon: Icon(
                                                    Icons.payments_outlined,
                                                    size: 22,
                                                    color: AppColors.yellow,
                                                  ),
                                                  suffixText: 'FCFA',
                                                  suffixStyle: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                  filled: true,
                                                  fillColor: const Color(0xFFF8F9FA),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[200]!, 
                                                      width: 1
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: AppColors.yellow, 
                                                      width: 2
                                                    ),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: const BorderSide(
                                                      color: Colors.red, 
                                                      width: 1
                                                    ),
                                                  ),
                                                  focusedErrorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: const BorderSide(
                                                      color: Colors.red, 
                                                      width: 2
                                                    ),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 16, 
                                                    vertical: 16
                                                  ),
                                                ),
                                                validator: (v) {
                                                  if (v == null || v.trim().isEmpty) {
                                                    return 'Requis';
                                                  }
                                                  final val = double.tryParse(
                                                    v.trim().replaceAll(',', '.')
                                                  );
                                                  if (val == null) return 'Invalide';
                                                  if (val < 0) return 'Doit être positif';
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // TVA
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'TVA %',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.grey,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                  Transform.scale(
                                                    scale: 0.8,
                                                    child: Switch(
                                                      value: isVatEnabled,
                                                      activeColor: AppColors.yellow,
                                                      onChanged: (value) {
                                                        setDialogState(() {
                                                          isVatEnabled = value;
                                                          if (!value) vatCtrl.text = '0';
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: vatCtrl,
                                                enabled: isVatEnabled,
                                                keyboardType: const TextInputType.numberWithOptions(
                                                  decimal: true
                                                ),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isVatEnabled 
                                                    ? Colors.black 
                                                    : Colors.grey[400],
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: '18',
                                                  filled: true,
                                                  fillColor: isVatEnabled 
                                                    ? const Color(0xFFF8F9FA) 
                                                    : Colors.grey[100],
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: isVatEnabled 
                                                        ? Colors.grey[200]! 
                                                        : Colors.grey[300]!,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: AppColors.yellow, 
                                                      width: 2
                                                    ),
                                                  ),
                                                  disabledBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: BorderSide(
                                                      color: Colors.grey[300]!, 
                                                      width: 1
                                                    ),
                                                  ),
                                                  errorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: const BorderSide(
                                                      color: Colors.red, 
                                                      width: 1
                                                    ),
                                                  ),
                                                  focusedErrorBorder: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                    borderSide: const BorderSide(
                                                      color: Colors.red, 
                                                      width: 2
                                                    ),
                                                  ),
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 12, 
                                                    vertical: 16
                                                  ),
                                                ),
                                                validator: (v) {
                                                  if (!isVatEnabled) return null;
                                                  if (v == null || v.trim().isEmpty) {
                                                    return 'Requis';
                                                  }
                                                  final val = double.tryParse(v.trim());
                                                  if (val == null) return 'Invalide';
                                                  if (val < 0 || val > 100) {
                                                    return '0-100';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Unité
                                    const Text(
                                      'UNITÉ DE MESURE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16, 
                                        vertical: 4
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.grey[200]!, 
                                          width: 1
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedUnit,
                                          isExpanded: true,
                                          icon: Icon(
                                            Icons.arrow_drop_down, 
                                            color: AppColors.yellow
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          items: units.map((u) {
                                            return DropdownMenuItem<String>(
                                              value: u,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    _getUnitIcon(u),
                                                    size: 18,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(u),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) => setDialogState(() {
                                            selectedUnit = v ?? 'Unité';
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // ✨ FOOTER AVEC BOUTONS
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey[200]!, 
                                  width: 1
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey[700],
                                      side: BorderSide(color: Colors.grey[300]!),
                                      minimumSize: const Size(0, 52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Annuler',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        Navigator.pop(dialogContext, {
                                          'name': nameCtrl.text.trim(),
                                          'price': double.tryParse(
                                            priceCtrl.text.trim().replaceAll(',', '.')
                                          ) ?? 0,
                                          'vat': isVatEnabled 
                                            ? (double.tryParse(
                                                vatCtrl.text.trim().replaceAll(',', '.')
                                              ) ?? 18) / 100 
                                            : 0.0,
                                          'unit': selectedUnit,
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.yellow,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 52),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          existing == null 
                                            ? Icons.add_circle_outline 
                                            : Icons.check_circle_outline,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          existing == null 
                                            ? 'Ajouter' 
                                            : 'Enregistrer',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    
    if (saved != null && saved != false) {
      final res = saved as Map<String, dynamic>;
      if (existing == null) {
        bloc.add(ProductCreateRequested(
          name: res['name'] as String,
          unitPrice: res['price'] as double,
          vatRate: res['vat'] as double,
          unit: res['unit'] as String,
        ));
      } else {
        bloc.add(ProductUpdateRequested(
          Product(
            id: existing.id,
            name: res['name'] as String,
            unitPrice: res['price'] as double,
            vatRate: res['vat'] as double,
            unit: res['unit'] as String,
          ),
        ));
      }
    }
    
    nameCtrl.dispose();
    priceCtrl.dispose();
    vatCtrl.dispose();
  }

  // Helper pour les icônes d'unités
  IconData _getUnitIcon(String unit) {
    switch (unit) {
      case 'm':
      case 'm²':
      case 'm³':
        return Icons.straighten;
      case 'kg':
        return Icons.scale;
      case 'Litre':
        return Icons.local_drink;
      case 'Heure':
      case 'Jour':
        return Icons.schedule;
      case 'Forfait':
        return Icons.workspace_premium;
      case 'Sac':
        return Icons.shopping_bag;
      case 'Voyage':
        return Icons.local_shipping;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  void _showFilterSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: const Text('Trier par'),
              tileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Nom (A-Z)'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('name_asc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Nom (Z-A)'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('name_desc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Prix croissant'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('price_asc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Prix décroissant'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('price_desc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('TVA croissante'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('vat_asc');
              },
            ),
            ListTile(
              leading: const Icon(Icons.percent),
              title: const Text('TVA décroissante'),
              onTap: () {
                Navigator.pop(context);
                _sortProducts('vat_desc');
              },
            ),
          ],
        );
      },
    );
  }

  String _currentSort = 'name_asc';

  void _sortProducts(String sortType) {
    setState(() {
      _currentSort = sortType;
    });
  }

  List<Product> _applySorting(List<Product> products) {
    final sorted = List<Product>.from(products);
    switch (_currentSort) {
      case 'name_asc':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        sorted.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
        break;
      case 'vat_asc':
        sorted.sort((a, b) => a.vatRate.compareTo(b.vatRate));
        break;
      case 'vat_desc':
        sorted.sort((a, b) => b.vatRate.compareTo(a.vatRate));
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
                    color: const Color(0xFFF9B000).withOpacity(0.3),
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
                  ? 'Aucun produit enregistré.' 
                  : 'Aucun produit trouvé pour "$searchTerm".',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (searchTerm.isEmpty)
              ElevatedButton.icon(
                onPressed: () => _openProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un produit'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

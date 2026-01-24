/// ProductsScreen – liste + ajout/modif/suppression (MVP).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../blocs/products/product_bloc.dart';
import '../widgets/app_text_field.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductListRequested());
    _searchController.addListener(() {
      setState(() {}); // Pour mettre à jour l'icône clear
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            hintText: 'Rechercher un produit...',
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
          // Masquer le FAB quand il n'y a pas de produits (le bouton est dans l'empty state)
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _openProductDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          );
        },
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listenWhen: (p, c) => c.status == ProductStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = products[i];
              return Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _confirmDelete(p);
                },
                child: ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('PU: ${p.unitPrice.toStringAsFixed(2)} € / ${p.unit} | TVA: ${(p.vatRate * 100).toStringAsFixed(0)}%'),
                  onTap: () => _openProductDialog(existing: p),
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
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${p.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(ProductDeleteRequested(p.id));
      return true; // Indicate that the item was dismissed
    }
    return false; // Indicate that the item was not dismissed
  }

  Future<void> _openProductDialog({Product? existing}) async {
    if (!mounted) return;
    
    final bloc = context.read<ProductBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing?.unitPrice.toString() ?? '');
    final vatCtrl = TextEditingController(text: existing == null ? '18' : (existing.vatRate * 100).toStringAsFixed(0));
    String selectedUnit = existing?.unit ?? 'Unité';
    final List<String> units = ['Unité', 'm', 'm²', 'm³', 'kg', 'Litre', 'Heure', 'Jour', 'Forfait', 'Sac', 'Voyage'];

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenHeight = MediaQuery.of(context).size.height;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              child: Container(
                constraints: BoxConstraints(maxWidth: 500, maxHeight: screenHeight * 0.9),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFDB913), Color(0xFFFFD700)]),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(existing == null ? 'Nouveau produit' : 'Modifier produit',
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(existing == null ? 'Ajoutez un produit ou service' : 'Modifiez les informations',
                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Nom du produit ou service', Icons.label_rounded),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                hintText: 'Ex: Consultation, Installation...',
                                prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFieldLabel('Prix unitaire (FCFA)', Icons.payments_rounded),
                            const SizedBox(height: 8),
                            TextField(
                              controller: priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                prefixIcon: const Icon(Icons.attach_money, size: 20),
                                suffixText: 'FCFA',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('TVA (%)', Icons.percent_rounded),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: vatCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: '18',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Unité', Icons.straighten_rounded),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
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
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (nameCtrl.text.trim().isEmpty) return;
                                Navigator.pop(dialogContext, {
                                  'name': nameCtrl.text.trim(),
                                  'price': double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ?? 0,
                                  'vat': (double.tryParse(vatCtrl.text.trim().replaceAll(',', '.')) ?? 18) / 100,
                                  'unit': selectedUnit,
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF9B000), foregroundColor: Colors.white),
                              child: const Text('Enregistrer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
        bloc.add(ProductCreateRequested(name: res['name'], unitPrice: res['price'], vatRate: res['vat'], unit: res['unit']));
      } else {
        bloc.add(ProductUpdateRequested(Product(id: existing.id, name: res['name'], unitPrice: res['price'], vatRate: res['vat'], unit: res['unit'])));
      }
    }
    
    nameCtrl.dispose();
    priceCtrl.dispose();
    vatCtrl.dispose();
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

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String searchTerm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo DEVISPRO (même style que dashboard)
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
            // Texte principal
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
            // Bouton centré avec style moderne
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
      itemCount: 5, // Show 5 skeleton items
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
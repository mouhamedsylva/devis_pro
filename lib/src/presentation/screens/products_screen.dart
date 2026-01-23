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
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductListRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produits / Services')),
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
          
          final products = state.products ?? const <Product>[];
          if (products.isEmpty) {
            return _buildEmptyState(context);
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
                  subtitle: Text('PU: ${p.unitPrice.toStringAsFixed(2)} € | TVA: ${(p.vatRate * 100).toStringAsFixed(0)}%'),
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
    final bloc = context.read<ProductBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing?.unitPrice.toString() ?? '');
    final vatCtrl = TextEditingController(text: existing == null ? '18' : (existing.vatRate * 100).toStringAsFixed(0));

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Nouveau produit' : 'Modifier produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: nameCtrl, label: 'Nom'),
              const SizedBox(height: 10),
              AppTextField(controller: priceCtrl, label: 'Prix unitaire', keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              AppTextField(controller: vatCtrl, label: 'TVA (%)', keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer')),
        ],
      ),
    );

    if (saved == true) {
      final name = nameCtrl.text.trim();
      final unitPrice = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      final vatPercent = double.tryParse(vatCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      final vatRate = vatPercent / 100.0;
      if (name.isEmpty) return;
      if (existing == null) {
        bloc.add(ProductCreateRequested(name: name, unitPrice: unitPrice, vatRate: vatRate));
      } else {
        bloc.add(
          ProductUpdateRequested(
            Product(id: existing.id, name: name, unitPrice: unitPrice, vatRate: vatRate),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/icône grande taille
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            // Texte principal
            const Text(
              'Aucun produit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Texte secondaire
            Text(
              'Commencez par ajouter votre premier produit ou service',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Bouton centré avec style moderne
            ElevatedButton.icon(
              onPressed: () => _openProductDialog(),
              icon: const Icon(Icons.add_circle_outline, size: 24),
              label: const Text(
                'Ajouter un produit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
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
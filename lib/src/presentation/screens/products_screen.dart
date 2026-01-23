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
          // Masquer le FAB quand il n'y a pas de produits (empty state)
          if (products.isEmpty && state.status != ProductStatus.loading) {
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun produit enregistré.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _openProductDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
          ),
        ],
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
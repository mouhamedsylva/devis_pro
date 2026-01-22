/// DashboardScreen – Accès rapide (Clients, Produits, Devis, Entreprise).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import 'clients_screen.dart';
import 'company_screen.dart';
import 'products_screen.dart';
import 'quotes_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _Tile(
              icon: Icons.people,
              title: 'Clients',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClientsScreen())),
            ),
            _Tile(
              icon: Icons.inventory_2,
              title: 'Produits/Services',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductsScreen())),
            ),
            _Tile(
              icon: Icons.receipt_long,
              title: 'Devis',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuotesScreen())),
            ),
            _Tile(
              icon: Icons.store,
              title: 'Entreprise',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}


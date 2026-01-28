/// DashboardScreen – Accès rapide avec statistiques et BottomNavigationBar.
import 'package:devis_pro/src/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/clients/client_bloc.dart';
import '../blocs/products/product_bloc.dart';
import '../blocs/quotes/quote_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/connectivity_service.dart';
import 'quote_editor_screen.dart';
import 'clients_screen.dart';
import 'company_screen.dart';
import 'products_screen.dart';
import 'quotes_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardData());
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const QuotesScreen();
      case 2:
        return const ClientsScreen();
      case 3:
        return const ProductsScreen();
      case 4:
        return const CompanyScreen();
      default:
        return _buildHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClientBloc, ClientState>(
          listenWhen: (p, c) => p.status != c.status && c.status == ClientStatus.loaded,
          listener: (context, state) => context.read<DashboardBloc>().add(LoadDashboardData()),
        ),
        BlocListener<ProductBloc, ProductState>(
          listenWhen: (p, c) => p.status != c.status && c.status == ProductStatus.loaded,
          listener: (context, state) => context.read<DashboardBloc>().add(LoadDashboardData()),
        ),
        BlocListener<QuoteBloc, QuoteState>(
          listenWhen: (p, c) => p.status != c.status && (c.status == QuoteStatus.loaded || c.status == QuoteStatus.success),
          listener: (context, state) => context.read<DashboardBloc>().add(LoadDashboardData()),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: _getCurrentScreen(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        int? totalClients;
        if (state is DashboardLoaded) {
          totalClients = state.totalClients;
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildNavItem(icon: Icons.home_rounded, label: 'Accueil', index: 0)),
                  Expanded(child: _buildNavItem(icon: Icons.receipt_long_rounded, label: 'Devis', index: 1)),
                  Expanded(child: _buildNavItem(icon: Icons.people_rounded, label: 'Clients', index: 2, badge: totalClients)),
                  Expanded(child: _buildNavItem(icon: Icons.inventory_2_rounded, label: 'Produits', index: 3)),
                  Expanded(child: _buildNavItem(icon: Icons.store_rounded, label: 'Entreprise', index: 4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int? badge,
    bool showBadge = false,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.yellow : const Color(0xFF999999);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
        builder: (context, value, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, AppColors.yellow.withOpacity(0.15), value),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.yellow.withOpacity(0.3 * value), blurRadius: 8 * value, offset: Offset(0, 2 * value))]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform.scale(
                      scale: 1.0 + (value * 0.15),
                      child: Transform.rotate(
                        angle: value * 0.1,
                        child: Icon(
                          icon,
                          color: Color.lerp(const Color(0xFF999999), AppColors.yellow, value),
                          size: 26,
                        ),
                      ),
                    ),
                    if (showBadge && badge != null)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFFFF5252), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(badge > 9 ? '9+' : badge.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isSelected ? 16 : 14,
                  margin: EdgeInsets.only(top: isSelected ? 6 : 4),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: Color.lerp(const Color(0xFF999999), AppColors.yellow, value),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: value * 0.5,
                    ),
                    child: Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardError) {
          return Center(child: Text(state.message));
        }
        if (state is DashboardLoaded) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildQuickStats(state),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildRecentActivity(state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        }
        return Container();
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.yellow, const Color(0xFFFFD700)]),
                      boxShadow: [BoxShadow(color: AppColors.yellow.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.description, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('DEVIS PRO', style: TextStyle(color: AppColors.yellow, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const Text('Tableau de bord', style: TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
                    child: IconButton(onPressed: () => _confirmLogout(context), icon: const Icon(Icons.logout_rounded, color: Color(0xFF666666), size: 22)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(DashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vue d\'ensemble', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(icon: Icons.people_rounded, value: state.totalClients.toString(), label: 'Clients')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(icon: Icons.inventory_2_rounded, value: state.totalProducts.toString(), label: 'Produits')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(icon: Icons.receipt_long_rounded, value: state.totalQuotes.toString(), label: 'Devis total')),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.note_add_rounded,
                  value: state.totalTemplates.toString(),
                  label: 'Modèles',
                  badgeText: 'LOCAL',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    bool showBadge = false,
    Color? backgroundColor,
    String? badgeText,
  }) {
    final effectiveContentColor = backgroundColor == Colors.blue ? Colors.white : const Color(0xFF1A1A1A);
    final effectiveSubColor = backgroundColor == Colors.blue ? Colors.white70 : const Color(0xFF666666);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor == Colors.blue ? Colors.white.withOpacity(0.2) : AppColors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(icon, color: backgroundColor == Colors.blue ? Colors.white : AppColors.yellow, size: 22),
              ),
              if (showBadge) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text(badgeText ?? '', style: TextStyle(color: backgroundColor ?? AppColors.yellow, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: effectiveContentColor, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: effectiveSubColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions rapides', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Nouveau devis',
                  color: AppColors.yellow,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const QuoteEditorScreen())).then((_) {
                      if (context.mounted) context.read<DashboardBloc>().add(LoadDashboardData());
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildQuickActionButton(icon: Icons.person_add_rounded, label: 'Ajouter client', color: const Color(0xFF4CAF50), onTap: () => _onItemTapped(2))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 22), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700))]),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(DashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activités récentes', style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  ).then((_) {
                    if (context.mounted) context.read<DashboardBloc>().add(LoadDashboardData());
                  });
                },
                child: Text('Voir tout', style: TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.recentActivities.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Center(child: Text('Aucune activité récente', style: TextStyle(color: Colors.grey[600], fontSize: 14, fontStyle: FontStyle.italic))),
            )
          else
            ...state.recentActivities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Padding(padding: EdgeInsets.only(bottom: index < state.recentActivities.length - 1 ? 10 : 0), child: _buildActivityItem(icon: activity.icon, title: activity.title, time: activity.timeAgo, color: activity.color));
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem({required IconData icon, required String title, required String time, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 3), Text(time, style: const TextStyle(color: Color(0xFF999999), fontSize: 12, fontWeight: FontWeight.w500))])),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: Colors.orange, size: 32)),
          const SizedBox(height: 16),
          const Text('Déconnexion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        ]),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter de votre compte ?', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black54)),
        actions: [
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Annuler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Se déconnecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
          ]),
        ],
      ),
    );
    if (confirmed == true && context.mounted) context.read<AuthBloc>().add(const AuthLogoutRequested());
  }
}

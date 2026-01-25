import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/quote.dart';
import '../../../domain/repositories/client_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/quote_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ClientRepository _clientRepository;
  final ProductRepository _productRepository;
  final QuoteRepository _quoteRepository;

  DashboardBloc({
    required ClientRepository clientRepository,
    required ProductRepository productRepository,
    required QuoteRepository quoteRepository,
  })  : _clientRepository = clientRepository,
        _productRepository = productRepository,
        _quoteRepository = quoteRepository,
        super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final totalClients = await _clientRepository.getClientsCount();
      final totalProducts = await _productRepository.getProductsCount();
      final totalQuotes = await _quoteRepository.getSyncedQuotesCount();
      final pendingQuotes = await _quoteRepository.getPendingQuotesCount();
      final monthlyRevenue = await _quoteRepository.getMonthlyRevenue();
      final monthlyPotential = await _quoteRepository.getMonthlyPotential();

      // Charger les activités récentes
      final recentActivities = await _loadRecentActivities();

      emit(DashboardLoaded(
        totalClients: totalClients,
        totalProducts: totalProducts,
        totalQuotes: totalQuotes,
        pendingQuotes: pendingQuotes,
        monthlyRevenue: monthlyRevenue,
        monthlyPotential: monthlyPotential,
        recentActivities: recentActivities,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  /// Charge les activités récentes (devis et clients) et les combine.
  Future<List<RecentActivity>> _loadRecentActivities() async {
    final activities = <RecentActivity>[];

    // Récupérer les 5 devis les plus récents
    final recentQuotes = await _quoteRepository.list();
    final quotes = recentQuotes.take(5).toList();

    for (final quote in quotes) {
      String title;
      IconData icon;
      Color color;

      switch (quote.status) {
        case 'Accepté':
          title = 'Devis ${quote.quoteNumber} accepté';
          icon = Icons.check_circle_rounded;
          color = const Color(0xFF4CAF50);
          break;
        case 'Envoyé':
          title = 'Devis ${quote.quoteNumber} envoyé';
          icon = Icons.send_rounded;
          color = const Color(0xFF2196F3);
          break;
        case 'Brouillon':
        default:
          title = 'Devis ${quote.quoteNumber} créé';
          icon = Icons.drafts_rounded;
          color = AppColors.yellow;
          break;
      }

      activities.add(RecentActivity(
        title: title,
        timeAgo: Formatters.timeAgo(quote.date),
        icon: icon,
        color: color,
        dateTime: quote.date,
      ));
    }

    // Récupérer les 3 clients les plus récents
    final recentClients = await _clientRepository.list();
    final clients = recentClients.take(3).toList();

    for (final client in clients) {
      activities.add(RecentActivity(
        title: 'Nouveau client ajouté: ${client.name}',
        timeAgo: Formatters.timeAgo(client.createdAt),
        icon: Icons.person_add_rounded,
        color: const Color(0xFF2196F3),
        dateTime: client.createdAt,
      ));
    }

    // Trier par date (plus récent en premier) et limiter à 5
    activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return activities.take(5).toList();
  }
}

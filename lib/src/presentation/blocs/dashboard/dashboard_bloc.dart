import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/activity_log.dart';
import '../../../domain/repositories/client_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/quote_repository.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../domain/repositories/template_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ClientRepository _clientRepository;
  final ProductRepository _productRepository;
  final QuoteRepository _quoteRepository;
  final ActivityRepository _activityRepository;
  final TemplateRepository _templateRepository;

  DashboardBloc({
    required ClientRepository clientRepository,
    required ProductRepository productRepository,
    required QuoteRepository quoteRepository,
    required ActivityRepository activityRepository,
    required TemplateRepository templateRepository,
  })  : _clientRepository = clientRepository,
        _productRepository = productRepository,
        _quoteRepository = quoteRepository,
        _activityRepository = activityRepository,
        _templateRepository = templateRepository,
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
      final totalQuotes = await _quoteRepository.getQuotesCount();
      final templates = await _templateRepository.getAllTemplates();
      final monthlyRevenue = await _quoteRepository.getMonthlyRevenue();
      final monthlyPotential = await _quoteRepository.getMonthlyPotential();

      // Charger les activités récentes (5 dernières)
      final logs = await _activityRepository.list(limit: 5);
      final recentActivities = logs.map((log) {
        return RecentActivity(
          title: log.action,
          timeAgo: Formatters.timeAgo(log.createdAt),
          icon: _getTypeIcon(log.type),
          color: _getTypeColor(log.type),
          dateTime: log.createdAt,
        );
      }).toList();

      emit(DashboardLoaded(
        totalClients: totalClients,
        totalProducts: totalProducts,
        totalQuotes: totalQuotes,
        totalTemplates: templates.length,
        monthlyRevenue: monthlyRevenue,
        monthlyPotential: monthlyPotential,
        recentActivities: recentActivities,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'quote': return Icons.description_rounded;
      case 'client': return Icons.person_rounded;
      case 'product': return Icons.inventory_2_rounded;
      case 'company': return Icons.store_rounded;
      case 'auth': return Icons.lock_rounded;
      default: return Icons.info_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'quote': return AppColors.yellow;
      case 'client': return Colors.blue;
      case 'product': return Colors.green;
      case 'company': return Colors.purple;
      case 'auth': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

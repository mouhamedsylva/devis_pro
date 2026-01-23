import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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
      final totalQuotes = await _quoteRepository.getQuotesCount();
      final pendingQuotes = await _quoteRepository.getPendingQuotesCount();
      final monthlyRevenue = await _quoteRepository.getMonthlyRevenue();

      emit(DashboardLoaded(
        totalClients: totalClients,
        totalProducts: totalProducts,
        totalQuotes: totalQuotes,
        pendingQuotes: pendingQuotes,
        monthlyRevenue: monthlyRevenue,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}

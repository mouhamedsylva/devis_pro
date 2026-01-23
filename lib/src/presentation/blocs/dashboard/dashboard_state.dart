part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalClients;
  final int totalProducts;
  final int totalQuotes;
  final int pendingQuotes;
  final double monthlyRevenue;

  const DashboardLoaded({
    required this.totalClients,
    required this.totalProducts,
    required this.totalQuotes,
    required this.pendingQuotes,
    required this.monthlyRevenue,
  });

  @override
  List<Object> get props => [
        totalClients,
        totalProducts,
        totalQuotes,
        pendingQuotes,
        monthlyRevenue,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}

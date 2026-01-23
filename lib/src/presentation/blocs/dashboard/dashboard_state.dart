part of 'dashboard_bloc.dart';

/// Représente une activité récente dans le dashboard.
class RecentActivity {
  final String title;
  final String timeAgo;
  final IconData icon;
  final Color color;
  final DateTime dateTime;

  const RecentActivity({
    required this.title,
    required this.timeAgo,
    required this.icon,
    required this.color,
    required this.dateTime,
  });
}

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
  final List<RecentActivity> recentActivities;

  const DashboardLoaded({
    required this.totalClients,
    required this.totalProducts,
    required this.totalQuotes,
    required this.pendingQuotes,
    required this.monthlyRevenue,
    required this.recentActivities,
  });

  @override
  List<Object> get props => [
        totalClients,
        totalProducts,
        totalQuotes,
        pendingQuotes,
        monthlyRevenue,
        recentActivities,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}

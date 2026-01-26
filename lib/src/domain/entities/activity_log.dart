import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  const ActivityLog({
    required this.id,
    required this.action,
    required this.details,
    required this.createdAt,
    required this.type, // 'quote', 'client', 'product', 'company', 'auth'
  });

  final int id;
  final String action;
  final String details;
  final DateTime createdAt;
  final String type;

  @override
  List<Object?> get props => [id, action, details, createdAt, type];
}

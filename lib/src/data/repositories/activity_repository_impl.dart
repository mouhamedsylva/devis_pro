import '../../domain/entities/activity_log.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/activity_log_model.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<ActivityLog>> list({int? limit}) async {
    final rows = await _db.database.query(
      'activity_logs',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map((row) => ActivityLogModel.fromMap(row)).toList();
  }

  @override
  Future<void> log({
    required String action,
    required String details,
    required String type,
  }) async {
    await _db.database.insert(
      'activity_logs',
      ActivityLogModel.toMap(action, details, type),
    );
  }

  @override
  Future<void> clear() async {
    await _db.database.delete('activity_logs');
  }
}

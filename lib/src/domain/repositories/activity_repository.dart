import '../entities/activity_log.dart';

abstract class ActivityRepository {
  Future<List<ActivityLog>> list({int? limit});
  Future<void> log({
    required String action,
    required String details,
    required String type,
  });
  Future<void> clear();
}

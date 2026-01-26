import '../../domain/entities/activity_log.dart';

class ActivityLogModel {
  static ActivityLog fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int,
      action: map['action'] as String,
      details: map['details'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      type: map['type'] as String,
    );
  }

  static Map<String, dynamic> toMap(String action, String details, String type) {
    return {
      'action': action,
      'details': details,
      'createdAt': DateTime.now().toIso8601String(),
      'type': type,
    };
  }
}

/// DTO SQLite <-> Entité Quote.
import '../../domain/entities/quote.dart';

class QuoteModel {
  static Quote fromMap(Map<String, Object?> map) {
    return Quote(
      id: map['id'] as int,
      quoteNumber: map['quoteNumber'] as String,
      clientId: map['clientId'] as int?,
      clientName: map['clientName'] as String?,
      clientPhone: map['clientPhone'] as String?,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      totalHT: (map['totalHT'] as num).toDouble(),
      totalVAT: (map['totalVAT'] as num).toDouble(),
      totalTTC: (map['totalTTC'] as num).toDouble(),
      isSynced: (map['is_synced'] as int?) == 1, // Default false/null handled by int? check, but here schema default is 1
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
      pendingSync: (map['pending_sync'] as int?) == 1,
    );
  }

  static Map<String, Object?> toMap(Quote quote) {
    return {
      'id': quote.id,
      'quoteNumber': quote.quoteNumber,
      'clientId': quote.clientId,
      'clientName': quote.clientName,
      'clientPhone': quote.clientPhone,
      'date': quote.date.toIso8601String(),
      'status': quote.status,
      'totalHT': quote.totalHT,
      'totalVAT': quote.totalVAT,
      'totalTTC': quote.totalTTC,
      'is_synced': quote.isSynced ? 1 : 0,
      'synced_at': quote.syncedAt?.toIso8601String(),
      'pending_sync': quote.pendingSync ? 1 : 0,
    };
  }
}


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
    };
  }
}

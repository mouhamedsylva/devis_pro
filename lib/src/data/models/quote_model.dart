/// DTO SQLite <-> Entité Quote.
import '../../domain/entities/quote.dart';

class QuoteModel {
  static Quote fromMap(Map<String, Object?> map) {
    return Quote(
      id: map['id'] as int,
      quoteNumber: map['quoteNumber'] as String,
      clientId: map['clientId'] as int,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      totalHT: (map['totalHT'] as num).toDouble(),
      totalVAT: (map['totalVAT'] as num).toDouble(),
      totalTTC: (map['totalTTC'] as num).toDouble(),
    );
  }
}


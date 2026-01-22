/// DTO SQLite <-> Entité QuoteItem.
import '../../domain/entities/quote_item.dart';

class QuoteItemModel {
  static QuoteItem fromMap(Map<String, Object?> map) {
    return QuoteItem(
      id: map['id'] as int,
      quoteId: map['quoteId'] as int,
      productName: map['productName'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      vatRate: (map['vatRate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}


/// Abstraction repository Devis + lignes.
import '../entities/quote.dart';
import '../entities/quote_item.dart';

abstract class QuoteRepository {
  Future<List<Quote>> list();
  Future<int> getQuotesCount();
  Future<double> getMonthlyRevenue();
  Future<double> getMonthlyPotential();
  Future<List<QuoteItem>> listItems(int quoteId);
  Future<Quote> createDraft({
    int? clientId,
    String? clientName,
    String? clientPhone,
    required DateTime date,
    required List<QuoteItemDraft> items,
    required String status,
  });
  Future<void> updateStatus({required int quoteId, required String status});
  Future<void> delete(int quoteId);
}

/// Draft (sans id) utilisé lors de la création d’un devis.
class QuoteItemDraft {
  const QuoteItemDraft({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.vatRate,
    this.unit,
  });

  final String productName;
  final double unitPrice;
  final double quantity;
  final double vatRate;
  final String? unit;
}

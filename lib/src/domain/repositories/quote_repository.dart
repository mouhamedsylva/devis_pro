/// Abstraction repository Devis + lignes.
import '../entities/quote.dart';
import '../entities/quote_item.dart';

abstract class QuoteRepository {
  Future<List<Quote>> list();
  Future<int> getQuotesCount();
  Future<int> getPendingQuotesCount();
  Future<double> getMonthlyRevenue();
  Future<List<QuoteItem>> listItems(int quoteId);
  Future<Quote> createDraft({
    required int clientId,
    required DateTime date,
    required List<QuoteItemDraft> items,
    required String status,
  });
  Future<void> updateStatus({required int quoteId, required String status});
}

/// Draft (sans id) utilisé lors de la création d’un devis.
class QuoteItemDraft {
  const QuoteItemDraft({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.vatRate,
  });

  final String productName;
  final double unitPrice;
  final double quantity;
  final double vatRate;
}


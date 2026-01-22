/// Impl SQLite du QuoteRepository (devis + items).
import '../../domain/entities/quote.dart';
import '../../domain/entities/quote_item.dart';
import '../../domain/repositories/quote_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/local/database_interface.dart';
import '../models/quote_item_model.dart';
import '../models/quote_model.dart';

class QuoteRepositoryImpl implements QuoteRepository {
  const QuoteRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Quote>> list() async {
    final rows = await _db.database.query('quotes', orderBy: 'id DESC');
    return rows.map(QuoteModel.fromMap).toList();
  }

  @override
  Future<List<QuoteItem>> listItems(int quoteId) async {
    final rows = await _db.database.query(
      'quote_items',
      where: 'quoteId = ?',
      whereArgs: [quoteId],
      orderBy: 'id ASC',
    );
    return rows.map(QuoteItemModel.fromMap).toList();
  }

  @override
  Future<Quote> createDraft({
    required int clientId,
    required DateTime date,
    required List<QuoteItemDraft> items,
    required String status,
  }) async {
    final db = _db.database;

    return db.transaction((txn) async {
      final quoteNumber = await _generateQuoteNumber(txn);

      double totalHT = 0;
      double totalVAT = 0;
      double totalTTC = 0;

      // Calculs.
      for (final it in items) {
        final lineHT = it.unitPrice * it.quantity;
        final lineVAT = lineHT * it.vatRate;
        totalHT += lineHT;
        totalVAT += lineVAT;
      }
      totalTTC = totalHT + totalVAT;

      final quoteId = await txn.insert('quotes', {
        'quoteNumber': quoteNumber,
        'clientId': clientId,
        'date': date.toIso8601String(),
        'status': status,
        'totalHT': totalHT,
        'totalVAT': totalVAT,
        'totalTTC': totalTTC,
      });

      for (final it in items) {
        final lineHT = it.unitPrice * it.quantity;
        final lineVAT = lineHT * it.vatRate;
        final lineTotal = lineHT + lineVAT;
        await txn.insert('quote_items', {
          'quoteId': quoteId,
          'productName': it.productName,
          'unitPrice': it.unitPrice,
          'quantity': it.quantity,
          'vatRate': it.vatRate,
          'total': lineTotal,
        });
      }

      final rows = await txn.query('quotes', where: 'id = ?', whereArgs: [quoteId], limit: 1);
      return QuoteModel.fromMap(rows.first);
    });
  }

  @override
  Future<void> updateStatus({required int quoteId, required String status}) async {
    await _db.database.update(
      'quotes',
      {'status': status},
      where: 'id = ?',
      whereArgs: [quoteId],
    );
  }

  Future<String> _generateQuoteNumber(DatabaseInterface db) async {
    // Format lisible: DV-YYYYMMDD-#### (auto incrément au jour)
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final prefix = 'DV-$y$m$d-';

    final rows = await db.rawQuery(
      'SELECT quoteNumber FROM quotes WHERE quoteNumber LIKE ? ORDER BY id DESC LIMIT 1',
      ['$prefix%'],
    );
    if (rows.isEmpty) return '${prefix}0001';

    final last = (rows.first['quoteNumber'] as String);
    final lastSeq = int.tryParse(last.split('-').last) ?? 0;
    final next = (lastSeq + 1).toString().padLeft(4, '0');
    return '$prefix$next';
  }
}


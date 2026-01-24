/// Entité ligne de devis.
import 'package:equatable/equatable.dart';

class QuoteItem extends Equatable {
  const QuoteItem({
    required this.id,
    required this.quoteId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.vatRate,
    this.unit,
    required this.total,
  });

  final int id;
  final int quoteId;
  final String productName;
  final double unitPrice;
  final double quantity;
  final double vatRate;
  final String? unit;
  final double total;

  @override
  List<Object?> get props => [id, quoteId, productName, unitPrice, quantity, vatRate, unit, total];
}


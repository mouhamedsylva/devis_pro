part of 'quote_bloc.dart';

sealed class QuoteEvent extends Equatable {
  const QuoteEvent();

  @override
  List<Object?> get props => [];
}

class QuoteListRequested extends QuoteEvent {
  const QuoteListRequested();
}

class QuoteCreateRequested extends QuoteEvent {
  const QuoteCreateRequested({
    this.clientId,
    this.clientName,
    this.clientPhone,
    required this.date,
    required this.items,
    required this.status,
  });

  final int? clientId;
  final String? clientName;
  final String? clientPhone;
  final DateTime date;
  final List<QuoteItemDraft> items;
  final String status;

  @override
  List<Object?> get props => [clientId, clientName, clientPhone, date, items, status];
}

class QuoteStatusUpdated extends QuoteEvent {
  const QuoteStatusUpdated({required this.quoteId, required this.status});

  final int quoteId;
  final String status;

  @override
  List<Object?> get props => [quoteId, status];
}

class QuoteDeleteRequested extends QuoteEvent {
  const QuoteDeleteRequested(this.quoteId);
  final int quoteId;

  @override
  List<Object?> get props => [quoteId];
}

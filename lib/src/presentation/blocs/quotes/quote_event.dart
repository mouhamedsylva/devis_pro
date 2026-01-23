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

  final int? clientId; // Nullable : si null, utiliser clientName et clientPhone
  final String? clientName; // Nom du client si pas de clientId
  final String? clientPhone; // Téléphone du client si pas de clientId
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


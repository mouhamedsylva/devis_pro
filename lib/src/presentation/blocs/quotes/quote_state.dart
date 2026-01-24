part of 'quote_bloc.dart';

class QuoteState extends Equatable {
  const QuoteState._({required this.status, this.quotes, this.createdQuote, this.message});

  const QuoteState.initial() : this._(status: QuoteStatus.initial);
  const QuoteState.loading() : this._(status: QuoteStatus.loading);
  const QuoteState.loaded(List<Quote> quotes) : this._(status: QuoteStatus.loaded, quotes: quotes);
  const QuoteState.success(Quote createdQuote) : this._(status: QuoteStatus.success, createdQuote: createdQuote);
  const QuoteState.failure(String message) : this._(status: QuoteStatus.failure, message: message);

  final QuoteStatus status;
  final List<Quote>? quotes;
  final Quote? createdQuote;
  final String? message;

  @override
  List<Object?> get props => [status, quotes, createdQuote, message];
}

enum QuoteStatus { initial, loading, loaded, success, failure }


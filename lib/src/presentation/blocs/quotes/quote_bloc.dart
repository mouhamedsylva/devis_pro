/// BLoC Quotes: listing + création brouillon + statut.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/quote.dart';
import '../../../domain/repositories/quote_repository.dart';

part 'quote_event.dart';
part 'quote_state.dart';

class QuoteBloc extends Bloc<QuoteEvent, QuoteState> {
  QuoteBloc({required QuoteRepository quoteRepository})
      : _quoteRepository = quoteRepository,
        super(const QuoteState.initial()) {
    on<QuoteListRequested>((event, emit) async {
      emit(const QuoteState.loading());
      try {
        final quotes = await _quoteRepository.list();
        emit(QuoteState.loaded(quotes));
      } catch (e) {
        emit(QuoteState.failure(e.toString()));
      }
    });

    on<QuoteCreateRequested>((event, emit) async {
      emit(const QuoteState.loading());
      try {
        final quote = await _quoteRepository.createDraft(
          clientId: event.clientId,
          clientName: event.clientName,
          clientPhone: event.clientPhone,
          date: event.date,
          items: event.items,
          status: event.status,
          isSynced: event.isSynced,
          pendingSync: event.pendingSync,
        );
        emit(QuoteState.success(quote));
        // On rafraîchit la liste en arrière-plan
        final quotes = await _quoteRepository.list();
        emit(QuoteState.loaded(quotes));
      } catch (e) {
        emit(QuoteState.failure(e.toString()));
      }
    });

    on<QuoteSyncPendingRequested>((event, emit) async {
      // Pour l'instant on ne fait rien, futur backend
      // On pourrait recharger la liste si nécessaire
      add(const QuoteListRequested());
    });

    on<QuoteStatusUpdated>((event, emit) async {
      try {
        await _quoteRepository.updateStatus(quoteId: event.quoteId, status: event.status);
        add(const QuoteListRequested());
      } catch (e) {
        emit(QuoteState.failure(e.toString()));
      }
    });
  }

  final QuoteRepository _quoteRepository;
}


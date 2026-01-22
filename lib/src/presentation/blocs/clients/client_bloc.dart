/// BLoC Clients: CRUD basique.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/client.dart';
import '../../../domain/repositories/client_repository.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  ClientBloc({required ClientRepository clientRepository})
      : _clientRepository = clientRepository,
        super(const ClientState.initial()) {
    on<ClientListRequested>((event, emit) async {
      emit(const ClientState.loading());
      try {
        final clients = await _clientRepository.list();
        emit(ClientState.loaded(clients));
      } catch (e) {
        emit(ClientState.failure(e.toString()));
      }
    });

    on<ClientCreateRequested>((event, emit) async {
      try {
        await _clientRepository.create(name: event.name, phone: event.phone, address: event.address);
        add(const ClientListRequested());
      } catch (e) {
        emit(ClientState.failure(e.toString()));
      }
    });

    on<ClientUpdateRequested>((event, emit) async {
      try {
        await _clientRepository.update(event.client);
        add(const ClientListRequested());
      } catch (e) {
        emit(ClientState.failure(e.toString()));
      }
    });

    on<ClientDeleteRequested>((event, emit) async {
      try {
        await _clientRepository.delete(event.id);
        add(const ClientListRequested());
      } catch (e) {
        emit(ClientState.failure(e.toString()));
      }
    });
  }

  final ClientRepository _clientRepository;
}


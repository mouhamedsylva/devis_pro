/// BLoC Clients: CRUD basique.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart'; // For more robust list manipulation

import '../../../domain/entities/client.dart';
import '../../../domain/repositories/client_repository.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientState> {
  ClientBloc({required ClientRepository clientRepository})
      : _clientRepository = clientRepository,
        super(const ClientState()) {
    on<ClientListRequested>(_onClientListRequested);
    on<ClientRefreshRequested>(_onClientRefreshRequested);
    on<ClientCreateRequested>(_onClientCreateRequested);
    on<ClientUpdateRequested>(_onClientUpdateRequested);
    on<ClientDeleteRequested>(_onClientDeleteRequested);
    on<ClientSearchTermChanged>(_onClientSearchTermChanged);
    on<ClientFilterChanged>(_onClientFilterChanged);
    on<ClientSortOrderChanged>(_onClientSortOrderChanged);
  }

  final ClientRepository _clientRepository;

  Future<void> _onClientListRequested(
    ClientListRequested event,
    Emitter<ClientState> emit,
  ) async {
    emit(state.copyWith(status: ClientStatus.loading));
    try {
      final allClients = await _clientRepository.list();
      emit(state.copyWith(
        status: ClientStatus.loaded,
        allClients: allClients,
        clients: await _applySearchFilterSort(allClients, state.searchTerm, state.filterOption, state.sortOrder),
      ));
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onClientRefreshRequested(
    ClientRefreshRequested event,
    Emitter<ClientState> emit,
  ) async {
    add(const ClientListRequested());
  }

  Future<void> _onClientCreateRequested(
    ClientCreateRequested event,
    Emitter<ClientState> emit,
  ) async {
    try {
      await _clientRepository.create(name: event.name, phone: event.phone, address: event.address);
      add(const ClientRefreshRequested());
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onClientUpdateRequested(
    ClientUpdateRequested event,
    Emitter<ClientState> emit,
  ) async {
    try {
      await _clientRepository.update(event.client);
      add(const ClientRefreshRequested());
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onClientDeleteRequested(
    ClientDeleteRequested event,
    Emitter<ClientState> emit,
  ) async {
    try {
      await _clientRepository.delete(event.id);
      add(const ClientRefreshRequested());
    } catch (e) {
      emit(state.copyWith(status: ClientStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onClientSearchTermChanged(
    ClientSearchTermChanged event,
    Emitter<ClientState> emit,
  ) async {
    emit(state.copyWith(
      searchTerm: event.searchTerm,
      clients: await _applySearchFilterSort(state.allClients, event.searchTerm, state.filterOption, state.sortOrder),
    ));
  }

  Future<void> _onClientFilterChanged(
    ClientFilterChanged event,
    Emitter<ClientState> emit,
  ) async {
    emit(state.copyWith(
      filterOption: event.filterOption,
      clients: await _applySearchFilterSort(state.allClients, state.searchTerm, event.filterOption, state.sortOrder),
    ));
  }

  Future<void> _onClientSortOrderChanged(
    ClientSortOrderChanged event,
    Emitter<ClientState> emit,
  ) async {
    emit(state.copyWith(
      sortOrder: event.sortOrder,
      clients: await _applySearchFilterSort(state.allClients, state.searchTerm, state.filterOption, event.sortOrder),
    ));
  }

  Future<List<Client>> _applySearchFilterSort(
    List<Client> rawClients,
    String searchTerm,
    ClientFilterOption filterOption,
    ClientSortOrder sortOrder,
  ) async {
    List<Client> workingList = List.from(rawClients);

    // Apply Search
    if (searchTerm.isNotEmpty) {
      workingList = workingList.where((client) {
        final lowerCaseSearchTerm = searchTerm.toLowerCase();
        return client.name.toLowerCase().contains(lowerCaseSearchTerm) ||
               client.phone.toLowerCase().contains(lowerCaseSearchTerm) ||
               client.address.toLowerCase().contains(lowerCaseSearchTerm);
      }).toList();
    }

    // Apply Filter
    switch (filterOption) {
      case ClientFilterOption.all:
        break;
      case ClientFilterOption.hasQuotes:
        List<Client> clientsWithQuotes = [];
        for (var client in workingList) {
          if (await _clientRepository.clientHasQuotes(client.id)) {
            clientsWithQuotes.add(client);
          }
        }
        workingList = clientsWithQuotes;
        break;
      case ClientFilterOption.noQuotes:
        List<Client> clientsWithoutQuotes = [];
        for (var client in workingList) {
          if (!await _clientRepository.clientHasQuotes(client.id)) {
            clientsWithoutQuotes.add(client);
          }
        }
        workingList = clientsWithoutQuotes;
        break;
    }

    // Apply Sort
    switch (sortOrder) {
      case ClientSortOrder.nameAsc:
        workingList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ClientSortOrder.nameDesc:
        workingList.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ClientSortOrder.dateCreatedAsc:
        workingList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ClientSortOrder.dateCreatedDesc:
        workingList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return workingList;
  }
}


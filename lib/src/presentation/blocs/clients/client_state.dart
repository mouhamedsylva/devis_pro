part of 'client_bloc.dart';

class ClientState extends Equatable {
  const ClientState({
    this.status = ClientStatus.initial,
    this.clients = const <Client>[],
    this.allClients = const <Client>[], // Keep a copy of all clients
    this.message,
    this.searchTerm = '',
    this.filterOption = ClientFilterOption.all,
    this.sortOrder = ClientSortOrder.nameAsc,
  });

  final ClientStatus status;
  final List<Client> clients;
  final List<Client> allClients;
  final String? message;
  final String searchTerm;
  final ClientFilterOption filterOption;
  final ClientSortOrder sortOrder;

  ClientState copyWith({
    ClientStatus? status,
    List<Client>? clients,
    List<Client>? allClients,
    String? message,
    String? searchTerm,
    ClientFilterOption? filterOption,
    ClientSortOrder? sortOrder,
  }) {
    return ClientState(
      status: status ?? this.status,
      clients: clients ?? this.clients,
      allClients: allClients ?? this.allClients,
      message: message,
      searchTerm: searchTerm ?? this.searchTerm,
      filterOption: filterOption ?? this.filterOption,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        status,
        clients,
        allClients,
        message,
        searchTerm,
        filterOption,
        sortOrder,
      ];
}

enum ClientStatus { initial, loading, loaded, failure }



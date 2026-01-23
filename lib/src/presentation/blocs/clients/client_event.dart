part of 'client_bloc.dart';

sealed class ClientEvent extends Equatable {
  const ClientEvent();

  @override
  List<Object?> get props => [];
}

class ClientListRequested extends ClientEvent {
  const ClientListRequested();
}

class ClientRefreshRequested extends ClientEvent {
  const ClientRefreshRequested();
}

class ClientCreateRequested extends ClientEvent {
  const ClientCreateRequested({required this.name, required this.phone, required this.address});

  final String name;
  final String phone;
  final String address;

  @override
  List<Object?> get props => [name, phone, address];
}

class ClientUpdateRequested extends ClientEvent {
  const ClientUpdateRequested(this.client);

  final Client client;

  @override
  List<Object?> get props => [client];
}

class ClientDeleteRequested extends ClientEvent {
  const ClientDeleteRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class ClientSearchTermChanged extends ClientEvent {
  const ClientSearchTermChanged(this.searchTerm);

  final String searchTerm;

  @override
  List<Object?> get props => [searchTerm];
}

enum ClientFilterOption {
  all,
  hasQuotes,
  noQuotes,
}

class ClientFilterChanged extends ClientEvent {
  const ClientFilterChanged(this.filterOption);

  final ClientFilterOption filterOption;

  @override
  List<Object?> get props => [filterOption];
}

enum ClientSortOrder {
  nameAsc,
  nameDesc,
  dateCreatedAsc,
  dateCreatedDesc,
}

class ClientSortOrderChanged extends ClientEvent {
  const ClientSortOrderChanged(this.sortOrder);

  final ClientSortOrder sortOrder;

  @override
  List<Object?> get props => [sortOrder];
}



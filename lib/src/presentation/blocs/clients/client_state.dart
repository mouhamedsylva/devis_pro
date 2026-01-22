part of 'client_bloc.dart';

class ClientState extends Equatable {
  const ClientState._({required this.status, this.clients, this.message});

  const ClientState.initial() : this._(status: ClientStatus.initial);
  const ClientState.loading() : this._(status: ClientStatus.loading);
  const ClientState.loaded(List<Client> clients) : this._(status: ClientStatus.loaded, clients: clients);
  const ClientState.failure(String message) : this._(status: ClientStatus.failure, message: message);

  final ClientStatus status;
  final List<Client>? clients;
  final String? message;

  @override
  List<Object?> get props => [status, clients, message];
}

enum ClientStatus { initial, loading, loaded, failure }


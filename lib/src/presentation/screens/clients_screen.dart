/// ClientsScreen – liste + ajout/modif/suppression (MVP).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/client.dart';
import '../blocs/clients/client_bloc.dart';
import '../widgets/app_text_field.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(const ClientListRequested());
    _searchController.addListener(() {
      context.read<ClientBloc>().add(ClientSearchTermChanged(_searchController.text));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: BlocBuilder<ClientBloc, ClientState>(
          builder: (context, state) {
            return TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                border: InputBorder.none,
                filled: false,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
              onChanged: (searchTerm) {
                // Event dispatched via listener, no need to dispatch here.
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSortOptions(context);
            },
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, state) {
          // Masquer le FAB quand il n'y a pas de clients (empty state)
          if (state.clients.isEmpty && state.status != ClientStatus.loading) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => _openClientDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          );
        },
      ),
      body: BlocConsumer<ClientBloc, ClientState>(
        listenWhen: (p, c) => c.status == ClientStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          if (state.status == ClientStatus.loading) {
            return _buildLoadingSkeleton();
          }
          final clients = state.clients;
          if (clients.isEmpty) {
            return _buildEmptyState(context, state.searchTerm);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: clients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = clients[i];
              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _confirmDelete(c);
                },
                child: ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${c.phone}\n${c.address}'),
                  isThreeLine: true,
                  // Trailing IconButton is removed as swipe-to-delete is implemented
                  onTap: () => _openClientDialog(existing: c),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return BlocBuilder<ClientBloc, ClientState>(
          builder: (context, state) {
            return Wrap(
              children: <Widget>[
                ListTile(
                  title: const Text('Filtrer par'),
                  tileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                RadioListTile<ClientFilterOption>(
                  title: const Text('Tous les clients'),
                  value: ClientFilterOption.all,
                  groupValue: state.filterOption,
                  onChanged: (ClientFilterOption? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientFilterChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ClientFilterOption>(
                  title: const Text('Clients avec devis'),
                  value: ClientFilterOption.hasQuotes,
                  groupValue: state.filterOption,
                  onChanged: (ClientFilterOption? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientFilterChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ClientFilterOption>(
                  title: const Text('Clients sans devis'),
                  value: ClientFilterOption.noQuotes,
                  groupValue: state.filterOption,
                  onChanged: (ClientFilterOption? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientFilterChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Trier par'),
                  tileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                RadioListTile<ClientSortOrder>(
                  title: const Text('Nom (A-Z)'),
                  value: ClientSortOrder.nameAsc,
                  groupValue: state.sortOrder,
                  onChanged: (ClientSortOrder? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientSortOrderChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ClientSortOrder>(
                  title: const Text('Nom (Z-A)'),
                  value: ClientSortOrder.nameDesc,
                  groupValue: state.sortOrder,
                  onChanged: (ClientSortOrder? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientSortOrderChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ClientSortOrder>(
                  title: const Text('Date de création (asc.)'),
                  value: ClientSortOrder.dateCreatedAsc,
                  groupValue: state.sortOrder,
                  onChanged: (ClientSortOrder? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientSortOrderChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<ClientSortOrder>(
                  title: const Text('Date de création (desc.)'),
                  value: ClientSortOrder.dateCreatedDesc,
                  groupValue: state.sortOrder,
                  onChanged: (ClientSortOrder? value) {
                    if (value != null) {
                      context.read<ClientBloc>().add(ClientSortOrderChanged(value));
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(Client client) async {
    final bloc = context.read<ClientBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${client.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(ClientDeleteRequested(client.id));
      return true; // Indicate that the item was dismissed
    }
    return false; // Indicate that the item was not dismissed
  }

  Future<void> _openClientDialog({Client? existing}) async {
    final bloc = context.read<ClientBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Nouveau client' : 'Modifier client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: nameCtrl, label: 'Nom'),
              const SizedBox(height: 10),
              AppTextField(controller: phoneCtrl, label: 'Téléphone', keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              AppTextField(controller: addressCtrl, label: 'Adresse'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer')),
        ],
      ),
    );

    if (saved == true) {
      final name = nameCtrl.text.trim();
      final phone = phoneCtrl.text.trim();
      final address = addressCtrl.text.trim();
      if (name.isEmpty) return;
      if (existing == null) {
        bloc.add(ClientCreateRequested(name: name, phone: phone, address: address));
      } else {
        bloc.add(
          ClientUpdateRequested(
            Client(id: existing.id, name: name, phone: phone, address: address, createdAt: existing.createdAt),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, String searchTerm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo DEVISPRO (même style que dashboard)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFDB913),
                  Color(0xFFFFD700),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF9B000).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.description,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            searchTerm.isEmpty ? 'Aucun client enregistré.' : 'Aucun client trouvé pour "$searchTerm".',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          if (searchTerm.isEmpty)
            ElevatedButton.icon(
              onPressed: () => _openClientDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un client'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 5, // Show 5 skeleton items
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
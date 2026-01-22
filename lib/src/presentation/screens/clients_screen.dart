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
  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(const ClientListRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClientDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: BlocConsumer<ClientBloc, ClientState>(
        listenWhen: (p, c) => c.status == ClientStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          if (state.status == ClientStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final clients = state.clients ?? const <Client>[];
          if (clients.isEmpty) {
            return const Center(child: Text('Aucun client. Ajoutez votre premier client.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: clients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = clients[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${c.phone}\n${c.address}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(c),
                ),
                onTap: () => _openClientDialog(existing: c),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Client client) async {
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
    }
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
            Client(id: existing.id, name: name, phone: phone, address: address),
          ),
        );
      }
    }
  }
}


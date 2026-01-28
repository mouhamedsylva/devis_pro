/// ClientsScreen – liste + ajout/modif/suppression (MVP).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/client.dart';
import '../blocs/clients/client_bloc.dart';
import '../widgets/app_text_field.dart';
import '../widgets/confirmation_dialog.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

  Future<void> _importFromContacts() async {
    final bloc = context.read<ClientBloc>();
    
    if (await FlutterContacts.requestPermission(readonly: true)) {
      final contact = await FlutterContacts.openExternalPick();
      
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);
        
        if (fullContact != null) {
          final String name = fullContact.displayName;
          final String phone = fullContact.phones.isNotEmpty 
              ? fullContact.phones.first.number 
              : '';
              
          if (name.isNotEmpty) {
            bloc.add(ClientCreateRequested(
              name: name,
              phone: phone,
              address: '',
            ));
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Client "$name" importé avec succès'),
                  backgroundColor: AppColors.yellow,
                ),
              );
            }
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accès aux contacts refusée')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: TextField(
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Importer de mes contacts',
            onPressed: _importFromContacts,
          ),
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
          if (state.clients.isEmpty && state.status != ClientStatus.loading) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFDB913),
                  Color(0xFFFFD700),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _openClientDialog(),
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Nouveau Client',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = clients[i];
              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) async {
                  return await _confirmDelete(c);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded, color: AppColors.yellow, size: 24),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              c.phone,
                              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        if (c.address.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.address,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    onTap: () => _openClientDialog(existing: c),
                  ),
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
      builder: (_) => ConfirmationDialog(
        title: 'Supprimer',
        content: 'Voulez-vous vraiment supprimer le client "${client.name}" ?',
        confirmText: 'Supprimer',
        confirmColor: Colors.red,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (ok == true) {
      bloc.add(ClientDeleteRequested(client.id));
      return true;
    }
    return false;
  }

  Future<void> _openClientDialog({Client? existing}) async {
    final bloc = context.read<ClientBloc>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.yellow, AppColors.yellow.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        existing == null ? Icons.person_add_rounded : Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        existing == null ? 'Nouveau client' : 'Modifier client',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom
                      _buildInputField(
                        controller: nameCtrl,
                        label: 'Nom complet',
                        hint: 'Ex: Amadou Diallo',
                        icon: Icons.person_outline_rounded,
                        validator: _validateName,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 20),

                      // Téléphone
                      _buildInputField(
                        controller: phoneCtrl,
                        label: 'Téléphone',
                        hint: '77 123 45 67',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Adresse
                      _buildInputField(
                        controller: addressCtrl,
                        label: 'Adresse (optionnel)',
                        hint: 'Ex: Pikine, Dakar',
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: _validateAddress,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(dialogContext, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.yellow,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      final name = nameCtrl.text.trim();
      final phone = phoneCtrl.text.trim();
      final address = addressCtrl.text.trim();
      if (existing == null) {
        bloc.add(ClientCreateRequested(name: name, phone: phone, address: address));
      } else {
        bloc.add(
          ClientUpdateRequested(
            Client(
              id: existing.id,
              name: name,
              phone: phone,
              address: address,
              createdAt: existing.createdAt,
            ),
          ),
        );
      }
    }
  }

  // ========== VALIDATEURS ==========

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    
    final trimmed = value.trim();
    
    // Vérifier la longueur minimale
    if (trimmed.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    
    // Vérifier la longueur maximale
    if (trimmed.length > 50) {
      return 'Le nom ne peut pas dépasser 50 caractères';
    }
    
    // Vérifier les caractères valides (lettres, espaces, tirets, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Le nom ne peut contenir que des lettres';
    }
    
    // Vérifier qu'il n'y a pas que des espaces
    if (trimmed.replaceAll(' ', '').isEmpty) {
      return 'Le nom ne peut pas être vide';
    }
    
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le téléphone est requis';
    }
    
    // Nettoyer le numéro (enlever espaces, tirets, etc.)
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Vérifier la longueur minimale
    if (cleaned.length < 9) {
      return 'Le numéro doit contenir au moins 9 chiffres';
    }
    
    // Vérifier la longueur maximale
    if (cleaned.length > 13) {
      return 'Le numéro ne peut pas dépasser 13 chiffres';
    }
    
    // Validation spécifique pour le Sénégal (si nécessaire)
    // Les numéros sénégalais commencent généralement par 77, 78, 76, 75, 70, 33
    final senegalPrefixes = ['77', '78', '76', '75', '70', '33'];
    final hasValidPrefix = senegalPrefixes.any((prefix) => cleaned.startsWith(prefix));
    
    if (cleaned.length == 9 && !hasValidPrefix) {
      return 'Numéro invalide (doit commencer par 77, 78, 76, 75, 70 ou 33)';
    }
    
    return null;
  }

  String? _validateAddress(String? value) {
    // L'adresse est optionnelle
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    
    final trimmed = value.trim();
    
    // Vérifier la longueur minimale si renseignée
    if (trimmed.length < 3) {
      return 'L\'adresse doit contenir au moins 3 caractères';
    }
    
    // Vérifier la longueur maximale
    if (trimmed.length > 200) {
      return 'L\'adresse ne peut pas dépasser 200 caractères';
    }
    
    return null;
  }

  // ========== WIDGET BUILDER ==========

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (validator != null && label.contains('optionnel') == false)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 16),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppColors.yellow, size: 22),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.yellow, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  } 

  Widget _buildEmptyState(BuildContext context, String searchTerm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFDB913),
                    Color(0xFFFFD700),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _openClientDialog(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Nouveau Client',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
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

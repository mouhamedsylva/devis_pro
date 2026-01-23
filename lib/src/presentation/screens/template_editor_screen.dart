import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/template.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../blocs/template/template_state.dart';

/// Écran de création d'un template personnalisé.
class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({super.key});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _validityCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  String _category = 'BTP';
  final List<_EditableTemplateItem> _items = [];

  bool _submitted = false;

  static const _categories = <String>[
    'BTP',
    'IT',
    'Consulting',
    'Commerce',
    'Service',
    'Autre',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _validityCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addOrEditItem({_EditableTemplateItem? existing, int? index}) async {
    final result = await showDialog<_EditableTemplateItem>(
      context: context,
      builder: (dialogContext) {
        return _TemplateItemDialog(
          initial: existing,
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      if (existing != null && index != null) {
        _items[index] = result;
      } else {
        _items.add(result);
      }
    });
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _submit() {
    setState(() => _submitted = true);

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un article au modèle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
    final terms = _termsCtrl.text.trim().isEmpty ? null : _termsCtrl.text.trim();
    final validityDays = int.tryParse(_validityCtrl.text.trim());

    final template = QuoteTemplate(
      id: 0,
      name: name,
      description: description,
      category: _category,
      isCustom: true,
      createdAt: DateTime.now(),
      notes: notes,
      validityDays: validityDays,
      termsAndConditions: terms,
    );

    final items = _items.asMap().entries.map((entry) {
      final displayOrder = entry.key + 1;
      final it = entry.value;
      return TemplateItem(
        id: 0,
        templateId: 0,
        productName: it.productName,
        description: it.description,
        quantity: it.quantity,
        unitPrice: it.unitPrice,
        vatRate: it.vatRate,
        displayOrder: displayOrder,
      );
    }).toList();

    context.read<TemplateBloc>().add(TemplateCreate(template, items));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateBloc, TemplateState>(
      listener: (context, state) {
        if (state is TemplateCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
        if (state is TemplateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Nouveau modèle'),
          actions: [
            BlocBuilder<TemplateBloc, TemplateState>(
              builder: (context, state) {
                final loading = state is TemplateLoading;
                return TextButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(
                  title: 'Informations',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nom du modèle *',
                          hintText: 'Ex: Devis Rénovation Appartement',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) {
                          if (!_submitted) return null;
                          if (v == null || v.trim().isEmpty) return 'Le nom est requis';
                          if (v.trim().length < 3) return 'Minimum 3 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          hintText: 'Décrivez brièvement ce modèle',
                          prefixIcon: Icon(Icons.subject),
                        ),
                        maxLines: 2,
                        validator: (v) {
                          if (!_submitted) return null;
                          if (v == null || v.trim().isEmpty) return 'La description est requise';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Articles / Services',
                  trailing: ElevatedButton.icon(
                    onPressed: () => _addOrEditItem(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  child: _items.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('Ajoutez au moins un article pour ce modèle.'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < _items.length; i++) ...[
                              _itemTile(
                                index: i,
                                item: _items[i],
                              ),
                              if (i != _items.length - 1) const Divider(height: 1),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  title: 'Options (facultatif)',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _validityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Validité (jours)',
                          hintText: 'Ex: 30',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Notes affichées sur le devis',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _termsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Conditions générales',
                          hintText: 'Conditions par défaut',
                          prefixIcon: Icon(Icons.gavel),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<TemplateBloc, TemplateState>(
                  builder: (context, state) {
                    final loading = state is TemplateLoading;
                    return ElevatedButton.icon(
                      onPressed: loading ? null : _submit,
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(loading ? 'Enregistrement...' : 'Enregistrer le modèle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemTile({required int index, required _EditableTemplateItem item}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} FCFA • TVA ${(item.vatRate * 100).toStringAsFixed(0)}%',
      ),
      trailing: Wrap(
        spacing: 6,
        children: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _addOrEditItem(existing: item, index: index),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteItem(index),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EditableTemplateItem {
  const _EditableTemplateItem({
    required this.productName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
  });

  final String productName;
  final String description;
  final int quantity;
  final double unitPrice;
  final double vatRate; // 0.18
}

class _TemplateItemDialog extends StatefulWidget {
  const _TemplateItemDialog({required this.initial});

  final _EditableTemplateItem? initial;

  @override
  State<_TemplateItemDialog> createState() => _TemplateItemDialogState();
}

class _TemplateItemDialogState extends State<_TemplateItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _vatCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.productName ?? '');
    _descCtrl = TextEditingController(text: init?.description ?? '');
    _qtyCtrl = TextEditingController(text: (init?.quantity ?? 1).toString());
    _priceCtrl = TextEditingController(text: (init?.unitPrice ?? 0).toStringAsFixed(0));
    _vatCtrl = TextEditingController(text: ((init?.vatRate ?? 0.18) * 100).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _vatCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final unitPrice = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final vatPercent = double.tryParse(_vatCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final vatRate = vatPercent / 100.0;

    Navigator.pop(
      context,
      _EditableTemplateItem(
        productName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        quantity: qty,
        unitPrice: unitPrice,
        vatRate: vatRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Ajouter un article' : 'Modifier l’article'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Désignation *',
                  hintText: 'Ex: Installation, Prestation...',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Qté *'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return '>= 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'PU (FCFA) *'),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                        if (n == null || n < 0) return 'Invalide';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _vatCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'TVA (%)'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n < 0 || n > 100) return '0-100';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: Colors.white),
          child: const Text('OK'),
        ),
      ],
    );
  }
}


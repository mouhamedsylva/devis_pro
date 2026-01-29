import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/template.dart';
import '../blocs/template/template_bloc.dart';
import '../blocs/template/template_event.dart';
import '../blocs/template/template_state.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/app_scaffold.dart';

/// Écran de création d'un template personnalisé.
class TemplateEditorScreen extends StatefulWidget {
  final QuoteTemplate? initialTemplate;
  final List<TemplateItem>? initialItems;

  const TemplateEditorScreen({
    super.key,
    this.initialTemplate,
    this.initialItems,
  });

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _validityCtrl;
  late TextEditingController _termsCtrl;

  String _category = 'BTP';
  final List<_EditableTemplateItem> _items = [];

  bool _submitted = false;

  final List<String> _categories = [
    'BTP',
    'Construction',
    'IT',
    'Consulting',
    'Commerce',
    'Service',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTemplate;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _validityCtrl = TextEditingController(text: t?.validityDays?.toString() ?? '');
    _termsCtrl = TextEditingController(text: t?.termsAndConditions ?? '');
    _category = t?.category ?? 'BTP';

    if (widget.initialItems != null) {
      for (final item in widget.initialItems!) {
        _items.add(_EditableTemplateItem(
          productName: item.productName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          vatRate: item.vatRate,
          unit: item.unit,
        ));
      }
    }
  }

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

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Veuillez ajouter au moins un article')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final template = QuoteTemplate(
      id: widget.initialTemplate?.id ?? 0,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      isCustom: true,
      createdAt: widget.initialTemplate?.createdAt ?? DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      validityDays: int.tryParse(_validityCtrl.text.trim()),
      termsAndConditions: _termsCtrl.text.trim().isEmpty ? null : _termsCtrl.text.trim(),
    );

    final items = _items.asMap().entries.map((entry) {
      final displayOrder = entry.key + 1;
      final it = entry.value;
      return TemplateItem(
        id: 0,
        templateId: template.id,
        productName: it.productName,
        description: it.description,
        quantity: it.quantity,
        unitPrice: it.unitPrice,
        vatRate: it.vatRate,
        displayOrder: displayOrder,
        unit: it.unit,
      );
    }).toList();

    if (widget.initialTemplate != null) {
      context.read<TemplateBloc>().add(TemplateUpdate(template, items));
    } else {
      context.read<TemplateBloc>().add(TemplateCreate(template, items));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateBloc, TemplateState>(
      listener: (context, state) {
        if (state is TemplateCreated || state is TemplateUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Modèle enregistré avec succès')),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is TemplateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: AppScaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          title: Text(
            widget.initialTemplate == null ? 'Nouveau modèle' : 'Modifier modèle',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Enregistrer'),
                onPressed: _submit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.yellow,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SECTION INFORMATIONS
                _buildSectionHeader(
                  icon: Icons.info_outline,
                  title: 'Informations générales',
                  subtitle: 'Définissez les détails de votre modèle',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Nom du modèle',
                        hint: 'Ex: Devis type construction',
                        icon: Icons.edit_note,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descCtrl,
                        label: 'Description',
                        hint: 'Décrivez brièvement ce modèle',
                        icon: Icons.description_outlined,
                        maxLines: 2,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // SECTION ARTICLES
                _buildSectionHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'Articles / Services',
                  subtitle: 'Ajoutez les lignes de votre devis',
                ),
                const SizedBox(height: 12),
                
                if (_items.isEmpty)
                  _buildEmptyState()
                else
                  ..._items.asMap().entries.map((entry) => _buildItemCard(entry.key, entry.value)),

                const SizedBox(height: 16),
                _buildAddItemButton(),

                const SizedBox(height: 32),

                // SECTION OPTIONS
                _buildSectionHeader(
                  icon: Icons.tune,
                  title: 'Options supplémentaires',
                  subtitle: 'Paramètres avancés (optionnel)',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _validityCtrl,
                        label: 'Validité (jours)',
                        hint: '30',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _notesCtrl,
                        label: 'Notes par défaut',
                        hint: 'Informations complémentaires',
                        icon: Icons.note_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _termsCtrl,
                        label: 'Conditions générales',
                        hint: 'Termes et conditions',
                        icon: Icons.gavel_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // BOUTON PRINCIPAL
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.yellow, AppColors.yellow.withOpacity(0.8)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'ENREGISTRER LE MODÈLE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.yellow, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.yellow),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: InputDecoration(
        labelText: 'Catégorie',
        prefixIcon: Icon(Icons.category_outlined, color: AppColors.yellow),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.yellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _categories.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text(c),
        );
      }).toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun article ajouté',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par ajouter des articles à votre modèle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton() {
    return InkWell(
      onTap: () => _addOrEditItem(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.yellow, width: 2, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.yellow),
            const SizedBox(width: 8),
            Text(
              'Ajouter un article',
              style: TextStyle(
                color: AppColors.yellow,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, _EditableTemplateItem item) {
    final total = item.quantity * item.unitPrice;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _addOrEditItem(existing: item, index: index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.yellow,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _deleteItem(index),
                      color: Colors.red[400],
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.tag,
                          label: 'Quantité',
                          value: '${item.quantity} ${item.unit ?? ''}',
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.payments_outlined,
                          label: 'Prix unit.',
                          value: '${item.unitPrice.toStringAsFixed(0)} FCFA',
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.calculate_outlined,
                          label: 'Total',
                          value: '${total.toStringAsFixed(0)} FCFA',
                          isHighlighted: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: isHighlighted ? AppColors.yellow : Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? AppColors.yellow : Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EditableTemplateItem {
  final String productName;
  final String description;
  final int quantity;
  final double unitPrice;
  final double vatRate;
  final String? unit;

  const _EditableTemplateItem({
    required this.productName,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    this.unit,
  });
}

class _TemplateItemDialog extends StatefulWidget {
  final _EditableTemplateItem? initial;
  const _TemplateItemDialog({this.initial});

  @override
  State<_TemplateItemDialog> createState() => _TemplateItemDialogState();
}

class _TemplateItemDialogState extends State<_TemplateItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _unitCtrl;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _nameCtrl = TextEditingController(text: init?.productName ?? '');
    _descCtrl = TextEditingController(text: init?.description ?? '');
    _qtyCtrl = TextEditingController(text: (init?.quantity ?? 1).toString());
    _priceCtrl = TextEditingController(text: (init?.unitPrice ?? 0).toStringAsFixed(0));
    _vatCtrl = TextEditingController(text: ((init?.vatRate ?? 0.18) * 100).toStringAsFixed(0));
    _unitCtrl = TextEditingController(text: init?.unit ?? 'Unité');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _vatCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.initial == null ? Icons.add_shopping_cart : Icons.edit,
                          color: AppColors.yellow,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.initial == null ? 'Nouvel article' : 'Modifier l\'article',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Remplissez les informations',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDialogTextField(
                    controller: _nameCtrl,
                    label: 'Désignation *',
                    icon: Icons.shopping_bag_outlined,
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: _descCtrl,
                    label: 'Description',
                    icon: Icons.description_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogTextField(
                          controller: _qtyCtrl,
                          label: 'Quantité',
                          icon: Icons.tag,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogTextField(
                          controller: _unitCtrl,
                          label: 'Unité',
                          icon: Icons.square_foot,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogTextField(
                          controller: _priceCtrl,
                          label: 'Prix unitaire',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogTextField(
                          controller: _vatCtrl,
                          label: 'TVA (%)',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(
                              context,
                              _EditableTemplateItem(
                                productName: _nameCtrl.text,
                                description: _descCtrl.text,
                                quantity: int.tryParse(_qtyCtrl.text) ?? 1,
                                unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
                                vatRate: (double.tryParse(_vatCtrl.text) ?? 0) / 100,
                                unit: _unitCtrl.text,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirmer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.yellow, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
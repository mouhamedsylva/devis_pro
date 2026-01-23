/// CompanyScreen – paramètres entreprise avec design moderne et upload logo.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/company.dart';
import '../blocs/company/company_bloc.dart';
import '../widgets/app_text_field.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'FCFA');
  final _vatCtrl = TextEditingController(text: '18');
  
  String? _selectedLogoPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<CompanyBloc>().add(const CompanyRequested());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currencyCtrl.dispose();
    _vatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedLogoPath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mon Entreprise'),
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<CompanyBloc, CompanyState>(
        listenWhen: (p, c) => c.status == CompanyStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red,
            ),
          );
        },
        builder: (context, state) {
          if (state.status == CompanyStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final company = state.company;
          if (company != null && _nameCtrl.text.isEmpty) {
            _nameCtrl.text = company.name;
            _phoneCtrl.text = company.phone;
            _addressCtrl.text = company.address;
            _currencyCtrl.text = company.currency;
            _vatCtrl.text = (company.vatRate * 100).toStringAsFixed(0);
            _selectedLogoPath = company.logoPath;
          }
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header avec logo
                _buildHeader(company),
                
                const SizedBox(height: 20),
                
                // Informations générales
                _buildSection(
                  title: 'Informations générales',
                  icon: Icons.business,
                  children: [
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Nom de l\'entreprise',
                      prefixIcon: Icons.store,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneCtrl,
                      label: 'Téléphone',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _addressCtrl,
                      label: 'Adresse complète',
                      prefixIcon: Icons.location_on,
                      maxLines: 3,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Paramètres financiers
                _buildSection(
                  title: 'Paramètres financiers',
                  icon: Icons.attach_money,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _currencyCtrl,
                            label: 'Devise',
                            prefixIcon: Icons.currency_exchange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            controller: _vatCtrl,
                            label: 'TVA par défaut (%)',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.percent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Bouton d'enregistrement
                _buildSaveButton(company),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Company? company) {
    final logoPath = _selectedLogoPath ?? company?.logoPath;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.yellow,
            AppColors.yellow.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              // Logo avec upload
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Logo ou placeholder
                      ClipOval(
                        child: logoPath != null && logoPath.isNotEmpty
                            ? Image.file(
                                File(logoPath),
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                              )
                            : _buildLogoPlaceholder(),
                      ),
                      // Overlay pour upload
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Texte d'instruction
              Text(
                'Touchez pour modifier le logo',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Logo',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(Company? company) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: company == null
              ? null
              : () {
                  if (_nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez saisir le nom de l\'entreprise'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  final vatPercent = double.tryParse(_vatCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                  final updated = Company(
                    id: company.id,
                    name: _nameCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    address: _addressCtrl.text.trim(),
                    logoPath: _selectedLogoPath ?? company.logoPath,
                    currency: _currencyCtrl.text.trim().isEmpty ? 'FCFA' : _currencyCtrl.text.trim(),
                    vatRate: vatPercent / 100.0,
                  );
                  context.read<CompanyBloc>().add(CompanyUpdated(updated));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Entreprise mise à jour avec succès'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.save, size: 22),
              SizedBox(width: 12),
              Text(
                'Enregistrer les modifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
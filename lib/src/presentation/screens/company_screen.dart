/// CompanyScreen – paramètres entreprise avec design moderne et upload logo.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

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
  String? _selectedSignaturePath;
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
      // Étape 1 : Sélectionner l'image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Qualité max avant cropping
      );
      
      if (image != null) {
        // Étape 2 : Rogner l'image
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Format carré pour logo
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Rogner le logo',
              toolbarColor: AppColors.yellow,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              cropStyle: CropStyle.circle, // Aperçu circulaire
              activeControlsWidgetColor: AppColors.yellow,
            ),
            IOSUiSettings(
              title: 'Rogner le logo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
              rotateButtonsHidden: false,
              cropStyle: CropStyle.circle,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
            ),
          ],
          compressQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
        );
        
        if (croppedFile != null) {
          setState(() {
            _selectedLogoPath = croppedFile.path;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo mis à jour'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickSignature() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedSignaturePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _drawSignature() async {
    final signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    final result = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dessinez votre signature'),
          content: SizedBox(
            width: 400,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(
                controller: signatureController,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                signatureController.clear();
              },
              child: const Text('Effacer'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (signatureController.isNotEmpty) {
                  final signature = await signatureController.toPngBytes();
                  Navigator.of(context).pop(signature);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez dessiner une signature')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // Sauvegarder l'image de la signature
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(result);
        
        setState(() {
          _selectedSignaturePath = filePath;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }

    signatureController.dispose();
  }

  Future<void> _showSignatureOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ajouter une signature',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.draw, color: AppColors.yellow),
                  ),
                  title: const Text('Dessiner la signature'),
                  subtitle: const Text('Utilisez votre doigt ou stylet'),
                  onTap: () {
                    Navigator.pop(context);
                    _drawSignature();
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.image, color: Colors.blue),
                  ),
                  title: const Text('Importer une image'),
                  subtitle: const Text('Sélectionner depuis la galerie'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickSignature();
                  },
                ),
                if (_selectedSignaturePath != null) ...[
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Supprimer la signature'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedSignaturePath = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Gris très clair premium
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
            _selectedSignaturePath = company.signaturePath;
          }
          
          return CustomScrollView(
            slivers: [
              // Header Immersif (Sliver)
              _buildSliverHeader(company),
              
              SliverToBoxAdapter(
                      // Statistiques rapides
                      _buildQuickStats(),
                      
                      const SizedBox(height: 32),

                      // Informations générales
                      _buildSection(
                        title: 'Identité de l\'entreprise',
                        icon: Icons.business_center,
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            label: 'Nom commercial',
                            prefixIcon: Icons.store,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _phoneCtrl,
                            label: 'Téléphone professionnel',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_android,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _addressCtrl,
                            label: 'Siège social / Adresse',
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Paramètres financiers
                      _buildSection(
                        title: 'Paramètres & Fiscalité',
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _currencyCtrl,
                                  label: 'Devise code',
                                  prefixIcon: Icons.currency_exchange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  controller: _vatCtrl,
                                  label: 'TVA normale (%)',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.percent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Section Signature
                      _buildSignatureSection(company),
                      
                      const SizedBox(height: 48),
                      
                      // Bouton d'enregistrement
                      _buildSaveButton(company),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader(Company? company) {
    final logoPath = _selectedLogoPath ?? company?.logoPath;
    
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF2D2D2D),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background avec gradient sombre
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D2D2D),
                    Color(0xFF3D3D3D),
                  ],
                ),
              ),
            ),
            // Pattern décoratif discret
            Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/logo2.png',
                fit: BoxFit.none,
                repeat: ImageRepeat.repeat,
                scale: 5,
              ),
            ),
            // Infos Entreprise (Nom + Badge)
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _nameCtrl.text.isEmpty ? 'NOM DE VOTRE ENTREPRISE' : _nameCtrl.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppColors.yellow, size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          'PROFIL PROFESSIONNEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Logo flottant
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: -50,
              child: GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: logoPath != null && logoPath.isNotEmpty
                            ? Image.file(
                                File(logoPath),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                              )
                            : _buildLogoPlaceholder(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D2D2D),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.business,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.yellow, size: 20),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF757575),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(Company? company) {
    final signaturePath = _selectedSignaturePath ?? company?.signaturePath;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.draw, color: AppColors.yellow, size: 20),
                const SizedBox(width: 10),
                Text(
                  'SCEAU & SIGNATURE'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF757575),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showSignatureOptions,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEEEEEE),
                        width: 1,
                      ),
                    ),
                    child: signaturePath != null && signaturePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(signaturePath),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildSignaturePlaceholder(),
                            ),
                          )
                        : _buildSignaturePlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showSignatureOptions,
                  icon: Icon(signaturePath != null ? Icons.refresh : Icons.add, size: 18),
                  label: Text(signaturePath != null ? 'CHANGER' : 'AJOUTER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    // Dans une version plus avancée, ces données viendraient d'un BLoC/Repository
    return Row(
      children: [
        _buildStatCard('DÉVIS', '24', Icons.description_outlined),
        const SizedBox(width: 12),
        _buildStatCard('CLIENTS', '12', Icons.people_outline),
        const SizedBox(width: 12),
        _buildStatCard('CA (MOIS)', '1.2M', Icons.trending_up, isAmount: true),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {bool isAmount = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.yellow.withOpacity(0.8)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(Company? company) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        final loading = state.status == CompanyStatus.loading;
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: loading ? null : () => _saveCompany(company),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D2D),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'ENREGISTRER LA FICHE PRO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _saveCompany(Company? company) {
    if (company == null) return;
    
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de l\'entreprise est requis')),
      );
      return;
    }
    
    final vatRate = double.tryParse(_vatCtrl.text.trim()) ?? 18.0;
    final updated = Company(
      id: company.id,
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logoPath: _selectedLogoPath,
      currency: _currencyCtrl.text.trim(),
      vatRate: vatRate / 100,
      signaturePath: _selectedSignaturePath,
    );
    
    context.read<CompanyBloc>().add(CompanyUpdated(updated));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fiche entreprise mise à jour avec succès ✨'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

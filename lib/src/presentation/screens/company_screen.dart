/// CompanyScreen – paramètres entreprise avec design moderne et upload logo.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../domain/entities/company.dart';
import '../blocs/company/company_bloc.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_scaffold.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
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
    _emailCtrl.dispose();
    _currencyCtrl.dispose();
    _vatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (image != null) {
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Rogner le logo',
              toolbarColor: AppColors.yellow,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              cropStyle: CropStyle.circle,
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
          ],
          compressQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
        );
        
        if (croppedFile != null) {
          setState(() {
            _selectedLogoPath = croppedFile.path;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20),
        ),
      );
    } finally {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
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
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20),
        ),
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
            TextButton(onPressed: () => signatureController.clear(), child: const Text('Effacer')),
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (signatureController.isNotEmpty) {
                  final signature = await signatureController.toPngBytes();
                  Navigator.of(context).pop(signature);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(result);
        setState(() => _selectedSignaturePath = filePath);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 20),
          ),
        );
      }
    }
    signatureController.dispose();
  }

  Future<void> _showSignatureOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Text('Ajouter une signature', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.draw, color: AppColors.yellow)),
                  title: const Text('Dessiner la signature'),
                  onTap: () { Navigator.pop(context); _drawSignature(); },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image, color: Colors.blue)),
                  title: const Text('Importer une image'),
                  onTap: () { Navigator.pop(context); _pickSignature(); },
                ),
                if (_selectedSignaturePath != null)
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete, color: Colors.red)),
                    title: const Text('Supprimer la signature'),
                    onTap: () { Navigator.pop(context); setState(() => _selectedSignaturePath = null); },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<CompanyBloc, CompanyState>(
        listener: (context, state) {
          if (state.status == CompanyStatus.failure && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state.status == CompanyStatus.loading && state.company == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final company = state.company;
          if (company != null && _nameCtrl.text.isEmpty) {
            _nameCtrl.text = company.name;
            _phoneCtrl.text = company.phone;
            _addressCtrl.text = company.address;
            _emailCtrl.text = company.email ?? '';
            _currencyCtrl.text = company.currency;
            _vatCtrl.text = (company.vatRate * 100).toStringAsFixed(0);
            _selectedLogoPath = company.logoPath;
            _selectedSignaturePath = company.signaturePath;
          }
          
          return CustomScrollView(
            slivers: [
              _buildSliverHeader(company),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Column(
                    children: [
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
                            controller: _emailCtrl,
                            label: 'Email de contact',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
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
                      _buildSection(
                        title: 'Paramètres & Fiscalité',
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(child: AppTextField(controller: _currencyCtrl, label: 'Devise code', prefixIcon: Icons.currency_exchange)),
                              const SizedBox(width: 16),
                              Expanded(child: AppTextField(controller: _vatCtrl, label: 'TVA normale (%)', keyboardType: TextInputType.number, prefixIcon: Icons.percent)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSignatureSection(company),
                      const SizedBox(height: 48),
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
        background: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo Positionné au dessus du nom
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipOval(
                          child: logoPath != null && logoPath.isNotEmpty
                              ? Image.file(File(logoPath), width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildLogoPlaceholder())
                              : _buildLogoPlaceholder(),
                        ),
                        Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFF2D2D2D), shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 10))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _nameCtrl.text.isEmpty ? 'VOTRE ENTREPRISE' : _nameCtrl.text.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(width: 90, height: 90, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(Icons.business, size: 36, color: Colors.grey[400]));
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [Icon(icon, color: AppColors.yellow, size: 20), const SizedBox(width: 10), Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF757575), letterSpacing: 1))]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(Company? company) {
    final signaturePath = _selectedSignaturePath ?? company?.signaturePath;
    return _buildSection(
      title: 'Sceau & Signature',
      icon: Icons.draw,
      children: [
        GestureDetector(
          onTap: _showSignatureOptions,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
            child: signaturePath != null && signaturePath.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(signaturePath), fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildSignaturePlaceholder()))
                : _buildSignaturePlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: _showSignatureOptions, icon: Icon(signaturePath != null ? Icons.refresh : Icons.add, size: 16, color: AppColors.yellow), label: Text(signaturePath != null ? 'CHANGER' : 'AJOUTER', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildSignaturePlaceholder() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.draw, size: 40, color: Colors.grey[400]), const Text('Aucune signature', style: TextStyle(color: Colors.grey, fontSize: 12))]);
  }

  Widget _buildSaveButton(Company? company) {
    return BlocBuilder<CompanyBloc, CompanyState>(
      builder: (context, state) {
        final loading = state.status == CompanyStatus.loading;
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: loading ? null : () => _saveCompany(company),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D2D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENREGISTRER LA FICHE PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        );
      },
    );
  }

  void _saveCompany(Company? company) {
    if (company == null) return;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nom est requis')));
      return;
    }
    final vatRate = double.tryParse(_vatCtrl.text.trim()) ?? 18.0;
    context.read<CompanyBloc>().add(CompanyUpdated(Company(
      id: company.id, name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(), address: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim(), logoPath: _selectedLogoPath, currency: _currencyCtrl.text.trim(),
      vatRate: vatRate / 100, signaturePath: _selectedSignaturePath,
    )));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profil mis à jour ✨'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20), // Standard bottom margin
      ),
    );
  }
}

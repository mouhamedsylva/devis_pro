/// CompanyScreen – paramètres entreprise (nom, téléphone, adresse, devise, TVA).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entreprise')),
      body: BlocConsumer<CompanyBloc, CompanyState>(
        listenWhen: (p, c) => c.status == CompanyStatus.failure && c.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
        },
        builder: (context, state) {
          if (state.status == CompanyStatus.loading) return const Center(child: CircularProgressIndicator());
          final company = state.company;
          if (company != null) {
            _nameCtrl.text = company.name;
            _phoneCtrl.text = company.phone;
            _addressCtrl.text = company.address;
            _currencyCtrl.text = company.currency;
            _vatCtrl.text = (company.vatRate * 100).toStringAsFixed(0);
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(controller: _nameCtrl, label: 'Nom entreprise'),
                const SizedBox(height: 10),
                AppTextField(controller: _phoneCtrl, label: 'Téléphone', keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                AppTextField(controller: _addressCtrl, label: 'Adresse'),
                const SizedBox(height: 10),
                AppTextField(controller: _currencyCtrl, label: 'Devise (label)', keyboardType: TextInputType.text),
                const SizedBox(height: 10),
                AppTextField(controller: _vatCtrl, label: 'TVA (%)', keyboardType: TextInputType.number),
                const Spacer(),
                ElevatedButton(
                  onPressed: company == null
                      ? null
                      : () {
                          final vatPercent = double.tryParse(_vatCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                          final updated = Company(
                            id: company.id,
                            name: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            address: _addressCtrl.text.trim(),
                            logoPath: company.logoPath,
                            currency: _currencyCtrl.text.trim().isEmpty ? 'FCFA' : _currencyCtrl.text.trim(),
                            vatRate: vatPercent / 100.0,
                          );
                          context.read<CompanyBloc>().add(CompanyUpdated(updated));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entreprise mise à jour')));
                        },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


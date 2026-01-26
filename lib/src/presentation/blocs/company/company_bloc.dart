/// BLoC Company: lecture/mise à jour des paramètres d'entreprise.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/company.dart';
import '../../../domain/repositories/company_repository.dart';

part 'company_event.dart';
part 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc({required CompanyRepository companyRepository})
      : _companyRepository = companyRepository,
        super(const CompanyState.initial()) {
    on<CompanyRequested>((event, emit) async {
      emit(const CompanyState.loading());
      try {
        final company = await _companyRepository.getCompany();
        emit(CompanyState.loaded(company));
      } catch (e) {
        emit(CompanyState.failure(e.toString()));
      }
    });

    on<CompanyUpdated>((event, emit) async {
      emit(const CompanyState.loading());
      try {
        await _companyRepository.updateCompany(event.company);
        emit(CompanyState.loaded(event.company));
      } catch (e) {
        emit(CompanyState.failure(e.toString()));
      }
    });

    on<CompanyUpdateFromRegistration>((event, emit) async {
      // Pas besoin d'émettre "loading" pour ne pas perturber l'UI
      try {
        // 1. Récupérer l'entreprise actuelle
        final currentCompany = await _companyRepository.getCompany();

        // 2. Créer l'objet mis à jour
        final updatedCompany = Company(
          id: currentCompany.id,
          name: event.name,
          phone: event.phone,
          email: event.email,
          address: currentCompany.address, // Garder les valeurs existantes
          logoPath: currentCompany.logoPath,
          currency: currentCompany.currency,
          vatRate: currentCompany.vatRate,
          signaturePath: currentCompany.signaturePath,
        );

        // 3. Mettre à jour en base de données
        await _companyRepository.updateCompany(updatedCompany);

        // 4. Émettre le nouvel état pour que l'UI se mette à jour
        emit(CompanyState.loaded(updatedCompany));
      } catch (e) {
        // En cas d'erreur, on peut émettre un état d'échec
        // mais on évite de bloquer l'utilisateur qui vient de s'inscrire
        print('Erreur lors de la mise à jour de l\'entreprise après inscription: $e');
      }
    });
  }

  final CompanyRepository _companyRepository;
}


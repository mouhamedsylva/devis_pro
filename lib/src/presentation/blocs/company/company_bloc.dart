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
  }

  final CompanyRepository _companyRepository;
}


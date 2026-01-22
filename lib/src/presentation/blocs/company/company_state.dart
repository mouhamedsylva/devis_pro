part of 'company_bloc.dart';

class CompanyState extends Equatable {
  const CompanyState._({required this.status, this.company, this.message});

  const CompanyState.initial() : this._(status: CompanyStatus.initial);
  const CompanyState.loading() : this._(status: CompanyStatus.loading);
  const CompanyState.loaded(Company company) : this._(status: CompanyStatus.loaded, company: company);
  const CompanyState.failure(String message) : this._(status: CompanyStatus.failure, message: message);

  final CompanyStatus status;
  final Company? company;
  final String? message;

  @override
  List<Object?> get props => [status, company, message];
}

enum CompanyStatus { initial, loading, loaded, failure }


part of 'company_bloc.dart';

sealed class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

class CompanyRequested extends CompanyEvent {
  const CompanyRequested();
}

class CompanyUpdated extends CompanyEvent {
  const CompanyUpdated(this.company);

  final Company company;

  @override
  List<Object?> get props => [company];
}

class CompanyUpdateFromRegistration extends CompanyEvent {
  const CompanyUpdateFromRegistration({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String email;

  @override
  List<Object?> get props => [name, phone, email];
}


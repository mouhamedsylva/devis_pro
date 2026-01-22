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


/// Abstraction repository Company.
import '../entities/company.dart';

abstract class CompanyRepository {
  Future<Company> getCompany();
  Future<void> updateCompany(Company company);
}


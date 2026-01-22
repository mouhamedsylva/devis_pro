/// Impl SQLite du CompanyRepository.
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/company_model.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  const CompanyRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<Company> getCompany() async {
    final rows = await _db.database.query('company', limit: 1);
    if (rows.isEmpty) {
      throw StateError('Company row missing. Database schema should create a default company.');
    }
    return CompanyModel.fromMap(rows.first);
  }

  @override
  Future<void> updateCompany(Company company) async {
    await _db.database.update(
      'company',
      CompanyModel.toMap(company),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }
}


/// DTO SQLite <-> Entité Company.
import '../../domain/entities/company.dart';

class CompanyModel {
  static Company fromMap(Map<String, Object?> map) {
    return Company(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      email: map['email'] as String?,
      logoPath: map['logoPath'] as String?,
      currency: (map['currency'] as String?) ?? 'FCFA',
      vatRate: (map['vatRate'] as num).toDouble(),
      signaturePath: map['signaturePath'] as String?,
    );
  }

  static Map<String, Object?> toMap(Company c) {
    return {
      'id': c.id,
      'name': c.name,
      'phone': c.phone,
      'address': c.address,
      'email': c.email,
      'logoPath': c.logoPath,
      'currency': c.currency,
      'vatRate': c.vatRate,
      'signaturePath': c.signaturePath,
    };
  }
}


/// Abstraction repository Client (CRUD).
import '../entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> list();
  Future<Client?> findById(int id);
  Future<Client> create({required String name, required String phone, required String address});
  Future<void> update(Client client);
  Future<void> delete(int id);
}


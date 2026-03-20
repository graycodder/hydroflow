import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  Stream<List<Customer>> call(String salesmanId, {String? agencyId, String? zone}) {
    return repository.getCustomers(salesmanId, agencyId: agencyId, zone: zone);
  }

  Stream<List<Customer>> byAgency(String agencyId) {
    return repository.getCustomersByAgency(agencyId);
  }

  Future<List<Customer>> getCustomersPaginated(String salesmanId, {String? agencyId, String? zone, int limit = 20, String? lastCustomerId}) {
    return repository.getCustomersPaginated(salesmanId, agencyId: agencyId, zone: zone, limit: limit, lastCustomerId: lastCustomerId);
  }
}

import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository repository;

  GetCustomersUseCase(this.repository);

  Stream<List<Customer>> call(String salesmanId) {
    return repository.getCustomers(salesmanId);
  }

  Stream<List<Customer>> byAgency(String agencyId) {
    return repository.getCustomersByAgency(agencyId);
  }
}

import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';

class AddCustomerUseCase {
  final CustomerRepository repository;

  AddCustomerUseCase(this.repository);

  Future<void> call(Customer customer) {
    return repository.addCustomer(customer);
  }
}

import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';

class UpdateCustomerUseCase {
  final CustomerRepository repository;

  UpdateCustomerUseCase(this.repository);

  Future<void> call(Customer customer) async {
    return await repository.updateCustomer(customer);
  }
}

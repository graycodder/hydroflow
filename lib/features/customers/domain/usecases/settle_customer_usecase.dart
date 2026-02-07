import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';

class SettleCustomerUseCase {
  final CustomerRepository repository;

  SettleCustomerUseCase(this.repository);

  Future<void> call(Customer customer) async {
    return await repository.settleAndDeactivate(customer);
  }
}

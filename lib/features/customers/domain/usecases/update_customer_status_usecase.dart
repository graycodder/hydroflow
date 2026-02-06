import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';

class UpdateCustomerStatusUseCase {
  final CustomerRepository repository;

  UpdateCustomerStatusUseCase(this.repository);

  Future<void> call(String id, String status, String salesmanId) {
    return repository.updateCustomerStatus(id, status, salesmanId);
  }
}

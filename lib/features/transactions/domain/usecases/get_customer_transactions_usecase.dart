import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';

class GetCustomerTransactionsUseCase {
  final TransactionRepository repository;

  GetCustomerTransactionsUseCase(this.repository);

  Stream<List<TransactionEntity>> call(String customerId) {
    return repository.getTransactionsByCustomer(customerId);
  }
}

import 'package:watermemo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:watermemo/features/transactions/domain/entities/transaction_entity.dart';

class AddTransactionUseCase {
  final TransactionRepository repository;

  AddTransactionUseCase(this.repository);

  Future<void> call(TransactionEntity transaction) async {
    return await repository.recordTransaction(transaction);
  }
}

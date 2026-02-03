import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';

class GetTodayTransactionsUseCase {
  final TransactionRepository repository;

  GetTodayTransactionsUseCase(this.repository);

  Stream<List<TransactionEntity>> call(String salesmanId) async* {
    yield* repository.getTodayTransactions(salesmanId);
  }
}

import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<void> recordTransaction(TransactionEntity transaction);
  Stream<List<TransactionEntity>> getTodayTransactions(String salesmanId);
}

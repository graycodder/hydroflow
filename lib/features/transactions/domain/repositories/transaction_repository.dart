import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<void> recordTransaction(TransactionEntity transaction);
  Future<void> recordAdjustment(TransactionEntity transaction);
  Stream<List<TransactionEntity>> getTodayTransactions(String salesmanId);
  Stream<List<TransactionEntity>> getTransactionsByDate(String salesmanId, DateTime date);
  Stream<List<TransactionEntity>> getTransactionsByMonth(String salesmanId, DateTime month);
}

import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/bottles/domain/entities/bottle_ledger_stats.dart';

class GetBottleLedgerUseCase {
  final CustomerRepository repository;

  GetBottleLedgerUseCase(this.repository);

  Future<BottleLedgerStats> call(String salesmanId) async {
    final customers = await repository.getCustomers(salesmanId).first;

    int totalBottles = 0;
    int highBalanceCount = 0;

    for (var customer in customers) {
      totalBottles += customer.bottleBalance;
      if (customer.bottleBalance > 5) {
        highBalanceCount++;
      }
    }

    double avgBalance = customers.isEmpty ? 0.0 : totalBottles / customers.length;

    return BottleLedgerStats(
      customers: customers,
      totalBottles: totalBottles,
      highBalanceCount: highBalanceCount,
      avgBalance: avgBalance,
    );
  }
}

import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/bottles/domain/entities/bottle_ledger_stats.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

class GetBottleLedgerUseCase {
  final CustomerRepository repository;

  GetBottleLedgerUseCase(this.repository);

  Stream<BottleLedgerStats> call(String salesmanId) {
    return _mapToStats(repository.getCustomers(salesmanId));
  }

  Stream<BottleLedgerStats> getAgencyBottleLedger(String agencyId) {
    return _mapToStats(repository.getCustomersByAgency(agencyId));
  }

  Stream<BottleLedgerStats> _mapToStats(Stream<List<Customer>> customerStream) {
    return customerStream.map((customers) {
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
    });
  }
}

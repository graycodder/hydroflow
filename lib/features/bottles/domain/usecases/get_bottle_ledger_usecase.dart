import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/features/bottles/domain/entities/bottle_ledger_stats.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

class GetBottleLedgerUseCase {
  final CustomerRepository customerRepository;
  final AgencyRepository agencyRepository;

  GetBottleLedgerUseCase(this.customerRepository, this.agencyRepository);

  Stream<BottleLedgerStats> call(String salesmanId) {
    return _mapToStats(customerRepository.getCustomers(salesmanId));
  }

  Stream<BottleLedgerStats> getAgencyBottleLedger(String agencyId) {
    return _mapToStats(customerRepository.getCustomersByAgency(agencyId));
  }

  Stream<BottleLedgerStats> getAgencySalesmanLedger(String agencyId) {
    return Stream.fromFuture(agencyRepository.getSalesmenByAgency(agencyId)).map((salesmen) {
      int totalBottles = 0;
      int highBalanceCount = 0;

      for (var salesman in salesmen) {
        // Here we define what "Total Bottles" means for a salesman in the ledger context.
        // It's usually Full + Empty on vehicle? Or just Full?
        // User said: "Agency Bottle Ledger is show Salesman's data"
        // Let's include both or just the ones that matter (Full + Empty).
        totalBottles += (salesman.currentStock + (salesman.emptyBottles ?? 0));
        
        // For a salesman, "High Balance" might mean something different. 
        // Let's stick to the >5 rule for now or refine if needed.
        if ((salesman.currentStock + (salesman.emptyBottles ?? 0)) > 5) {
          highBalanceCount++;
        }
      }

      double avgBalance = salesmen.isEmpty ? 0.0 : totalBottles / salesmen.length;

      return BottleLedgerStats(
        customers: const [], // No customer data in this mode
        salesmen: salesmen,
        totalBottles: totalBottles,
        highBalanceCount: highBalanceCount,
        avgBalance: avgBalance,
      );
    });
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
        salesmen: null,
        totalBottles: totalBottles,
        highBalanceCount: highBalanceCount,
        avgBalance: avgBalance,
      );
    });
  }
}

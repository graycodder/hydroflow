import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';
import 'package:watermemo/features/auth/domain/repositories/agency_repository.dart';
import 'package:watermemo/features/bottles/domain/entities/bottle_ledger_stats.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';

class GetBottleLedgerUseCase {
  final CustomerRepository customerRepository;
  final AgencyRepository agencyRepository;

  GetBottleLedgerUseCase(this.customerRepository, this.agencyRepository);

  Stream<BottleLedgerStats> call(String salesmanId, {String? agencyId, String? zone}) {
    return _mapToStats(customerRepository.getCustomers(salesmanId, agencyId: agencyId, zone: zone));
  }

  Stream<BottleLedgerStats> getAgencyBottleLedger(String agencyId) {
    return _mapToStats(customerRepository.getCustomersByAgency(agencyId));
  }

  Future<BottleLedgerStats> getPaginatedLedger(String salesmanId, {String? agencyId, String? zone, int limit = 20, String? lastCustomerId}) async {
    final customers = await customerRepository.getCustomersPaginated(salesmanId, agencyId: agencyId, zone: zone, limit: limit, lastCustomerId: lastCustomerId);
    
    int totalBottles = 0;
    int highBalanceCount = 0;

    // Note: Stats here are only for the PAGED customers.
    // If the user wants TOTAL stats, we might need a separate total stats fetch.
    // However, the current UI shows "Total Bottles In Circulation" which usually means the whole set.
    // Since we're doing pagination, we should probably fetch the totals once and keep them.
    
    for (var customer in customers) {
      totalBottles += customer.bottleBalance;
      if (customer.bottleBalance > 5) {
        highBalanceCount++;
      }
    }

    return BottleLedgerStats(
      customers: customers,
      salesmen: null,
      totalBottles: totalBottles, // This will be per-page if we don't adjust
      highBalanceCount: highBalanceCount,
      avgBalance: customers.isEmpty ? 0.0 : totalBottles / customers.length,
    );
  }

  Stream<BottleLedgerStats> getAgencySalesmanLedger(String agencyId) {
    return Stream.fromFuture(
      agencyRepository.getSalesmenByAgency(agencyId),
    ).map((salesmen) {
      int totalBottles = 0;
      int highBalanceCount = 0;

      for (var salesman in salesmen) {
        // As requested: Only calculate Total Bottles using currentStock (Full bottles)
        totalBottles += salesman.currentStock;

        if ((salesman.currentStock + (salesman.emptyBottles ?? 0)) > 5) {
          highBalanceCount++;
        }
      }

      double avgBalance = salesmen.isEmpty
          ? 0.0
          : totalBottles / salesmen.length;

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

      double avgBalance = customers.isEmpty
          ? 0.0
          : totalBottles / customers.length;

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

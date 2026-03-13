import 'package:watermemo/features/customers/domain/entities/customer.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> getCustomers(String salesmanId, {String? agencyId, String? zone});
  Stream<List<Customer>> getCustomersByAgency(String agencyId);
  Future<int> getTotalBottleBalance(String salesmanId);
  Future<void> addCustomer(Customer customer);
  Future<void> updateCustomerStatus(String id, String status, String salesmanId);
  Future<void> updateCustomer(Customer customer);
  Future<void> settleAndDeactivate(Customer customer);
}

import 'package:hydroflow/features/customers/domain/entities/customer.dart';

abstract class CustomerRepository {
  Stream<List<Customer>> getCustomers(String salesmanId);
  Future<void> addCustomer(Customer customer);
  Future<void> updateCustomerStatus(String id, String status);
}

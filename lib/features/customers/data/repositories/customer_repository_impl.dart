import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/customers/data/models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseDatabase _database;

  CustomerRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<List<Customer>> getCustomers(String salesmanId) {
    final ref = _database.ref().child('Customers');
    // Query customers by salesmanId
    return ref.orderByChild('salesmanId').equalTo(salesmanId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
             final map = Map<String, dynamic>.from(entry.value as Map);
             map['id'] = entry.key; // Inject ID
             return CustomerModel.fromMap(map);
        }).toList();
      }
      return [];
    });
  }
  @override
  Future<void> addCustomer(Customer customer) async {
    try {
      final ref = _database.ref().child('Customers').push();
      final customerModel = CustomerModel(
        id: ref.key!,
        salesmanId: customer.salesmanId,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        status: customer.status,
        securityDeposit: customer.securityDeposit,
        pendingBalance: customer.pendingBalance,
        bottleBalance: customer.bottleBalance,
        isRefunded: customer.isRefunded,
      );
      
      await ref.set(customerModel.toMap());
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  @override
  Future<void> updateCustomerStatus(String id, String status) async {
    try {
      final ref = _database.ref().child('Customers/$id');
      await ref.update({'status': status});
    } catch (e) {
      throw Exception('Failed to update customer status: $e');
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      final ref = _database.ref().child('Customers/${customer.id}');
      final customerModel = CustomerModel(
        id: customer.id,
        salesmanId: customer.salesmanId,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        status: customer.status,
        securityDeposit: customer.securityDeposit,
        pendingBalance: customer.pendingBalance,
        bottleBalance: customer.bottleBalance,
        isRefunded: customer.isRefunded,
      );
      await ref.update(customerModel.toMap());
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }
}

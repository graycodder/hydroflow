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
    // Enable synchronization for this node to keep it ready in local cache
    ref.keepSynced(true);
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
        paymentMode: customer.paymentMode,
      );
      
      await ref.set(customerModel.toMap());

      // Increment salesman's customer count and active customer count
      final salesmanRef = _database.ref().child('Salesmen').child(customer.salesmanId);
      await salesmanRef.update({
        'customerCount': ServerValue.increment(1),
        'activeCustomers': ServerValue.increment(1),
        'totalDepositsHeld': ServerValue.increment(customer.securityDeposit),
      });

      // Record Deposit Transaction
      if (customer.securityDeposit > 0) {
        final txRef = _database.ref().child('Transactions').push();
        await txRef.set({
          'salesmanId': customer.salesmanId,
          'customerId': ref.key,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'Deposit',
          'amount': customer.securityDeposit,
          'amountReceived': customer.securityDeposit,
          'paymentMode': customer.paymentMode, // Use selected payment mode
          'cansDelivered': 0,
          'emptyCollected': 0,
          'whatsappReceiptSent': false,
          'notes': 'Initial Security Deposit',
        });

        // Update Stock Log Collection
        final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
        final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${customer.salesmanId}');
        await logRef.runTransaction((Object? post) {
          final logMap = post == null ? <String, dynamic>{} : Map<String, dynamic>.from(post as Map);
          if (!logMap.containsKey('date')) {
            logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
            logMap['salesmanId'] = customer.salesmanId;
          }
          final currentColl = (logMap['todayCollection'] as num?)?.toDouble() ?? 0.0;
          logMap['todayCollection'] = currentColl + customer.securityDeposit;
          
          if (customer.paymentMode == 'Cash') {
            final currentCash = (logMap['cashCollected'] as num?)?.toDouble() ?? 0.0;
            logMap['cashCollected'] = currentCash + customer.securityDeposit;
          } else if (customer.paymentMode == 'Online' || customer.paymentMode == 'UPI') {
            final currentOnline = (logMap['onlineCollected'] as num?)?.toDouble() ?? 0.0;
            logMap['onlineCollected'] = currentOnline + customer.securityDeposit;
          }
          
          return Transaction.success(logMap);
        });
      }
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  @override
  Future<void> updateCustomerStatus(String id, String status, String salesmanId) async {
    try {
      final customerRef = _database.ref().child('Customers/$id');
      final snapshot = await customerRef.child('status').get();
      final oldStatus = snapshot.value as String?;

      if (oldStatus != status) {
        await customerRef.update({'status': status});

        final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
        if (status == 'Active') {
          await salesmanRef.update({'activeCustomers': ServerValue.increment(1)});
        } else if (status == 'Inactive') {
          await salesmanRef.update({'activeCustomers': ServerValue.increment(-1)});
        }
      }
    } catch (e) {
      throw Exception('Failed to update customer status: $e');
    }
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    try {
      final ref = _database.ref().child('Customers/${customer.id}');
      
      // 1. Fetch existing data to compare Security Deposit
      final snapshot = await ref.get();
      if (!snapshot.exists) {
         throw Exception('Customer not found');
      }
      final existingData = Map<String, dynamic>.from(snapshot.value as Map);
      final oldDeposit = (existingData['securityDeposit'] as num?)?.toDouble() ?? 0.0;
      
      final double newDeposit = customer.securityDeposit;
      final double depositDiff = newDeposit - oldDeposit;
      
      // 2. Update Customer Data
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
        paymentMode: customer.paymentMode,
      );
      await ref.update(customerModel.toMap());
      
      // 3. Handle Deposit Difference
      if (depositDiff != 0) {
        // Update Salesman
        final salesmanRef = _database.ref().child('Salesmen/${customer.salesmanId}');
        await salesmanRef.update({
          'totalDepositsHeld': ServerValue.increment(depositDiff),
        });

        // Record Transaction
        final txRef = _database.ref().child('Transactions').push();
        
        if (depositDiff > 0) {
          // Additional Deposit
          await txRef.set({
            'salesmanId': customer.salesmanId,
            'customerId': customer.id,
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'Deposit',
            'amount': depositDiff,
            'amountReceived': depositDiff,
            'paymentMode': customer.paymentMode, 
            'cansDelivered': 0,
            'emptyCollected': 0,
            'whatsappReceiptSent': false,
            'notes': 'Security Deposit Increased',
          });
        } else {
          // Refund/Decrease
          final refundAmt = depositDiff.abs();
          await txRef.set({
            'salesmanId': customer.salesmanId,
            'customerId': customer.id,
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'Refund',
            'amount': refundAmt,
            'amountReceived': refundAmt,
            'paymentMode': customer.paymentMode, 
            'cansDelivered': 0,
            'emptyCollected': 0,
            'whatsappReceiptSent': false,
            'notes': 'Security Deposit Decreased',
          });
        }

        // Update Stock Log Collection
        final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
        final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${customer.salesmanId}');
        await logRef.runTransaction((Object? post) {
            final logMap = post == null ? <String, dynamic>{} : Map<String, dynamic>.from(post as Map);
            if (!logMap.containsKey('date')) {
              logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
              logMap['salesmanId'] = customer.salesmanId;
            }
            final currentColl = (logMap['todayCollection'] as num?)?.toDouble() ?? 0.0;
            // Deposit increase is (+) collection. Decrease/Refund is (-) collection.
            logMap['todayCollection'] = currentColl + depositDiff;

            if (customer.paymentMode == 'Cash') {
              final currentCash = (logMap['cashCollected'] as num?)?.toDouble() ?? 0.0;
              logMap['cashCollected'] = currentCash + depositDiff;
            } else if (customer.paymentMode == 'Online' || customer.paymentMode == 'UPI') {
              final currentOnline = (logMap['onlineCollected'] as num?)?.toDouble() ?? 0.0;
              logMap['onlineCollected'] = currentOnline + depositDiff;
            }

            return Transaction.success(logMap);
        });
      }
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  @override
  Future<void> settleAndDeactivate(Customer customer) async {
    try {
      final double deposit = customer.securityDeposit;
      final double pending = customer.pendingBalance;
      
      // Calculate adjusted amounts
      double refundAmount = 0;
      double adjustedPending = 0;
      double amountAdjusted = 0; // Amount of deposit used to pay pending
      
      if (deposit >= pending) {
        refundAmount = deposit - pending;
        adjustedPending = 0;
        amountAdjusted = pending;
      } else {
        refundAmount = 0;
        adjustedPending = pending - deposit;
        amountAdjusted = deposit;
      }

      // 1. Update Customer
      final customerRef = _database.ref().child('Customers/${customer.id}');
      await customerRef.update({
        'status': 'Inactive',
        'securityDeposit': 0.0, // Deposit is now settled/refunded
        'pendingBalance': adjustedPending,
        'isRefunded': true, // Flag to indicate settlement
        'lastSettledDate': DateTime.now().toIso8601String(),
      });

      // 2. Update Salesman (Reduce Total Deposits Held)
      final salesmanRef = _database.ref().child('Salesmen/${customer.salesmanId}');
      await salesmanRef.update({
        'totalDepositsHeld': ServerValue.increment(-deposit), // Reduce by full original deposit
        'activeCustomers': ServerValue.increment(-1),
      });

      // 3. Record Transactions
      
      // A. Refund Transaction (if any money returned)
      if (refundAmount > 0) {
        final refundRef = _database.ref().child('Transactions').push();
        await refundRef.set({
          'salesmanId': customer.salesmanId,
          'customerId': customer.id,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'Refund',
          'amount': refundAmount,
          'amountReceived': refundAmount, // Money out
          'paymentMode': 'Cash', 
          'cansDelivered': 0,
          'emptyCollected': 0,
          'whatsappReceiptSent': false,
          'notes': 'Security Deposit Refund',
        });
      }

      // B. Adjustment Transaction (if deposit covered pending)
      if (amountAdjusted > 0) {
        final adjustRef = _database.ref().child('Transactions').push();
        await adjustRef.set({
          'salesmanId': customer.salesmanId,
          'customerId': customer.id,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'Payment', // Payment type
          'amount': 0, // No new bill value
          'amountReceived': amountAdjusted, // Money credited to pending
          'paymentMode': 'Deposit Adjustment', 
          'cansDelivered': 0,
          'emptyCollected': 0,
          'whatsappReceiptSent': false,
          'notes': 'Settled via Security Deposit',
        });
      }
      
      // Update Stock Log for Settlement
      final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
      final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${customer.salesmanId}');
      await logRef.runTransaction((Object? post) {
          final logMap = post == null ? <String, dynamic>{} : Map<String, dynamic>.from(post as Map);
          if (!logMap.containsKey('date')) {
            logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
            logMap['salesmanId'] = customer.salesmanId;
          }
          final currentColl = (logMap['todayCollection'] as num?)?.toDouble() ?? 0.0;
          logMap['todayCollection'] = currentColl - refundAmount;
          
          final currentCash = (logMap['cashCollected'] as num?)?.toDouble() ?? 0.0;
          logMap['cashCollected'] = currentCash - refundAmount;

          return Transaction.success(logMap);
      });
      
    } catch (e) {
      throw Exception('Failed to settle and deactivate customer: $e');
    }
  }
}

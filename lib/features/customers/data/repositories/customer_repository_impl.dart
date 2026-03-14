import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';
import 'package:watermemo/features/customers/data/models/customer_model.dart';
import 'package:intl/intl.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseDatabase _database;

  CustomerRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<List<Customer>> getCustomers(String salesmanId, {String? agencyId, String? zone}) {
    final ref = _database.ref().child('Customers');
    ref.keepSynced(true);

    // Use agencyId for querying if provided, supporting agency-wide access
    if (agencyId != null && agencyId.isNotEmpty) {
      return ref.orderByChild('agencyId').equalTo(agencyId).onValue.map((event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final lowerZone = zone?.trim().toLowerCase();
          final bool shouldFilterByZone = lowerZone != null && lowerZone.isNotEmpty && lowerZone != 'all';
          final assignedZones = shouldFilterByZone ? lowerZone.split(',').map((e) => e.trim()).toList() : [];

          return data.entries
              .where((entry) {
                if (!shouldFilterByZone) return true;
                
                final val = entry.value as Map;
                final customerZone = (val['zone'] as String? ?? '').trim().toLowerCase();
                return assignedZones.contains(customerZone);
              })
              .map((entry) {
                final map = Map<String, dynamic>.from(entry.value as Map);
                map['id'] = entry.key;
                return CustomerModel.fromMap(map);
              })
              .toList();
        }
        return [];
      });
    }

    // Legacy Fallback (for older accounts without agencyId mapping transition): 
    // Query customers strictly by salesmanId
    return ref.orderByChild('salesmanId').equalTo(salesmanId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          map['id'] = entry.key; 
          return CustomerModel.fromMap(map);
        }).toList();
      }
      return [];
    });
  }

  @override
  Stream<List<Customer>> getCustomersByAgency(String agencyId) {
    final ref = _database.ref().child('Customers');
    ref.keepSynced(true);
    // Query customers by agencyId
    return ref.orderByChild('agencyId').equalTo(agencyId).onValue.map((event) {
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
  Future<int> getTotalBottleBalance(String salesmanId) async {
    try {
      final ref = _database.ref().child('Customers');
      final snapshot = await ref.orderByChild('salesmanId').equalTo(salesmanId).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        int totalBalance = 0;
        data.forEach((key, value) {
          final customer = Map<String, dynamic>.from(value as Map);
          totalBalance += (customer['bottleBalance'] as num?)?.toInt() ?? 0;
        });
        return totalBalance;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    try {
      final salesmanId = customer.salesmanId;
      final agencyId = customer.agencyId;
      
      // 1. Check Salesman Quota and Agency Limit (Atomic)
      final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
      final agencyRef = _database.ref().child('Agencies').child(agencyId);

      // Increment Salesman Stats (only if assigned)
      if (salesmanId.isNotEmpty) {
        final salesmanTx = await salesmanRef.runTransaction((Object? data) {
          if (data == null) return Transaction.abort();
          final map = Map<String, dynamic>.from(data as Map);

          map['customerCount'] = ((map['customerCount'] as num?)?.toInt() ?? 0) + 1;
          map['activeCustomers'] = ((map['activeCustomers'] as num?)?.toInt() ?? 0) + 1;
          map['totalDepositsHeld'] = ((map['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0) + customer.securityDeposit;

          if (customer.securityDeposit > 0 && customer.paymentMode == 'Cash') {
            map['pendingCashBalance'] = ((map['pendingCashBalance'] as num?)?.toDouble() ?? 0.0) + customer.securityDeposit;
            map['_lastUpdateBalance'] = map['pendingCashBalance'];
          }

          return Transaction.success(map);
        });

        if (!salesmanTx.committed) {
          throw Exception('Failed to update salesman stats. Please try again.');
        }
      }

      // Increment Agency Total Count with Limit Check
      if (agencyId.isNotEmpty) {
        final agencyTx = await agencyRef.runTransaction((Object? data) {
          if (data == null) return Transaction.abort();
          final map = Map<String, dynamic>.from(data as Map);
          final totalCount = (map['totalCustomersCount'] as num?)?.toInt() ?? 0;
          final maxTotal = (map['maxCustomers'] as num?)?.toInt() ?? 500;

          if (totalCount >= maxTotal) {
            return Transaction.abort(); // Agency limit reached
          }

          map['totalCustomersCount'] = totalCount + 1;
          return Transaction.success(map);
        });

        if (!agencyTx.committed) {
          // Rollback Salesman increment if Agency limit fails
          if (salesmanId.isNotEmpty) {
            final updates = <String, Object?>{
              'customerCount': ServerValue.increment(-1),
              'activeCustomers': ServerValue.increment(-1),
              'totalDepositsHeld': ServerValue.increment(-customer.securityDeposit),
            };
            if (customer.securityDeposit > 0 && customer.paymentMode == 'Cash') {
              updates['pendingCashBalance'] = ServerValue.increment(-customer.securityDeposit);
            }
            await salesmanRef.update(updates);
          }
          throw Exception('Agency-wide customer limit (Subscription) has been reached.');
        }
      }

      // 2. Add Customer Record
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd').format(now);
      final timeStr = DateFormat('HHmmss').format(now);
      final safeSalesmanId = salesmanId.replaceAll(RegExp(r'[.#$\[\]]'), '_'); 
      final customCustomerId = '${dateStr}_${safeSalesmanId}_$timeStr';

      final ref = _database.ref().child('Customers').child(customCustomerId);
      
      final customerModel = CustomerModel(
        id: customCustomerId,
        agencyId: agencyId,
        salesmanId: salesmanId,
        name: customer.name,
        phone: customer.phone,
        address: customer.address,
        status: customer.status,
        securityDeposit: customer.securityDeposit,
        pendingBalance: customer.pendingBalance,
        bottleBalance: customer.bottleBalance,
        isRefunded: customer.isRefunded,
        paymentMode: customer.paymentMode,
        createdAt: now,
        updatedId: customer.updatedId,
        updateAt: customer.updateAt,
        zone: customer.zone,
      );
      
      await ref.set(customerModel.toMap());

      // Record Deposit Transaction
      if (customer.securityDeposit > 0) {
        // Ensure Transaction ID is unique even if created same second
        // Adding a small delay or suffix if needed, but for now milliseconds might differ?
        // Actually, user requested strict `Date_SalesmanId_Time`.
        // If we strictly follow that, we might collide if multiple tx/cust created same second.
        // But here we create 1 cust + 1 tx.
        // Let's use the same timestamp for both to link them? 
        // Or generate a new timestamp for the Transaction to distinguish (if >1s elapses or we force it).
        // Let's use `DateTime.now()` again for the transaction to get a potentially slightly later time,
        // OR simply append `_Dep` for clarity/uniqueness if permitted.
        // User requested: `Date_SalesmanId_Time`.
        // If I use the SAME string, it's fine because they are in different collections (Customers vs Transactions).
        
        final txTime = DateTime.now();
        // If execution is fast, txTime might be same second as `now`.
        // To ensure uniqueness within `Transactions` collection (if another tx happened same sec?),
        // we might adding milliseconds?
        // User example: `20240212_Salesman123_143005`.
        // I will stick to the requested format. 
        // If I use `DateTime.now()`, it's likely fine.
        
        final txDateStr = DateFormat('yyyyMMdd').format(txTime);
        final txTimeStr = DateFormat('HHmmss').format(txTime);
        // Check if same as customer?
        String customTxId = '${txDateStr}_${safeSalesmanId}_$txTimeStr';
        
        // If it matches customer ID (which is in Customers), it's fine for Transactions.
        // IMPORTANT: If a REGULAR transaction happened at the exact same second, we have a collision.
        // But regular transactions are manual. This is automatic. Unlikely to collide.
        
        final txRef = _database.ref().child('Transactions').child(customTxId);
        
        await txRef.set({
          'id': customTxId, // Add ID to the body too for consistency
          'salesmanId': customer.salesmanId,
          'customerId': customCustomerId,
          'timestamp': txTime.toIso8601String(),
          'type': 'Deposit',
          'amount': customer.securityDeposit,
          'amountReceived': customer.securityDeposit,
          'paymentMode': customer.paymentMode, // Use selected payment mode
          'cansDelivered': 0,
          'emptyCollected': 0,
          'whatsappReceiptSent': false,
          'notes': 'Initial Security Deposit',
          'previousBalance': customer.pendingBalance, // Usually 0
          'currentBalance': customer.pendingBalance, // Deposit doesn't affect pending money
        });

        // Update Stock Log Collection (only if assigned)
        if (customer.salesmanId.isNotEmpty) {
          final dateKey = txTime.toIso8601String().substring(0, 10).replaceAll('-', '_');
          final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${customer.salesmanId}');
          await logRef.runTransaction((Object? post) {
            final logMap = post == null ? <String, dynamic>{} : Map<String, dynamic>.from(post as Map);
            
            // Robust Initialization
            if (!logMap.containsKey('date')) {
              logMap['date'] = txTime.toIso8601String().substring(0, 10);
              logMap['salesmanId'] = customer.salesmanId;
            }
            
            logMap['openingStock'] ??= 0;
            logMap['loaded'] ??= 0;
            logMap['totalDelivered'] ??= 0;
            logMap['totalEmptyCollected'] ??= 0;
            logMap['damaged'] ??= 0;
            logMap['closingStock'] ??= 0;
            logMap['actualClosingStock'] ??= 0;
            logMap['mismatchCount'] ??= 0;
            logMap['isReconciled'] ??= false;
            logMap['todayCollection'] ??= 0.0;
            logMap['cashCollected'] ??= 0.0;
            logMap['onlineCollected'] ??= 0.0;

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
        await customerRef.update({
          'status': status,
          'updatedId': salesmanId,
          'updateAt': DateTime.now().toIso8601String(),
        });

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
        agencyId: customer.agencyId,
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
        createdAt: customer.createdAt,
        updatedId: customer.updatedId,
        updateAt: customer.updateAt,
        zone: customer.zone,
      );
      await ref.update(customerModel.toMap());
      
      // 3. Handle Deposit Difference
      if (depositDiff != 0) {
        // Update Salesman
        final salesmanRef = _database.ref().child('Salesmen/${customer.salesmanId}');
        final updates = <String, Object?>{
          'totalDepositsHeld': ServerValue.increment(depositDiff),
        };
        if (customer.paymentMode == 'Cash') {
          updates['pendingCashBalance'] = ServerValue.increment(depositDiff);
        }
        await salesmanRef.update(updates);

        // Record Transaction
        final txRef = _database.ref().child('Transactions').push();
        
        if (depositDiff > 0) {
          // Additional Deposit
          await txRef.set({
            'salesmanId': customer.salesmanId,
            'customerId': customer.id,
            'zone': customer.zone,
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'Deposit',
            'amount': depositDiff,
            'amountReceived': depositDiff,
            'paymentMode': customer.paymentMode, 
            'cansDelivered': 0,
            'emptyCollected': 0,
            'whatsappReceiptSent': false,
            'notes': 'Security Deposit Increased',
            'previousBalance': customer.pendingBalance,
            'currentBalance': customer.pendingBalance,
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
            'previousBalance': customer.pendingBalance,
            'currentBalance': customer.pendingBalance,
            'zone': customer.zone,
          });
        }

        // Update Stock Log Collection
        final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
        final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${customer.salesmanId}');
        await logRef.runTransaction((Object? post) {
            final logMap = post == null ? <String, dynamic>{} : Map<String, dynamic>.from(post as Map);
            
            // Robust Initialization
            if (!logMap.containsKey('date')) {
              logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
              logMap['salesmanId'] = customer.salesmanId;
            }

            logMap['openingStock'] ??= 0;
            logMap['loaded'] ??= 0;
            logMap['totalDelivered'] ??= 0;
            logMap['totalEmptyCollected'] ??= 0;
            logMap['damaged'] ??= 0;
            logMap['closingStock'] ??= 0;
            logMap['actualClosingStock'] ??= 0;
            logMap['mismatchCount'] ??= 0;
            logMap['isReconciled'] ??= false;
            logMap['todayCollection'] ??= 0.0;
            logMap['cashCollected'] ??= 0.0;
            logMap['onlineCollected'] ??= 0.0;

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
        'updatedId': customer.updatedId ?? customer.salesmanId,
        'updateAt': (customer.updateAt ?? DateTime.now()).toIso8601String(),
      });

      // 2. Update Salesman (Reduce Total Deposits Held, Count, and Pending Cash)
      final salesmanRef = _database.ref().child('Salesmen/${customer.salesmanId}');
      
      await salesmanRef.runTransaction((Object? data) {
        if (data == null) return Transaction.abort();
        final map = Map<String, dynamic>.from(data as Map);
        
        map['totalDepositsHeld'] = ((map['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0) - deposit;
        map['activeCustomers'] = ((map['activeCustomers'] as num?)?.toInt() ?? 0) - 1;
        map['customerCount'] = ((map['customerCount'] as num?)?.toInt() ?? 0) - 1;
        
        // Decrease salesman's physical cash debt by the amount they just gave back
        if (refundAmount > 0) {
          final double currentPending = (map['pendingCashBalance'] as num?)?.toDouble() ?? 0.0;
          map['pendingCashBalance'] = currentPending - refundAmount;
          map['_lastUpdateBalance'] = map['pendingCashBalance'];
        }
        
        return Transaction.success(map);
      });

      // 3. Update Agency Total Count (Free up Subscription space)
      if (customer.agencyId.isNotEmpty) {
        final agencyRef = _database.ref().child('Agencies/${customer.agencyId}');
        await agencyRef.update({
          'totalCustomersCount': ServerValue.increment(-1),
        });
      }

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
          'previousBalance': pending, // pendingBalance doesn't change on pure refund
          'currentBalance': pending,
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
          'previousBalance': pending,
          'currentBalance': adjustedPending,
        });
      }
      
      // Update Stock Log for Settlement
      final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
      final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${customer.salesmanId}');
      await logRef.runTransaction((Object? post) {
          final logMap = post == null ? <String, dynamic>{} : Map<String, dynamic>.from(post as Map);
          
          // Robust Initialization
          if (!logMap.containsKey('date')) {
            logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
            logMap['salesmanId'] = customer.salesmanId;
          }

          logMap['openingStock'] ??= 0;
          logMap['loaded'] ??= 0;
          logMap['totalDelivered'] ??= 0;
          logMap['totalEmptyCollected'] ??= 0;
          logMap['damaged'] ??= 0;
          logMap['closingStock'] ??= 0;
          logMap['actualClosingStock'] ??= 0;
          logMap['mismatchCount'] ??= 0;
          logMap['isReconciled'] ??= false;
          logMap['todayCollection'] ??= 0.0;
          logMap['cashCollected'] ??= 0.0;
          logMap['onlineCollected'] ??= 0.0;

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

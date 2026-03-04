import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/stock/domain/repositories/inventory_repository.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';
import 'package:hydroflow/features/stock/data/models/stock_log_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final FirebaseDatabase _database;

  InventoryRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<StockLog?> getTodayStockLogStream(String salesmanId) {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    
    // Enable synchronization for today's logs
    logRef.keepSynced(true);
    
    // Also keep the salesman's main stock record synced
    _database.ref().child('Salesmen').child(salesmanId).child('currentStock').keepSynced(true);

    return logRef.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return StockLogModel.fromMap(data);
      }
      return null;
    }).handleError((error) {
       print('Error in getTodayStockLogStream: $error');
       throw error; 
    });
  }

  @override
  Stream<Map<String, int>> getAgencyWarehouseStock(String agencyId) {
    final ref = _database.ref().child('Agencies').child(agencyId).child('stock');
    ref.keepSynced(true);
    
    return ref.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return {
          'fullBottles': (data['fullCans'] as num?)?.toInt() ?? 0,
          'emptyBottles': (data['emptyCans'] as num?)?.toInt() ?? 0,
          'damagedBottles': (data['damagedCans'] as num?)?.toInt() ?? 0,
        };
      }
      return {'fullBottles': 0, 'emptyBottles': 0, 'damagedBottles': 0};
    }).handleError((error) {
       print('Error in getAgencyWarehouseStock: $error');
       throw error;
    });
  }

  @override
  Future<void> addWarehouseStock({required String agencyId, required int quantity}) async {
    final ref = _database.ref().child('Agencies').child(agencyId).child('stock');
    await ref.runTransaction((Object? currentData) {
      final stockMap = currentData == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(currentData as Map);
          
      stockMap['fullCans'] ??= 0;
      final currentFull = (stockMap['fullCans'] as num).toInt();
      stockMap['fullCans'] = currentFull + quantity;
      
      return Transaction.success(stockMap);
    });
    
    // Log this action in Agency History (Optional but good for audit)
    final historyRef = _database.ref().child('Agency_Stock_History').push();
    await historyRef.set({
      'agencyId': agencyId,
      'date': DateTime.now().toIso8601String(),
      'type': 'Purchase',
      'quantity': quantity,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> addStock({required String salesmanId, required int quantity, String? agencyId}) async {
    // 1. If AgencyId is provided (Trading Mode), we must DEDUCT from Warehouse first
    if (agencyId != null && agencyId.isNotEmpty) {
      final warehouseRef = _database.ref().child('Agencies').child(agencyId).child('stock');
      final transactionResult = await warehouseRef.runTransaction((Object? currentData) {
        final stockMap = currentData == null 
            ? <String, dynamic>{} 
            : Map<String, dynamic>.from(currentData as Map);
            
        stockMap['fullCans'] ??= 0;
        final currentFull = (stockMap['fullCans'] as num).toInt();
        
        if (currentFull < quantity) {
          return Transaction.abort(); // Not enough stock in Godown
        }
        
        stockMap['fullCans'] = currentFull - quantity;
        return Transaction.success(stockMap);
      });

      if (!transactionResult.committed) {
         throw Exception("Insufficient stock in Warehouse/Godown to load vehicle.");
      }
      
      // Log the Load Action
      final historyRef = _database.ref().child('Agency_Stock_History').push();
      final now = DateTime.now();
      final dateKey = now.toIso8601String().substring(0, 10).replaceAll('-', '_');
      
      await historyRef.set({
        'agencyId': agencyId,
        'date': now.toIso8601String(),
        'type': 'Load',
        'quantity': quantity,
        'targetUserId': salesmanId,
        'timestamp': ServerValue.timestamp,
      });

      // Update Warehouse Stock Log (Internal Distribution)
      final warehouseLogRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$agencyId');
      final stockSnapshot = await _database.ref().child('Agencies').child(agencyId).child('stock').get();
      final stockData = stockSnapshot.value as Map?;
      final currentWarehouseStock = (stockData?['fullCans'] as num?)?.toInt() ?? 0;

      await warehouseLogRef.runTransaction((Object? post) {
        final logMap = post == null 
            ? <String, dynamic>{} 
            : Map<String, dynamic>.from(post as Map);

        if (!logMap.containsKey('date')) {
          logMap['date'] = now.toIso8601String().substring(0, 10);
          logMap['agencyId'] = agencyId;
          logMap['salesmanId'] = agencyId; // Changed from '' to agencyId
        }
        
        logMap['openingStock'] ??= 0;
        if ((logMap['openingStock'] == 0) && !logMap.containsKey('openingStock_set')) {
          logMap['openingStock'] = currentWarehouseStock + quantity; // +quantity because we already deducted from warehouseRef
        }

        logMap['loaded'] ??= 0;
        final currentDelivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
        logMap['totalDelivered'] = currentDelivered + quantity;
        logMap['damaged'] ??= 0;
        
        final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
        final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
        final delivered = logMap['totalDelivered'] as int;
        final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
        
        logMap['closingStock'] = opening + loaded - delivered - damaged;

        return Transaction.success(logMap);
      });
    }

    // 2. Proceed to Add to Salesman Vehicle using existing logic
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    final salesmanStockRef = _database.ref().child('Salesmen').child(salesmanId).child('currentStock');

    // Get current stock for carry forward calculation - FALLBACK
    final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').get();
    final currentStockInVan = (salesmanSnapshot.value as num?)?.toInt() ?? 0;

    // Fetch carry forward from previous log
    int carryForwardStock = 0;
    try {
      final query = _database.ref()
          .child('Stock_logs')
          .orderByChild('salesmanId')
          .equalTo(salesmanId)
          .limitToLast(2); 
      final snapshot = await query.get();
      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final sortedKeys = data.keys.toList()..sort();
        for (var i = sortedKeys.length - 1; i >= 0; i--) {
           final key = sortedKeys[i];
           final log = Map<String, dynamic>.from(data[key]);
           if (log['date'] != DateTime.now().toIso8601String().substring(0, 10)) {
             final isReconciled = log['isReconciled'] == true;
             carryForwardStock = isReconciled
                 ? ((log['actualClosingStock'] as num?)?.toInt() ?? 0)
                 : ((log['closingStock'] as num?)?.toInt() ?? 0);
             break;
           }
        }
      }
    } catch (_) {}

    final openingStockToUse = carryForwardStock > 0 ? carryForwardStock : currentStockInVan;

    // 3. Update log
    await logRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);

      // Robust Initialization: Ensure all required fields exist
      if (!logMap.containsKey('date')) {
        logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
        logMap['salesmanId'] = salesmanId;
        if (agencyId != null) logMap['agencyId'] = agencyId; // Add agencyId to logs too
      }
      
      // Initialize counters if missing (e.g. if log was created by a deposit)
      logMap['openingStock'] ??= 0;
      logMap['loaded'] ??= 0;
      logMap['totalDelivered'] ??= 0;
      logMap['totalEmptyCollected'] ??= 0;
      logMap['damaged'] ??= 0;
      logMap['closingStock'] ??= 0;
      logMap['actualClosingStock'] ??= 0;
      logMap['mismatchCount'] ??= 0;
      logMap['isReconciled'] ??= logMap['isReconciled'] ?? false;
      logMap['todayCollection'] ??= 0.0;
      logMap['cashCollected'] ??= 0.0;
      logMap['onlineCollected'] ??= 0.0;
      
      // If openingStock was never set (e.g. first load of the day), we treat this as Opening Stock
      if (logMap['openingStock'] == 0 && !logMap.containsKey('openingStock_set')) {
        logMap['openingStock'] = openingStockToUse + quantity;
        logMap['openingStock_set'] = true; // Mark as set so subsequent loads go to 'loaded'
      } else {
        final currentLoaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
        logMap['loaded'] = currentLoaded + quantity;
      }

      final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
      final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      
      logMap['closingStock'] = opening + loaded - delivered - damaged;


      return Transaction.success(logMap);
    });

    // 4. Increment currentStock
    await salesmanStockRef.runTransaction((Object? currentData) {
      final currentStock = (currentData as num?)?.toInt() ?? 0;
      return Transaction.success(currentStock + quantity);
    });
  }

  @override
  Future<void> recordDamagedStock({required String salesmanId, required int quantity}) async {
    final ref = _database.ref();

    final stockRef = ref.child('Salesmen').child(salesmanId).child('currentStock');

    await stockRef.runTransaction((Object? currentData) {
      if (currentData == null) {
        // Can't remove from null, safely return 0 or handleError
        return Transaction.abort(); 
      }
      
      final currentStock = (currentData as num).toInt();
      if (currentStock < quantity) {
          // Prevent negative stock
         return Transaction.abort(); 
      }
      
      return Transaction.success(currentStock - quantity);
    });

    // Get current stock for carry forward calculation (FALLBACK)
    final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').get();
    final currentStockInVan = (salesmanSnapshot.value as num?)?.toInt() ?? 0;

    // Fetch carry forward logic
    int carryForwardStock = 0;
    try {
      final query = _database.ref()
          .child('Stock_logs')
          .orderByChild('salesmanId')
          .equalTo(salesmanId)
          .limitToLast(2); 
      final snapshot = await query.get();
      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final sortedKeys = data.keys.toList()..sort();
        for (var i = sortedKeys.length - 1; i >= 0; i--) {
           final key = sortedKeys[i];
           final log = Map<String, dynamic>.from(data[key]);
           if (log['date'] != DateTime.now().toIso8601String().substring(0, 10)) {
             final isReconciled = log['isReconciled'] == true;
             carryForwardStock = isReconciled
                 ? ((log['actualClosingStock'] as num?)?.toInt() ?? 0)
                 : ((log['closingStock'] as num?)?.toInt() ?? 0);
             break;
           }
        }
      }
    } catch (_) {}

    final openingStockToUse = carryForwardStock > 0 ? carryForwardStock : currentStockInVan;

    // Upload damaged log
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    
    // Increment damaged count transactionally
    await logRef.runTransaction((Object? post) {
       final logMap = post == null 
           ? <String, dynamic>{} 
           : Map<String, dynamic>.from(post as Map);

      // Robust Initialization
      if (!logMap.containsKey('date')) {
        logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
        logMap['salesmanId'] = salesmanId;
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

      final currentDamaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      logMap['damaged'] = currentDamaged + quantity;
      
      final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
      final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      logMap['closingStock'] = opening + loaded - delivered - logMap['damaged'];

       return Transaction.success(logMap);
    });
  }

  @override
  Future<void> setOpeningStock({required String salesmanId, required int quantity, String? agencyId}) async {
  // 1. If AgencyId is provided (Trading Mode), we must DEDUCT from Warehouse first
  if (agencyId != null && agencyId.isNotEmpty) {
    final warehouseRef = _database.ref().child('Agencies').child(agencyId).child('stock');
    final transactionResult = await warehouseRef.runTransaction((Object? currentData) {
      final stockMap = currentData == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(currentData as Map);
          
      stockMap['fullCans'] ??= 0;
      final currentFull = (stockMap['fullCans'] as num).toInt();
      
      if (currentFull < quantity) {
        return Transaction.abort(); // Not enough stock in Godown
      }
      
      stockMap['fullCans'] = currentFull - quantity;
      return Transaction.success(stockMap);
    });

    if (!transactionResult.committed) {
       throw Exception("Insufficient stock in Warehouse/Godown to set opening stock.");
    }
    
    // Log the Setup Action
    final historyRef = _database.ref().child('Agency_Stock_History').push();
    await historyRef.set({
      'agencyId': agencyId,
      'date': DateTime.now().toIso8601String(),
      'type': 'Setup(Opening)',
      'quantity': quantity,
      'targetUserId': salesmanId,
      'timestamp': ServerValue.timestamp,
    });
  }

  final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
  final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
  
  await logRef.runTransaction((Object? post) {
    final logMap = post == null 
        ? <String, dynamic>{} 
        : Map<String, dynamic>.from(post as Map);

    // Robust Initialization
    if (!logMap.containsKey('date')) {
      logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
      logMap['salesmanId'] = salesmanId;
      if (agencyId != null) logMap['agencyId'] = agencyId; 
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

    final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
    final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
    final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
    
    final expectedClosing = quantity + loaded - delivered - damaged;
    
    logMap['openingStock'] = quantity;
    logMap['closingStock'] = expectedClosing;
    logMap['openingStock_set'] = true; // Flag for UI/Repository logic

    return Transaction.success(logMap);
  });

  // Re-reading log to sync currentStock
  final snapshot = await logRef.get();
  if (snapshot.exists) {
     final data = Map<String, dynamic>.from(snapshot.value as Map);
     final closing = (data['closingStock'] as num?)?.toInt() ?? quantity;
     await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').set(closing);
  }
}

  @override
  Future<void> reconcileStock({required String salesmanId, required int physicalCount}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    
    await logRef.runTransaction((Object? post) {
      if (post == null) return Transaction.abort();
      
      final logMap = Map<String, dynamic>.from(post as Map);
      
      final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
      final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      
      final expectedClosing = opening + loaded - delivered - damaged;
      final mismatch = physicalCount - expectedClosing;
      
      logMap['closingStock'] = expectedClosing; // Calculated
      logMap['actualClosingStock'] = physicalCount; // Physical
      logMap['mismatchCount'] = mismatch;
      logMap['isReconciled'] = true;
      
      return Transaction.success(logMap);
    });

    // We also update currentStock to match physicalCount because that's the REAL truth now.
    await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').set(physicalCount);
  }

  @override
  Future<void> recordDailyBottleSnapshot({required String salesmanId, required int totalBottles}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');

    await logRef.runTransaction((Object? post) {
      if (post == null) return Transaction.abort();
      
      final logMap = Map<String, dynamic>.from(post as Map);
      logMap['totalBottlesWithCustomers'] = totalBottles;
      
      return Transaction.success(logMap);
    });
  }

  @override
  Future<bool> checkStockLogsExist(String salesmanId) async {
    try {
      final query = _database.ref()
          .child('Stock_logs')
          .orderByChild('salesmanId')
          .equalTo(salesmanId);
      final snapshot = await query.get().timeout(const Duration(seconds: 5));
      
      if (!snapshot.exists) return false;
      
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      // Check if any of the logs for this salesman have been explicitly setup
      return data.values.any((log) {
        if (log is Map) {
          // Check for the explicit flag OR a non-zero openingStock
       
          final int openingStock = (log['openingStock'] as num?)?.toInt() ?? 0;
          
          return openingStock > 0;
        }
        return false;
      });


    } catch (e) {
      return false; 
    }
  }

  // ---------------- AGENCY STOCK LOG IMPLEMENTATION ----------------

  @override
  Stream<StockLog?> getAgencyStockLogStream(String agencyId) {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$agencyId');
    
    logRef.keepSynced(true);
    _database.ref().child('Agencies').child(agencyId).child('stock').keepSynced(true);

    return logRef.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return StockLogModel.fromMap(data);
      }
      return null;
    }).handleError((error) {
       print('Error in getAgencyStockLogStream: $error');
       throw error; 
    });
  }

  @override
  Future<void> setAgencyOpeningStock({required String agencyId, required int quantity}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$agencyId');
    
    await logRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);

      if (!logMap.containsKey('date')) {
        logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
        logMap['agencyId'] = agencyId; 
        logMap['salesmanId'] = agencyId; // Changed from '' to agencyId
      }
      
      logMap['openingStock'] ??= 0;
      logMap['loaded'] ??= 0;
      logMap['totalDelivered'] ??= 0; // Distributed to Salesmen
      logMap['damaged'] ??= 0;
      logMap['closingStock'] ??= 0;
      
      logMap['openingStock'] = quantity;
      
      final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      
      logMap['closingStock'] = quantity + loaded - delivered - damaged;
      logMap['openingStock_set'] = true;

      return Transaction.success(logMap);
    });

    // Sync to Agency Warehouse Stock
    final snapshot = await logRef.get();
    if (snapshot.exists) {
       final data = Map<String, dynamic>.from(snapshot.value as Map);
       final closing = (data['closingStock'] as num?)?.toInt() ?? quantity;
       await _updateAgencyWarehouseCount(agencyId, closing);
    }
  }

  @override
  Future<void> addAgencyPurchaseStock({required String agencyId, required int quantity}) async {
    // Purchase adds to loaded stock without consuming empties
    await _addAgencyStockWithLog(agencyId: agencyId, quantity: quantity, type: 'Purchase');
  }

  @override
  Future<void> addAgencyRefillStock({required String agencyId, required int quantity}) async {
    // Refill adds to loaded stock AND consumes empties
    
    // 1. Decrement empties first
    final agencyStockRef = _database.ref().child('Agencies').child(agencyId).child('stock');
    final transactionResult = await agencyStockRef.runTransaction((Object? post) {
      final stockMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);
          
      int currentEmpties = (stockMap['emptyCans'] as num?)?.toInt() ?? 0;
      if (currentEmpties < quantity) {
        return Transaction.abort(); // Prevent negative empties
      }
      stockMap['emptyCans'] = currentEmpties - quantity;
      
      return Transaction.success(stockMap);
    });

    if (!transactionResult.committed) {
       throw Exception("Not enough empty bottles available in Warehouse for refill.");
    }

    // 2. Add full stock and log
    await _addAgencyStockWithLog(agencyId: agencyId, quantity: quantity, type: 'Refill');
  }

  Future<void> _addAgencyStockWithLog({required String agencyId, required int quantity, required String type}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$agencyId');

    final stockSnapshot = await _database.ref().child('Agencies').child(agencyId).child('stock').get();
    final stockData = stockSnapshot.value as Map?;
    final currentWarehouseStock = (stockData?['fullCans'] as num?)?.toInt() ?? 0;

    await logRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);

      if (!logMap.containsKey('date')) {
        logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
        logMap['agencyId'] = agencyId;
        logMap['salesmanId'] = '';
      }
      
      logMap['openingStock'] ??= 0;
      
      if ((logMap['openingStock'] == 0) && !logMap.containsKey('openingStock_set')) {
        logMap['openingStock'] = currentWarehouseStock;
      }

      logMap['loaded'] ??= 0;
      logMap['totalDelivered'] ??= 0;
      logMap['damaged'] ??= 0;
      
      final currentLoaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      logMap['loaded'] = currentLoaded + quantity;
      
      final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      
      logMap['closingStock'] = opening + logMap['loaded'] - delivered - damaged;

      return Transaction.success(logMap);
    });

    final snapshot = await logRef.get();
    if (snapshot.exists) {
       final data = Map<String, dynamic>.from(snapshot.value as Map);
       final closing = (data['closingStock'] as num?)?.toInt() ?? 0;
       await _updateAgencyWarehouseCount(agencyId, closing);
    }

    // Audit log
    final historyRef = _database.ref().child('Agency_Stock_History').push();
    await historyRef.set({
      'agencyId': agencyId,
      'date': DateTime.now().toIso8601String(),
      'type': type,
      'quantity': quantity,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> recordAgencyDamagedStock({required String agencyId, required int quantity, bool isFromEmpty = false}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$agencyId');
    
    if (isFromEmpty) {
      // 1. Decrement empties and increment damaged in Agency stock node
      final agencyStockRef = _database.ref().child('Agencies').child(agencyId).child('stock');
      final transactionResult = await agencyStockRef.runTransaction((Object? post) {
        final stockMap = post == null 
            ? <String, dynamic>{} 
            : Map<String, dynamic>.from(post as Map);
            
        int currentEmpties = (stockMap['emptyCans'] as num?)?.toInt() ?? 0;
        int currentDamaged = (stockMap['damagedCans'] as num?)?.toInt() ?? 0;
        
        if (currentEmpties < quantity) {
          return Transaction.abort(); // Prevent negative empties
        }
        
        stockMap['emptyCans'] = currentEmpties - quantity;
        stockMap['damagedCans'] = currentDamaged + quantity;
        
        return Transaction.success(stockMap);
      });

      if (!transactionResult.committed) {
         throw Exception("Not enough empty bottles available in Warehouse to mark as damaged.");
      }
    } else {
      // Fetch current warehouse stock (Yesterday's closing / Today's opening)
      final stockSnapshot = await _database.ref().child('Agencies').child(agencyId).child('stock').get();
      final stockData = stockSnapshot.value as Map?;
      final currentWarehouseStock = (stockData?['fullCans'] as num?)?.toInt() ?? 0;

      await logRef.runTransaction((Object? post) {
         final logMap = post == null 
             ? <String, dynamic>{} 
             : Map<String, dynamic>.from(post as Map);

        if (!logMap.containsKey('date')) {
          logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
          logMap['agencyId'] = agencyId;
          logMap['salesmanId'] = agencyId; // Match other logs
        }
        
        logMap['openingStock'] ??= 0;
        
        // Carry Forward Logic
        if ((logMap['openingStock'] == 0) && !logMap.containsKey('openingStock_set')) {
          logMap['openingStock'] = currentWarehouseStock;
        }

        logMap['loaded'] ??= 0;
        logMap['totalDelivered'] ??= 0;
        logMap['damaged'] ??= 0;
        
        final currentDamaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
        logMap['damaged'] = currentDamaged + quantity;
        
        final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
        final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
        final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
        
        logMap['closingStock'] = opening + loaded - delivered - logMap['damaged'];

         return Transaction.success(logMap);
      });

      // Update Agency Warehouse Stock (Full Cans)
      final snapshot = await logRef.get();
      if (snapshot.exists) {
         final data = Map<String, dynamic>.from(snapshot.value as Map);
         final closing = (data['closingStock'] as num?)?.toInt() ?? 0;
         await _updateAgencyWarehouseCount(agencyId, closing);
         
         // Also increment damagedCans in Agency node
         await _database.ref().child('Agencies').child(agencyId).child('stock').child('damagedCans').runTransaction((Object? val) {
            final current = (val as num?)?.toInt() ?? 0;
            return Transaction.success(current + quantity);
         });
      }
    }

    // 3. Audit log for both cases
    final historyRef = _database.ref().child('Agency_Stock_History').push();
    await historyRef.set({
      'agencyId': agencyId,
      'date': DateTime.now().toIso8601String(),
      'type': isFromEmpty ? 'Damage(Empty)' : 'Damage(Full)',
      'quantity': quantity,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> collectEmptyBottles({required String salesmanId, required int quantity, required String agencyId}) async {
    final now = DateTime.now();
    final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
    final agencyStockRef = _database.ref().child('Agencies').child(agencyId).child('stock');
    
    // 1. Transaction to update Salesman and Agency Stock
    await salesmanRef.runTransaction((Object? post) {
      if (post == null) return Transaction.abort();
      final salesmanMap = Map<String, dynamic>.from(post as Map);
      int currentEmpties = (salesmanMap['emptyBottles'] as num?)?.toInt() ?? 0;
      
      if (currentEmpties < quantity) {
        // Option 1: Abort if not enough empties? Or Option 2: Allow negative (means manual correction)?
        // User said "Provision for empty bottle collection". Assume they might collect more than tracked if manual errors exist.
        // Let's allow but maybe cap at 0 if we want strictness.
        // For collection, better to allow what the user sees physically.
      }
      
      salesmanMap['emptyBottles'] = currentEmpties - quantity;
      return Transaction.success(salesmanMap);
    });

    await agencyStockRef.runTransaction((Object? post) {
      final stockMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);
          
      int currentAgencyEmpties = (stockMap['emptyCans'] as num?)?.toInt() ?? 0;
      stockMap['emptyCans'] = currentAgencyEmpties + quantity;
      
      return Transaction.success(stockMap);
    });

    // 2. Log in Agency Stock_logs for daily reports
    final dateKey = now.toIso8601String().substring(0, 10).replaceAll('-', '_');
    final warehouseLogRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$agencyId');
    
    await warehouseLogRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);

      if (!logMap.containsKey('date')) {
        logMap['date'] = now.toIso8601String().substring(0, 10);
        logMap['agencyId'] = agencyId;
        logMap['salesmanId'] = agencyId; // Changed from '' to agencyId
      }
      
      logMap['totalEmptyCollected'] = ((logMap['totalEmptyCollected'] as num?)?.toInt() ?? 0) + quantity;

      return Transaction.success(logMap);
    });

    // 3. Log in history for audit
    final historyRef = _database.ref().child('Agency_Stock_History').push();
    await historyRef.set({
      'agencyId': agencyId,
      'date': now.toIso8601String(),
      'type': 'EmptyCollection',
      'quantity': quantity,
      'targetUserId': salesmanId,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<bool> checkAgencyStockLogsExist(String agencyId) async {
    try {
      final query = _database.ref()
          .child('Stock_logs')
          .orderByChild('agencyId')
          .equalTo(agencyId);
      final snapshot = await query.get().timeout(const Duration(seconds: 5));
      
      if (!snapshot.exists) return false;
      
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return data.values.any((log) {
        if (log is Map) {
          final int openingStock = (log['openingStock'] as num?)?.toInt() ?? 0;
          return openingStock > 0;
        }
        return false;
      });
    } catch (e) {
      return false; 
    }
  }

  Future<void> _updateAgencyWarehouseCount(String agencyId, int count) async {
    await _database.ref().child('Agencies').child(agencyId).child('stock').update({
      'fullCans': count
    });
  }
}

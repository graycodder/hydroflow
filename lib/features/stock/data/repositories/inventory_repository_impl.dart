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
    
    return logRef.onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return StockLogModel.fromMap(data);
      }
      return null;
    });
  }

  @override
  Future<void> addStock({required String salesmanId, required int quantity}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    final salesmanStockRef = _database.ref().child('Salesmen').child(salesmanId).child('currentStock');

    // Get current stock for carry forward calculation
    final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').get();
    final currentStockInVan = (salesmanSnapshot.value as num?)?.toInt() ?? 0;

    // 1. Update log
    await logRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);

      // Initialize if new log for today
      if (!logMap.containsKey('date')) {
         logMap['salesmanId'] = salesmanId;
         logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
         
         // Opening stock is what was already in the van
         logMap['openingStock'] = currentStockInVan;
         // The new quantity is "loaded"
         logMap['loaded'] = quantity;
         
         logMap['totalDelivered'] = 0;
         logMap['totalEmptyCollected'] = 0;
         logMap['damaged'] = 0;
         // Closing stock = carry forward + newly loaded
         logMap['closingStock'] = currentStockInVan + quantity;
         logMap['actualClosingStock'] = 0;
         logMap['mismatchCount'] = 0;
         logMap['isReconciled'] = false;
         logMap['cashCollected'] = 0.0;
         logMap['onlineCollected'] = 0.0;
      } else {
         // Subsequent loads are refills (update loaded)
         final currentLoaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
         final newLoaded = currentLoaded + quantity;
         logMap['loaded'] = newLoaded;
         
         final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
         final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
         final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
         
         logMap['closingStock'] = opening + newLoaded - delivered - damaged;
      }

      return Transaction.success(logMap);
    });

    // 2. Increment currentStock
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

    // Get current stock for carry forward calculation
    final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').get();
    final currentStockInVan = (salesmanSnapshot.value as num?)?.toInt() ?? 0;

    // Upload damaged log
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    
    // Increment damaged count transactionally
    await logRef.runTransaction((Object? post) {
       final logMap = post == null 
           ? <String, dynamic>{} 
           : Map<String, dynamic>.from(post as Map);

       if (!logMap.containsKey('date')) {
          logMap['salesmanId'] = salesmanId;
          logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
          logMap['openingStock'] = (currentStockInVan); // Use captured van stock
          logMap['loaded'] = 0;
          logMap['totalDelivered'] = 0;
          logMap['totalEmptyCollected'] = 0;
          logMap['damaged'] = quantity;
          logMap['closingStock'] = currentStockInVan - quantity; 
          logMap['actualClosingStock'] = 0;
          logMap['mismatchCount'] = 0;
          logMap['isReconciled'] = false;
          logMap['cashCollected'] = 0.0;
          logMap['onlineCollected'] = 0.0;
       } else {
          final currentDamaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
          logMap['damaged'] = currentDamaged + quantity;
          
          final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
          final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
          final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
          logMap['closingStock'] = opening + loaded - delivered - (currentDamaged + quantity);
       }
       return Transaction.success(logMap);
    });
  }

  @override
  Future<void> setOpeningStock({required String salesmanId, required int quantity}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    
    await logRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);

      // Initialize if new
      if (!logMap.containsKey('date')) {
         logMap['salesmanId'] = salesmanId;
         logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
         logMap['loaded'] = 0;
         logMap['totalDelivered'] = 0;
         logMap['damaged'] = 0;
         logMap['actualClosingStock'] = 0;
         logMap['mismatchCount'] = 0;
         logMap['isReconciled'] = false;
      }
      
      final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      
      final expectedClosing = quantity + loaded - delivered - damaged;
      
      logMap['openingStock'] = quantity;
      logMap['closingStock'] = expectedClosing;

      return Transaction.success(logMap);
    });
    
    // Recalculate solely for the purpose of updating Salesman currentStock mostly accurately
    // We can just rely on the same calculation as above.
    // Fetch fresh or just blindly trust the recent calc? 
    // Ideally we trust the transaction result but we are in a separate one for Salesmen.
    // Let's just update Salesman currentStock.
    // To be perfectly safe, we could read the log again, but given we just set it...
    // Let's assume the transaction succeeded. 
    
    // We need 'loaded' etc to calc currentStock for Salesman update.
    // The transaction above updated the log. Let's read it back or re-calc.
    // Re-reading is safer.
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
}

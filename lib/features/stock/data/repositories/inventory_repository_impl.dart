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

    // 1. Update 'loaded' count in log
    await logRef.child('loaded').runTransaction((Object? currentData) {
      final currentLoaded = (currentData as num?)?.toInt() ?? 0;
      return Transaction.success(currentLoaded + quantity);
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

    // Upload damaged log
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    
    // Increment damaged count transactionally
    await logRef.child('damaged').runTransaction((Object? currentData) {
       final currentDamaged = (currentData as num?)?.toInt() ?? 0;
       return Transaction.success(currentDamaged + quantity);
    });
  }

  @override
  Future<void> setOpeningStock({required String salesmanId, required int quantity}) async {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    


    // 2. We should also recalculate closingStock in log if it exists? 
    // For now let's just sync currentStock.

    // 3. Update Salesmen currentStock

    
    // We update currentStock to effectively be: openingStock + loaded - delivered - damaged
    // But if the user is "setting opening stock", they might mean they want the inventory to START at this value.
    // If they already delivered some, maybe it should be adjusted.
    // HOWEVER, the simplest and most "expected" behavior when someone fixes the "Opening Stock" 
    // is that it sets the baseline.
    
    // Let's use a transaction to be safe for the entire log update.
    await logRef.runTransaction((Object? post) {
      final logMap = post == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(post as Map);
      
      final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;
      
      final calculatedCurrent = quantity + loaded - delivered - damaged;
      
      // Update fields
      logMap['salesmanId'] = salesmanId;
      logMap['date'] = DateTime.now().toIso8601String().substring(0, 10);
      logMap['openingStock'] = quantity;
      logMap['closingStock'] = calculatedCurrent; // Update closing for consistency
      
      return Transaction.success(logMap);
    });

    final logSnapshot = await logRef.get();
    if (logSnapshot.exists) {
      final data = Map<String, dynamic>.from(logSnapshot.value as Map);
      final loaded = (data['loaded'] as num?)?.toInt() ?? 0;
      final delivered = (data['totalDelivered'] as num?)?.toInt() ?? 0;
      final damaged = (data['damaged'] as num?)?.toInt() ?? 0;
      
      final newCurrentStock = quantity + loaded - delivered - damaged;
      await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').set(newCurrentStock);
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

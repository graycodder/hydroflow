import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

abstract class InventoryRepository {
  Future<void> addStock({required String salesmanId, required int quantity});
  Future<void> recordDamagedStock({required String salesmanId, required int quantity});
  Future<void> setOpeningStock({required String salesmanId, required int quantity});
  Stream<StockLog?> getTodayStockLogStream(String salesmanId);
  Future<void> reconcileStock({required String salesmanId, required int physicalCount});
}

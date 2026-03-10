import 'package:watermemo/features/stock/domain/entities/stock_log.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';

abstract class InventoryRepository {
  Future<void> addStock({required String salesmanId, required int quantity, String? agencyId});
  Future<void> recordDamagedStock({required String salesmanId, required int quantity});
  Future<void> setOpeningStock({required String salesmanId, required int quantity, String? agencyId});
  Stream<StockLog?> getTodayStockLogStream(String salesmanId);
  Future<void> recordDailyBottleSnapshot({required String salesmanId, required int totalBottles});
  Future<void> reconcileStock({required String salesmanId, required int physicalCount});
  Future<bool> checkStockLogsExist(String salesmanId);
  Stream<Map<String, int>> getAgencyWarehouseStock(String agencyId);
  Future<void> addWarehouseStock({required String agencyId, required int quantity});
  
  // Agency Stock Log Methods
  Stream<StockLog?> getAgencyStockLogStream(String agencyId);
  Future<void> setAgencyOpeningStock({required String agencyId, required int quantity});
  Future<void> addAgencyPurchaseStock({required String agencyId, required int quantity});
  Future<void> addAgencyRefillStock({required String agencyId, required int quantity});
  Future<void> recordAgencyDamagedStock({required String agencyId, required int quantity, bool isFromEmpty = false});
  Future<void> collectEmptyBottles({required String salesmanId, required int quantity, required String agencyId});
  Future<bool> checkAgencyStockLogsExist(String agencyId);
}

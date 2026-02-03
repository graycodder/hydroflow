import 'package:hydroflow/features/stock/domain/repositories/inventory_repository.dart';

class RecordDamagedStockUseCase {
  final InventoryRepository repository;

  RecordDamagedStockUseCase(this.repository);

  Future<void> call({required String salesmanId, required int quantity}) {
    return repository.recordDamagedStock(salesmanId: salesmanId, quantity: quantity);
  }
}

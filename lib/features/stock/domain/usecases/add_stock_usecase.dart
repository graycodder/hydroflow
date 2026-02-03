import 'package:hydroflow/features/stock/domain/repositories/inventory_repository.dart';

class AddStockUseCase {
  final InventoryRepository repository;

  AddStockUseCase(this.repository);

  Future<void> call({required String salesmanId, required int quantity}) {
    return repository.addStock(salesmanId: salesmanId, quantity: quantity);
  }
}

import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';

class SearchCustomersUseCase {
  final CustomerRepository _repository;

  SearchCustomersUseCase(this._repository);

  Future<List<Customer>> call(
    String query, {
    String? salesmanId,
    String? agencyId,
    String? zone,
    int limit = 20,
  }) {
    return _repository.searchCustomers(
      query,
      salesmanId: salesmanId,
      agencyId: agencyId,
      zone: zone,
      limit: limit,
    );
  }
}

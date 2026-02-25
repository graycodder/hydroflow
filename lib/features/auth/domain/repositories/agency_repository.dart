import '../entities/agency.dart';
import '../entities/salesman.dart';

abstract class AgencyRepository {
  Future<void> createAgency(Agency agency);
  Future<Agency?> getAgencyDetails(String agencyId);
  Future<List<Salesman>> getSalesmenByAgency(String agencyId);
  Future<void> updateWarehouseStock(String agencyId, int quantity, String type);
  Future<void> resetDeviceBinding(String salesmanId);
  Future<void> addSalesman(Salesman salesman);
  Future<void> updateSalesman(Salesman salesman);
  Future<bool> isPhoneNumberUnique(String phoneNumber, {String? excludeSalesmanId});
  Future<void> updateAgencySettings(String agencyId, Map<String, dynamic> settings);
  Stream<Agency> getAgencyStream(String agencyId);
}

import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';
import 'package:hydroflow/features/auth/data/models/agency_model.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/data/models/salesman_model.dart';

class AgencyRepositoryImpl implements AgencyRepository {
  final FirebaseDatabase _database;

  AgencyRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<void> createAgency(Agency agency) async {
    try {
      final ref = _database.ref().child('Agencies').child(agency.id);
      final model = AgencyModel(
        id: agency.id,
        name: agency.name,
        ownerId: agency.ownerId,
        contactPhone: agency.contactPhone,
        address: agency.address,
        status: agency.status,
        subscriptionExpiry: agency.subscriptionExpiry,
        warehouseFullStock: agency.warehouseFullStock,
        warehouseEmptyStock: agency.warehouseEmptyStock,
        warehouseDamagedStock: agency.warehouseDamagedStock,
        allowCredit: agency.allowCredit,
        maxCreditLimit: agency.maxCreditLimit,
        createdAt: agency.createdAt,
      );
      await ref.set(model.toMap());
    } catch (e) {
      throw Exception('Failed to create agency: $e');
    }
  }

  @override
  Future<Agency?> getAgencyDetails(String agencyId) async {
    try {
      final ref = _database.ref().child('Agencies').child(agencyId);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        return AgencyModel.fromSnapshot(snapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch agency details: $e');
    }
  }

  @override
  Future<void> updateWarehouseStock(String agencyId, int quantity, String type) async {
    final ref = _database.ref().child('Agencies').child(agencyId).child('stock');
    
    await ref.runTransaction((Object? currentData) {
      final stockMap = currentData == null 
          ? <String, dynamic>{} 
          : Map<String, dynamic>.from(currentData as Map);
          
      stockMap['fullCans'] ??= 0;
      stockMap['emptyCans'] ??= 0;
      stockMap['damagedCans'] ??= 0;

      final currentFull = (stockMap['fullCans'] as num).toInt();
      final currentEmpty = (stockMap['emptyCans'] as num).toInt();

      if (type == 'Purchase') {
        stockMap['fullCans'] = currentFull + quantity;
      } else if (type == 'Load') {
        if (currentFull < quantity) return Transaction.abort();
        stockMap['fullCans'] = currentFull - quantity;
      } else if (type == 'ReturnFull') {
        stockMap['fullCans'] = currentFull + quantity;
      } else if (type == 'ReturnEmpty') {
        stockMap['emptyCans'] = currentEmpty + quantity;
      }

      return Transaction.success(stockMap);
    });
  }
  @override
  Future<List<Salesman>> getSalesmenByAgency(String agencyId) async {
    try {
      final ref = _database.ref().child('Salesmen');
      final snapshot = await ref.orderByChild('agencyId').equalTo(agencyId).get();

      if (snapshot.exists) {
        final salesmen = <Salesman>[];
        for (final child in snapshot.children) {
          salesmen.add(SalesmanModel.fromSnapshot(child));
        }
        return salesmen;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch salesmen: $e');
    }
  }
  @override
  Future<void> resetDeviceBinding(String salesmanId) async {
    try {
      final ref = _database.ref().child('Salesmen').child(salesmanId);
      await ref.update({'deviceId': ''});
    } catch (e) {
      throw Exception('Failed to reset device binding: $e');
    }
  }
  @override
  Future<void> addSalesman(Salesman salesman) async {
    try {
      // 1. Check Max Salesmen Limit
      final agency = await getAgencyDetails(salesman.agencyId);
      if (agency == null) throw Exception('Agency not found');

      final currentSalesmen = await getSalesmenByAgency(salesman.agencyId);
      if (currentSalesmen.length >= agency.maxSalesmen) {
        throw Exception('Maximum limit of ${agency.maxSalesmen} salesmen reached.');
      }

      // 2. Check Quota Allocation Pool
      final alreadyAllocated = currentSalesmen.fold<int>(0, (sum, s) => sum + s.maxCustomers);
      if (alreadyAllocated + salesman.maxCustomers > agency.maxCustomers) {
        throw Exception('Cannot assign quota of ${salesman.maxCustomers}. Only ${agency.maxCustomers - alreadyAllocated} remaining in subscription pool.');
      }
      
      // 3. Add Salesman
      final ref = _database.ref().child('Salesmen').push(); 
      String newId = salesman.id;
      if (newId.isEmpty) {
        newId = ref.key!;
      }
      
      final model = SalesmanModel(
        id: newId,
        name: salesman.name,
        agencyId: salesman.agencyId,
        agencyName: salesman.agencyName,
        role: 'salesman',
        username: salesman.username,
        password: salesman.password,
        currentStock: 0,
        isActive: true,
        address: salesman.address,
        phoneNumber: salesman.phoneNumber,
        zone: salesman.zone,
        customerCount: 0,
        maxCustomers: salesman.maxCustomers,
        totalDepositsHeld: 0,
        createdAt: DateTime.now(),
      );

      await _database.ref().child('Salesmen').child(newId).set(model.toMap());
      
    } catch (e) {
      throw Exception('Failed to add salesman: $e');
    }
  }

  @override
  Future<void> updateSalesman(Salesman salesman) async {
    try {
      if (salesman.id.isEmpty) throw Exception('Salesman ID required for update');

      // 1. Quota Validation
      final agency = await getAgencyDetails(salesman.agencyId);
      if (agency == null) throw Exception('Agency not found');

      final currentSalesmen = await getSalesmenByAgency(salesman.agencyId);
      
      print('DEBUG: Max Customers: ${agency.maxCustomers}');
      
      // Exclude current salesman from sum to check new total
      final otherAllocated = currentSalesmen
          .where((s) => s.id != salesman.id)
          .fold<int>(0, (sum, s) => sum + s.maxCustomers);

      print('DEBUG: Salesman ID: ${salesman.id}');
      print('DEBUG: Other Allocated: $otherAllocated');
      print('DEBUG: New Max Customers: ${salesman.maxCustomers}');
      print('DEBUG: Total Request: ${otherAllocated + salesman.maxCustomers}');
          
      if (otherAllocated + salesman.maxCustomers > agency.maxCustomers) {
        throw Exception('Quota Update Failed. Only ${agency.maxCustomers - otherAllocated} remaining in subscription pool.');
      }

      // 2. Prepare Update Map
      final Map<String, dynamic> updates = {
        'name': salesman.name,
        'phoneNumber': salesman.phoneNumber,
        'zone': salesman.zone,
        'maxCustomers': salesman.maxCustomers,
      };

      // Only update password if provided (non-empty)
      if (salesman.password.isNotEmpty) {
        updates['password'] = salesman.password;
      }
      
      // 3. Update Firebase
      await _database.ref().child('Salesmen').child(salesman.id).update(updates);

    } catch (e) {
      throw Exception('Failed to update salesman: $e');
    }
  }

  @override
  Future<bool> isPhoneNumberUnique(String phoneNumber, {String? excludeSalesmanId}) async {
    try {
      final normalizedPhone = phoneNumber.trim();
      if (normalizedPhone.isEmpty) return true;

      final ref = _database.ref().child('Salesmen');
      final snapshot = await ref.orderByChild('phoneNumber').equalTo(normalizedPhone).get();

      if (snapshot.exists) {
        for (final child in snapshot.children) {
          final data = child.value as Map?;
          if (data == null) continue;
          
          final foundPhone = (data['phoneNumber'] ?? '').toString().trim();
          
          if (foundPhone == normalizedPhone) {
            if (excludeSalesmanId == null || child.key != excludeSalesmanId) {
              return false;
            }
          }
        }
      }
      return true;
    } catch (e) {
      throw Exception('Failed to check phone number uniqueness: $e');
    }
  }

  @override
  Future<void> updateAgencySettings(String agencyId, Map<String, dynamic> settings) async {
    try {
      final ref = _database.ref().child('Agencies').child(agencyId).child('settings');
      await ref.update(settings);
    } catch (e) {
      throw Exception('Failed to update agency settings: $e');
    }
  }
}

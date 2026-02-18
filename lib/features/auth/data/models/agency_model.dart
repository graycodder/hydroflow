import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

class AgencyModel extends Agency {
  const AgencyModel({
    required super.id,
    required super.name,
    required super.ownerId,
    super.contactPhone,
    super.address,
    super.status,
    super.subscriptionExpiry,
    super.warehouseFullStock,
    super.warehouseEmptyStock,
    super.warehouseDamagedStock,
    super.allowCredit,
    super.maxCreditLimit,
    super.maxSalesmen,
    super.maxCustomers,
    super.totalCustomersCount,
    required super.createdAt,
  });

  factory AgencyModel.fromSnapshot(DataSnapshot snapshot) {
    if (snapshot.value == null) {
      throw Exception('Agency data is null for key: ${snapshot.key}');
    }
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    
    
    // Parse Subscription Data
    Map<String, dynamic>? activeSub;
    final subData = data['subscription'];
    
    if (subData is Map) {
      if (subData.containsKey('maxCustomers')) {
         // Direct structure (User's latest format)
         activeSub = Map<String, dynamic>.from(subData);
      } else if (subData.containsKey('0') && subData['0'] is Map) {
         // Legacy/Nested structure with index keys
         activeSub = Map<String, dynamic>.from(subData['0'] as Map);
      } else if (subData.isNotEmpty) {
         final firstValue = subData.values.first;
         if (firstValue is Map) {
             activeSub = Map<String, dynamic>.from(firstValue);
         }
      }
    } else if (subData is List && subData.isNotEmpty && subData.first is Map) {
       activeSub = Map<String, dynamic>.from(subData.first as Map);
    }

    final stock = data['stock'] as Map?;
    final settings = data['settings'] as Map?;

    // Extract fields from subscription if available, otherwise fallback to root (for legacy/backward compat)
    final subStatus = activeSub?['status'] as String? ?? 'active';
    final subExpiry = activeSub?['expiryDate'] != null
          ? DateTime.tryParse(activeSub!['expiryDate'].toString())
          : null;
    final subMaxCustomers = (activeSub?['maxCustomers'] as num?)?.toInt();
    
    // Root level fallback
    final rootMaxCustomers = (data['maxCustomers'] as num?)?.toInt() ?? 0;

    return AgencyModel(
      id: snapshot.key!,
      name: data['name'] as String? ?? 'Unnamed Agency',
      ownerId: data['ownerId'] as String? ?? '',
      contactPhone: data['contactPhone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      status: subStatus, // Status from subscription
      subscriptionExpiry: subExpiry,
      warehouseFullStock: (stock?['fullCans'] as num?)?.toInt() ?? 0,
      warehouseEmptyStock: (stock?['emptyCans'] as num?)?.toInt() ?? 0,
      warehouseDamagedStock: (stock?['damagedCans'] as num?)?.toInt() ?? 0,
      allowCredit: settings?['allowCredit'] as bool? ?? true,
      maxCreditLimit: (settings?['maxCreditLimit'] as num?)?.toDouble() ?? 5000.0,
      maxSalesmen: (data['maxSalesmen'] as num?)?.toInt() ?? 5,
      maxCustomers: subMaxCustomers ?? rootMaxCustomers, // Prioritize subscription limit
      totalCustomersCount: (data['totalCustomersCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'contactPhone': contactPhone,
      'address': address,
      'maxSalesmen': maxSalesmen,
      'maxCustomers': maxCustomers,
      'totalCustomersCount': totalCustomersCount,
      'subscription': {
        'status': status,
        'expiryDate': subscriptionExpiry?.toIso8601String(),
      },
      'stock': {
        'fullCans': warehouseFullStock,
        'emptyCans': warehouseEmptyStock,
        'damagedCans': warehouseDamagedStock,
      },
      'settings': {
        'allowCredit': allowCredit,
        'maxCreditLimit': maxCreditLimit,
      },
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

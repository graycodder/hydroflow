import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/auth/domain/entities/agency.dart';

class AgencyModel extends Agency {
  const AgencyModel({
    required super.id,
    required super.name,
    required super.ownerId,
    super.contactPhone,
    super.address,
    super.status,
    super.subscriptionId,
    super.subscriptionStartDate,
    super.subscriptionExpiry,
    super.lastNotificationDate,
    super.warehouseFullStock,
    super.warehouseEmptyStock,
    super.warehouseDamagedStock,
    super.allowCredit,
    super.maxCreditLimit,
    super.defaultBottlePrice,
    super.enforceFixedPrice,
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
      if (subData.containsKey('maxCustomers') || subData.containsKey('subEndDate') || subData.containsKey('expiryDate') || subData.containsKey('status')) {
         // Direct structure (User's latest format)
         activeSub = Map<String, dynamic>.from(subData);
      } else if (subData.containsKey('0') && subData['0'] is Map) {
         // Legacy/Nested structure with index keys
         activeSub = Map<String, dynamic>.from(subData['0'] as Map);
      } else if (subData.isNotEmpty) {
         final firstValue = subData.values.first;
         if (firstValue is Map) {
             activeSub = Map<String, dynamic>.from(firstValue);
         } else {
             // Fallback: It's a map but doesn't have nested objects
             activeSub = Map<String, dynamic>.from(subData);
         }
      }
    } else if (subData is List && subData.isNotEmpty && subData.first is Map) {
       activeSub = Map<String, dynamic>.from(subData.first as Map);
    }

    final stock = data['stock'] as Map?;
    final settings = data['settings'] as Map?;

    // Extract fields from subscription if available, otherwise fallback to root (for legacy/backward compat)
    // Status is at root-level agency node (set by admin)
    final rootStatus = data['status'] as String? ?? 'active';
    // subscriptionExpiry: check subscription sub-object first (subEndDate or expiryDate), then root-level fallback
    final subExpiryStr = activeSub?['subEndDate']?.toString() ?? activeSub?['expiryDate']?.toString();
    
    final subExpiry = subExpiryStr != null
          ? DateTime.tryParse(subExpiryStr)
          : (data['subscriptionExpiry'] != null
              ? DateTime.tryParse(data['subscriptionExpiry'].toString())
              : null);
    final subMaxCustomers = (activeSub?['maxCustomers'] as num?)?.toInt();
    
    final subId = activeSub?['subId']?.toString();
    final subStartDateStr = activeSub?['subStartDate']?.toString();
    final subStartDate = subStartDateStr != null ? DateTime.tryParse(subStartDateStr) : null;
    final subLastNotifStr = activeSub?['lastNotification']?.toString();
    final subLastNotifDate = subLastNotifStr != null ? DateTime.tryParse(subLastNotifStr) : null;
    
    // Root level fallback
    final rootMaxCustomers = (data['maxCustomers'] as num?)?.toInt() ?? 0;

    return AgencyModel(
      id: snapshot.key!,
      name: data['name'] as String? ?? 'Unnamed Agency',
      ownerId: data['ownerId'] as String? ?? '',
      contactPhone: data['contactPhone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      status: rootStatus, // Status from root agency node (admin-controlled)
      subscriptionId: subId,
      subscriptionStartDate: subStartDate,
      subscriptionExpiry: subExpiry,
      lastNotificationDate: subLastNotifDate,
      warehouseFullStock: (stock?['fullCans'] as num?)?.toInt() ?? 0,
      warehouseEmptyStock: (stock?['emptyCans'] as num?)?.toInt() ?? 0,
      warehouseDamagedStock: (stock?['damagedCans'] as num?)?.toInt() ?? 0,
      allowCredit: settings?['allowCredit'] as bool? ?? true,
      maxCreditLimit: (settings?['maxCreditLimit'] as num?)?.toDouble() ?? 5000.0,
      defaultBottlePrice: (settings?['defaultBottlePrice'] as num?)?.toDouble() ?? 60.0,
      enforceFixedPrice: settings?['enforceFixedPrice'] as bool? ?? false,
      maxSalesmen: (data['maxSalesmen'] as num?)?.toInt() ?? 0,
      maxCustomers: subMaxCustomers ?? (data['maxCustomers'] as num?)?.toInt() ?? 0,
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
      'status': status, // Also write at root level so admin UI updates are reflected
      'maxSalesmen': maxSalesmen,
      'maxCustomers': maxCustomers,
      'totalCustomersCount': totalCustomersCount,
      'subscription': {
        if (subscriptionId != null) 'subId': subscriptionId,
        if (subscriptionStartDate != null) 'subStartDate': subscriptionStartDate?.toIso8601String(),
        if (subscriptionExpiry != null) 'subEndDate': subscriptionExpiry?.toIso8601String(),
        if (lastNotificationDate != null) 'lastNotification': lastNotificationDate?.toIso8601String(),
      },
      'stock': {
        'fullCans': warehouseFullStock,
        'emptyCans': warehouseEmptyStock,
        'damagedCans': warehouseDamagedStock,
      },
      'settings': {
        'allowCredit': allowCredit,
        'maxCreditLimit': maxCreditLimit,
        'defaultBottlePrice': defaultBottlePrice,
        'enforceFixedPrice': enforceFixedPrice,
      },
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

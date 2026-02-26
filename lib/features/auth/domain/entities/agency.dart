import 'package:equatable/equatable.dart';

class Agency extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String contactPhone;
  final String address;
  final String status;
  final String? subscriptionId;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionExpiry;
  final DateTime? lastNotificationDate;
  final int warehouseFullStock;
  final int warehouseEmptyStock;
  final int warehouseDamagedStock;
  final bool allowCredit;
  final double maxCreditLimit;
  final double defaultBottlePrice;
  final bool enforceFixedPrice;
  final int maxSalesmen;
  final int maxCustomers;
  final int totalCustomersCount;
  final DateTime createdAt;

  const Agency({
    required this.id,
    required this.name,
    required this.ownerId,
    this.contactPhone = '',
    this.address = '',
    this.status = 'active',
    this.subscriptionId,
    this.subscriptionStartDate,
    this.subscriptionExpiry,
    this.lastNotificationDate,
    this.warehouseFullStock = 0,
    this.warehouseEmptyStock = 0,
    this.warehouseDamagedStock = 0,
    this.allowCredit = true,
    this.maxCreditLimit = 5000.0,
    this.defaultBottlePrice = 60.0,
    this.enforceFixedPrice = false,
    this.maxSalesmen = 5,
    this.maxCustomers = 500,
    this.totalCustomersCount = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    ownerId,
    contactPhone,
    address,
    status,
    subscriptionId,
    subscriptionStartDate,
    subscriptionExpiry,
    lastNotificationDate,
    warehouseFullStock,
    warehouseEmptyStock,
    warehouseDamagedStock,
    allowCredit,
    maxCreditLimit,
    defaultBottlePrice,
    enforceFixedPrice,
    maxSalesmen,
    maxCustomers,
    totalCustomersCount,
    createdAt,
  ];

  Agency copyWith({
    bool? enforceFixedPrice,
    bool? allowCredit,
    double? maxCreditLimit,
    double? defaultBottlePrice,
  }) {
    return Agency(
      id: id,
      name: name,
      ownerId: ownerId,
      contactPhone: contactPhone,
      address: address,
      status: status,
      subscriptionId: subscriptionId,
      subscriptionStartDate: subscriptionStartDate,
      subscriptionExpiry: subscriptionExpiry,
      lastNotificationDate: lastNotificationDate,
      warehouseFullStock: warehouseFullStock,
      warehouseEmptyStock: warehouseEmptyStock,
      warehouseDamagedStock: warehouseDamagedStock,
      allowCredit: allowCredit ?? this.allowCredit,
      maxCreditLimit: maxCreditLimit ?? this.maxCreditLimit,
      defaultBottlePrice: defaultBottlePrice ?? this.defaultBottlePrice,
      enforceFixedPrice: enforceFixedPrice ?? this.enforceFixedPrice,
      maxSalesmen: maxSalesmen,
      maxCustomers: maxCustomers,
      totalCustomersCount: totalCustomersCount,
      createdAt: createdAt,
    );
  }
}

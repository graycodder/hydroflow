import 'package:equatable/equatable.dart';

class Agency extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String contactPhone;
  final String address;
  final String status;
  final DateTime? subscriptionExpiry;
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
    this.subscriptionExpiry,
    this.warehouseFullStock = 0,
    this.warehouseEmptyStock = 0,
    this.warehouseDamagedStock = 0,
    this.allowCredit = true,
    this.maxCreditLimit = 5000.0,
    this.defaultBottlePrice = 50.0,
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
    subscriptionExpiry,
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
}

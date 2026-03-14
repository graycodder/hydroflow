import 'package:watermemo/features/customers/domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.agencyId,
    required super.salesmanId,
    required super.name,
    required super.phone,
    required super.address,
    required super.status,
    super.zone = '',
    super.securityDeposit = 0.0,
    super.pendingBalance = 0.0,
    super.bottleBalance = 0,
    super.isRefunded = false,
    super.paymentMode = 'Cash',
    super.createdAt,
    super.updatedId,
    super.updateAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> data) {
    return CustomerModel(
      id: data['id'] as String? ?? '',
      agencyId: data['agencyId'] as String? ?? '',
      salesmanId: data['salesmanId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      zone: data['zone'] as String? ?? '',
      securityDeposit: (data['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      bottleBalance: (data['bottleBalance'] as num?)?.toInt() ?? 0,
      isRefunded: data['isRefunded'] as bool? ?? false,
      paymentMode: data['paymentMode'] as String? ?? 'Cash',
      createdAt: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt'] as String) 
          : null,
      updatedId: data['updatedId'] as String?,
      updateAt: data['updateAt'] != null 
          ? DateTime.tryParse(data['updateAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyId': agencyId,
      'salesmanId': salesmanId,
      'name': name,
      'phone': phone,
      'address': address,
      'status': status,
      'zone': zone,
      'securityDeposit': securityDeposit,
      'pendingBalance': pendingBalance,
      'bottleBalance': bottleBalance,
      'isRefunded': isRefunded,
      'paymentMode': paymentMode,
      'createdAt': createdAt?.toIso8601String(),
      'updatedId': updatedId,
      'updateAt': updateAt?.toIso8601String(),
    };
  }
}

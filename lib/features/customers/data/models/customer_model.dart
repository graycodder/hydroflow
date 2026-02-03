import 'package:hydroflow/features/customers/domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.salesmanId,
    required super.name,
    required super.phone,
    required super.address,
    required super.status,
    super.securityDeposit = 0.0,
    super.pendingBalance = 0.0,
    super.bottleBalance = 0,
    super.isRefunded = false,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> data) {
    return CustomerModel(
      id: data['id'] as String? ?? '',
      salesmanId: data['salesmanId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      status: data['status'] as String? ?? 'Active',
      securityDeposit: (data['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      bottleBalance: (data['bottleBalance'] as num?)?.toInt() ?? 0,
      isRefunded: data['isRefunded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesmanId': salesmanId,
      'name': name,
      'phone': phone,
      'address': address,
      'status': status,
      'securityDeposit': securityDeposit,
      'pendingBalance': pendingBalance,
      'bottleBalance': bottleBalance,
      'isRefunded': isRefunded,
    };
  }
}

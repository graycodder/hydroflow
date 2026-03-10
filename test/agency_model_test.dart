import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watermemo/features/auth/data/models/agency_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';

class MockDataSnapshot extends Mock implements DataSnapshot {
  @override
  final Object? value;
  @override
  final String? key;
  MockDataSnapshot(this.key, this.value);
}

void main() {
  test('AgencyModel parses properly', () {
    final Map<String, dynamic> data = {
      "address": "kochi ",
      "contactPhone": "9995226139",
      "createdAt": 1772097856324,
      "maxCustomers": 1000,
      "maxSalesmen": 2,
      "name": "Test Agent ",
      "ownerId": "1772097856324",
      "status": "active",
      "stock": {
        "damagedCans": 0,
        "emptyCans": 0,
        "fullCans": 900
      },
      "subscription": {
        "lastNotification": "2026-02-26T14:54:25.305230",
        "subEndDate": "2026-03-28T14:54:24.972047",
        "subId": "-OmOFsJB78pA5prQwdXB",
        "subStartDate": "2026-02-26T14:54:24.972047"
      },
      "totalCustomersCount": 1
    };
    
    final snapshot = MockDataSnapshot('AGENCY_TEST_AGENT__1772097856324', data);
    final model = AgencyModel.fromSnapshot(snapshot);
    print('Parsed Expiry (subEndDate): ${model.subscriptionExpiry}');
    print('Is Expired? ${model.subscriptionExpiry == null || model.subscriptionExpiry!.isBefore(DateTime.now())}');
  });
}

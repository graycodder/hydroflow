import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:watermemo/features/reports/domain/repositories/report_repository.dart';
import 'package:watermemo/features/reports/domain/entities/report_entity.dart';

@GenerateMocks([FirebaseDatabase, ReportRepository, DatabaseReference, DataSnapshot, DatabaseEvent])
import 'dashboard_repository_test.mocks.dart';

void main() {
  late DashboardRepositoryImpl repository;
  late MockFirebaseDatabase mockDatabase;
  late MockReportRepository mockReportRepository;
  late MockDatabaseReference mockRef;

  setUp(() {
    mockDatabase = MockFirebaseDatabase();
    mockReportRepository = MockReportRepository();
    mockRef = MockDatabaseReference();
    
    when(mockDatabase.ref()).thenReturn(mockRef);
    
    repository = DashboardRepositoryImpl(
      database: mockDatabase,
      reportRepository: mockReportRepository,
    );
  });

  group('DashboardRepository Tests', () {
    test('getDashboardSummary returns agency data when agencyId is provided', () {
      final mockDate = DateTime.now();
      final mockReport = ReportEntity(
        date: mockDate,
        openingStock: 100,
        closingStock: 150, // currentStock
        stockLoaded: 50,
        totalAvailable: 150,
        deliveredStock: 20,
        damagedStock: 0,
        bottlesDelivered: 20,
        bottlesReturned: 10,
        netBottlesOut: 10,
        totalBottlesWithCustomers: 100,
        totalDeliveries: 20, // todayDeliveries
        totalCollected: 5000, // todayCollection
        cashSales: 2000,
        onlineSales: 3000,
        salesRevenue: 6000, // todaySales
        totalRevenue: 6000,
        totalCreditPending: 1000,
        securityDepositsCollected: 0,
        securityDepositsRefunded: 0,
        netDeposits: 0,
        totalDepositsHeld: 0,
        cashInHand: 2000,
        upiCollections: 3000,
        avgPricePerCan: 300,
        stockTurnover: 0,
        activeCustomers: 50, // activeCustomers
        inactiveCustomers: 5, // inactiveCustomers
        pendingCashBalance: 1000, // pendingAmounts
      );

      when(mockReportRepository.getAgencyDailyReport(any, any))
          .thenAnswer((_) => Stream.value(mockReport));

      final stream = repository.getDashboardSummary(salesmanId: 's1', agencyId: 'a1');

      expectLater(
        stream,
        emitsInOrder([
          isA<dynamic>()
              .having((s) => s.currentStock, 'currentStock', 150)
              .having((s) => s.activeCustomers, 'activeCustomers', 50)
              .having((s) => s.inactiveCustomers, 'inactiveCustomers', 5)
              .having((s) => s.todaySales, 'todaySales', 6000)
              .having((s) => s.todayCollection, 'todayCollection', 5000)
              .having((s) => s.todayDeliveries, 'todayDeliveries', 20)
              .having((s) => s.pendingAmounts, 'pendingAmounts', 1000)
        ]),
      );
    });
  });
}

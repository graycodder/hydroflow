import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:watermemo/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:watermemo/features/stock/presentation/bloc/stock_event.dart';
import 'package:watermemo/features/stock/presentation/bloc/stock_state.dart';
import 'package:watermemo/features/stock/domain/repositories/inventory_repository.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';

@GenerateMocks([InventoryRepository, CustomerRepository])
import 'stock_bloc_test.mocks.dart';

void main() {
  late StockBloc stockBloc;
  late MockInventoryRepository mockInventoryRepository;
  late MockCustomerRepository mockCustomerRepository;

  setUp(() {
    mockInventoryRepository = MockInventoryRepository();
    mockCustomerRepository = MockCustomerRepository();
    stockBloc = StockBloc(
      inventoryRepository: mockInventoryRepository,
      customerRepository: mockCustomerRepository,
    );
  });

  tearDown(() {
    stockBloc.close();
  });

  group('StockBloc Tests', () {
    test('initial state is StockInitial', () {
      expect(stockBloc.state, const StockInitial());
    });

    blocTest<StockBloc, StockState>(
      'emits [StockActionLoading, StockFailure] when StockLoadRequested fails due to 0 quantity',
      build: () => stockBloc,
      act: (bloc) => bloc.add(const StockLoadRequested(salesmanId: 's1', quantity: 0)),
      expect: () => [
        const StockFailure('Quantity must be greater than 0'),
      ],
    );

    blocTest<StockBloc, StockState>(
      'emits [StockActionLoading, StockActionSuccess] when StockLoadRequested is successful',
      build: () {
        when(mockInventoryRepository.addStock(
          salesmanId: anyNamed('salesmanId'),
          quantity: anyNamed('quantity'),
          agencyId: anyNamed('agencyId'),
        )).thenAnswer((_) async => Future.value());
        return stockBloc;
      },
      act: (bloc) => bloc.add(const StockLoadRequested(salesmanId: 's1', quantity: 10)),
      expect: () => [
        const StockActionLoading(),
        const StockActionSuccess('Stock loaded successfully'),
      ],
    );

    blocTest<StockBloc, StockState>(
      'emits [StockFailure] when StockDamagedReported is called with 0 quantity',
      build: () => stockBloc,
      act: (bloc) => bloc.add(const StockDamagedReported(salesmanId: 's1', quantity: 0)),
      expect: () => [
        const StockFailure('Quantity must be greater than 0'),
      ],
    );
    
    blocTest<StockBloc, StockState>(
      'emits [StockActionLoading, StockActionSuccess] when StockDamagedReported is successful',
      build: () {
        when(mockInventoryRepository.recordDamagedStock(
          salesmanId: anyNamed('salesmanId'),
          quantity: anyNamed('quantity'),
        )).thenAnswer((_) async => Future.value());
        return stockBloc;
      },
      act: (bloc) => bloc.add(const StockDamagedReported(salesmanId: 's1', quantity: 5)),
      expect: () => [
        const StockActionLoading(),
        const StockActionSuccess('Damaged stock recorded'),
      ],
    );
  });
}

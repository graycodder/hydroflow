import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_event.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';
import 'package:hydroflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

@GenerateMocks([AuthRepository, AgencyRepository])
import 'auth_bloc_test.mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockAgencyRepository mockAgencyRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAgencyRepository = MockAgencyRepository();
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      agencyRepository: mockAgencyRepository,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Tests', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when AuthLoginRequested fails',
      build: () {
        when(mockAuthRepository.signIn(
          username: anyNamed('username'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Login Failed'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(username: 'user', password: 'pass')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Exception: Login Failed'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthSubscriptionExpired] when AuthStatusChanged with expired salesman',
      build: () => authBloc,
      act: (bloc) {
        final expiredSalesman = Salesman(
          id: 's1',
          name: 'Expired User',
          username: 'expired',
          phoneNumber: '123',
          password: 'abc',
          role: 'salesman',
          agencyId: 'a1',
          isActive: true, // But subscription is expired
          subscriptionExpiry: DateTime.now().subtract(const Duration(days: 1)),
        );
        final agency = Agency(
          id: 'a1',
          name: 'Agency 1',
          ownerId: 'Owner 1',
          contactPhone: '123',
          status: 'active',
          subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now(),
        );
        bloc.add(AuthStatusChanged(expiredSalesman, agency));
      },
      expect: () => [
        isA<AuthSubscriptionExpired>(),
      ],
    );
    
    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when AuthStatusChanged with valid salesman',
      build: () => authBloc,
      act: (bloc) {
        final validSalesman = Salesman(
          id: 's1',
          username: 'valid',
          name: 'Valid User',
          phoneNumber: '123',
          password: 'abc',
          role: 'salesman',
          agencyId: 'a1',
          isActive: true,
          subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
        );
        final validAgency = Agency(
          id: 'a1',
          name: 'Agency 1',
          ownerId: 'Owner 1',
          contactPhone: '123',
          status: 'active',
          subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
          createdAt: DateTime.now(),
        );
        bloc.add(AuthStatusChanged(validSalesman, validAgency));
      },
      expect: () => [
        isA<AuthAuthenticated>(),
      ],
    );
  });
}

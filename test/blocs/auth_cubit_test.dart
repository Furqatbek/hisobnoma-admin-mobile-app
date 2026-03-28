import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hisobnoma/data/models/auth/auth_models.dart';
import 'package:hisobnoma/data/repositories/auth_repository.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeLoginRequest extends Fake implements LoginRequest {}

void main() {
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeLoginRequest());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      final cubit = AuthCubit(authRepository: mockRepository);
      expect(cubit.state, isA<AuthInitial>());
      cubit.close();
    });

    group('checkAuth', () {
      blocTest<AuthCubit, AuthState>(
        'emits AuthAuthenticated when token exists',
        setUp: () {
          when(() => mockRepository.isAuthenticated())
              .thenAnswer((_) async => true);
          when(() => mockRepository.getPermissions())
              .thenAnswer((_) async => ['ADMIN', 'SALES']);
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.checkAuth(),
        expect: () => [
          isA<AuthAuthenticated>()
              .having((s) => s.permissions, 'permissions', ['ADMIN', 'SALES']),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits AuthUnauthenticated when no token',
        setUp: () {
          when(() => mockRepository.isAuthenticated())
              .thenAnswer((_) async => false);
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.checkAuth(),
        expect: () => [isA<AuthUnauthenticated>()],
      );
    });

    group('login', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] on success',
        setUp: () {
          when(() => mockRepository.login(any())).thenAnswer(
            (_) async => const LoginResponse(
              accessToken: 'token',
              refreshToken: 'refresh',
              tokenType: 'Bearer',
              expiresIn: 3600,
              userId: 1,
              tenantId: 1,
              permissions: ['ADMIN'],
            ),
          );
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.login(
          username: 'admin',
          pin: '1234',
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>()
              .having((s) => s.userId, 'userId', 1),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthError] on failure',
        setUp: () {
          when(() => mockRepository.login(any()))
              .thenThrow(Exception('UNAUTHORIZED'));
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.login(
          username: 'admin',
          pin: '0000',
        ),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>()
              .having((s) => s.message, 'message',
                  'Invalid username or PIN. Please try again.'),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits network error message on SocketException',
        setUp: () {
          when(() => mockRepository.login(any()))
              .thenThrow(Exception('SocketException'));
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.login(username: 'admin', pin: '1234'),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message',
              'No internet connection. Please check your network.'),
        ],
      );
    });

    group('logout', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] on success',
        setUp: () {
          when(() => mockRepository.logout()).thenAnswer((_) async {});
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.logout(),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'still logs out on API failure',
        setUp: () {
          when(() => mockRepository.logout())
              .thenThrow(Exception('Network error'));
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.logout(),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hisobnoma/data/models/auth/auth_models.dart';
import 'package:hisobnoma/data/repositories/auth_repository.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeLoginRequest extends Fake implements LoginRequest {}

const _testUsers = [
  UserAccount(
    id: 1,
    username: 'admin',
    firstName: 'System',
    lastName: 'Admin',
    fullName: 'System Admin',
    initials: 'SA',
    hasPin: true,
  ),
  UserAccount(
    id: 2,
    username: 'ahmed',
    firstName: 'Ahmed',
    lastName: '',
    fullName: 'Ahmed',
    initials: 'A',
    hasPin: true,
  ),
];

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
        'emits AuthUnauthenticated then loads users when no token',
        setUp: () {
          when(() => mockRepository.isAuthenticated())
              .thenAnswer((_) async => false);
          when(() => mockRepository.getUsers())
              .thenAnswer((_) async => _testUsers);
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.checkAuth(),
        expect: () => [
          isA<AuthUnauthenticated>(),
          isA<AuthUsersLoaded>()
              .having((s) => s.users.length, 'users.length', 2),
        ],
      );
    });

    group('loadUsers', () {
      blocTest<AuthCubit, AuthState>(
        'emits AuthUsersLoaded on success',
        setUp: () {
          when(() => mockRepository.getUsers())
              .thenAnswer((_) async => _testUsers);
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.loadUsers(),
        expect: () => [
          isA<AuthUsersLoaded>()
              .having((s) => s.users.length, 'users.length', 2),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits AuthError on failure',
        setUp: () {
          when(() => mockRepository.getUsers())
              .thenThrow(Exception('SocketException'));
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.loadUsers(),
        expect: () => [
          isA<AuthError>().having((s) => s.message, 'message',
              'No internet connection. Please check your network.'),
        ],
      );
    });

    group('login', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] on success',
        setUp: () {
          when(() => mockRepository.getUsers())
              .thenAnswer((_) async => _testUsers);
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
        seed: () => AuthAccountSelected(
          users: _testUsers,
          selectedUser: _testUsers[0],
        ),
        act: (cubit) => cubit.login(username: 'admin', pin: '1234'),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>()
              .having((s) => s.userId, 'userId', 1),
        ],
      );

      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthError] on failure with user preserved',
        setUp: () {
          when(() => mockRepository.login(any()))
              .thenThrow(Exception('UNAUTHORIZED'));
        },
        build: () => AuthCubit(authRepository: mockRepository),
        seed: () => AuthAccountSelected(
          users: _testUsers,
          selectedUser: _testUsers[0],
        ),
        act: (cubit) => cubit.login(username: 'admin', pin: '0000'),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>()
              .having((s) => s.message, 'message',
                  'Invalid username or PIN. Please try again.')
              .having((s) => s.selectedUser?.username, 'selectedUser', 'admin'),
        ],
      );
    });

    group('logout', () {
      blocTest<AuthCubit, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated, AuthUsersLoaded] on success',
        setUp: () {
          when(() => mockRepository.logout()).thenAnswer((_) async {});
          when(() => mockRepository.getUsers())
              .thenAnswer((_) async => _testUsers);
        },
        build: () => AuthCubit(authRepository: mockRepository),
        act: (cubit) => cubit.logout(),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
          isA<AuthUsersLoaded>(),
        ],
      );
    });
  });
}

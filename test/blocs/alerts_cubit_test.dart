import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hisobnoma/core/network/api_response.dart';
import 'package:hisobnoma/data/models/alert/alert_models.dart';
import 'package:hisobnoma/data/repositories/alert_repository.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';

class MockAlertRepository extends Mock implements AlertRepository {}

void main() {
  late MockAlertRepository mockRepository;

  final testAlerts = [
    Alert(
      id: 1,
      alertType: AlertType.lowStock,
      title: 'Low Stock',
      message: 'Product A is low',
      priority: AlertPriority.high,
      isRead: false,
      createdAt: DateTime(2026, 3, 15),
    ),
    Alert(
      id: 2,
      alertType: AlertType.system,
      title: 'System Update',
      message: 'Maintenance tonight',
      priority: AlertPriority.normal,
      isRead: true,
      createdAt: DateTime(2026, 3, 14),
    ),
  ];

  setUp(() {
    mockRepository = MockAlertRepository();
  });

  group('AlertsCubit', () {
    test('initial state is AlertsInitial', () {
      final cubit = AlertsCubit(alertRepository: mockRepository);
      expect(cubit.state, isA<AlertsInitial>());
      cubit.close();
    });

    group('loadAlerts', () {
      blocTest<AlertsCubit, AlertsState>(
        'emits [AlertsLoading, AlertsLoaded] on success',
        setUp: () {
          when(() => mockRepository.getAlerts(
                unreadOnly: any(named: 'unreadOnly'),
                page: any(named: 'page'),
                size: any(named: 'size'),
              )).thenAnswer((_) async => PaginatedResponse(
                content: testAlerts,
                page: 0,
                size: 20,
                totalPages: 1,
                totalElements: 2,
              ));
        },
        build: () => AlertsCubit(alertRepository: mockRepository),
        act: (cubit) => cubit.loadAlerts(),
        expect: () => [
          isA<AlertsLoading>(),
          isA<AlertsLoaded>()
              .having((s) => s.alerts.length, 'alerts.length', 2)
              .having((s) => s.page, 'page', 0)
              .having((s) => s.hasMore, 'hasMore', false),
        ],
      );

      blocTest<AlertsCubit, AlertsState>(
        'emits [AlertsLoading, AlertsError] on failure',
        setUp: () {
          when(() => mockRepository.getAlerts(
                unreadOnly: any(named: 'unreadOnly'),
                page: any(named: 'page'),
                size: any(named: 'size'),
              )).thenThrow(Exception('Network error'));
        },
        build: () => AlertsCubit(alertRepository: mockRepository),
        act: (cubit) => cubit.loadAlerts(),
        expect: () => [
          isA<AlertsLoading>(),
          isA<AlertsError>(),
        ],
      );
    });

    group('loadUnreadCount', () {
      blocTest<AlertsCubit, AlertsState>(
        'emits AlertsUnreadCountLoaded when not in AlertsLoaded state',
        setUp: () {
          when(() => mockRepository.getUnreadCount())
              .thenAnswer((_) async => 5);
        },
        build: () => AlertsCubit(alertRepository: mockRepository),
        act: (cubit) => cubit.loadUnreadCount(),
        expect: () => [
          isA<AlertsUnreadCountLoaded>()
              .having((s) => s.count, 'count', 5),
        ],
      );

      blocTest<AlertsCubit, AlertsState>(
        'silently fails on error',
        setUp: () {
          when(() => mockRepository.getUnreadCount())
              .thenThrow(Exception('fail'));
        },
        build: () => AlertsCubit(alertRepository: mockRepository),
        act: (cubit) => cubit.loadUnreadCount(),
        expect: () => <AlertsState>[],
      );
    });

    group('markAsRead', () {
      blocTest<AlertsCubit, AlertsState>(
        'updates alert to read and decrements unread count',
        setUp: () {
          when(() => mockRepository.markAsRead(1))
              .thenAnswer((_) async {});
        },
        build: () => AlertsCubit(alertRepository: mockRepository),
        seed: () => AlertsLoaded(
          alerts: testAlerts,
          unreadCount: 1,
        ),
        act: (cubit) => cubit.markAsRead(1),
        expect: () => [
          isA<AlertsLoaded>()
              .having(
                  (s) => s.alerts.first.isRead, 'first alert isRead', true)
              .having((s) => s.unreadCount, 'unreadCount', 0),
        ],
      );
    });

    group('markAllAsRead', () {
      blocTest<AlertsCubit, AlertsState>(
        'marks all alerts as read and sets count to 0',
        setUp: () {
          when(() => mockRepository.markAllAsRead())
              .thenAnswer((_) async {});
        },
        build: () => AlertsCubit(alertRepository: mockRepository),
        seed: () => AlertsLoaded(
          alerts: testAlerts,
          unreadCount: 1,
        ),
        act: (cubit) => cubit.markAllAsRead(),
        expect: () => [
          isA<AlertsLoaded>()
              .having((s) => s.alerts.every((a) => a.isRead),
                  'all read', true)
              .having((s) => s.unreadCount, 'unreadCount', 0),
        ],
      );
    });
  });
}

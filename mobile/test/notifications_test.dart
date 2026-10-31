import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/auth/student_profile_view.dart';
import 'package:mealmate/features/notifications/notifications_screen.dart';

const _acceptedId = '11111111-1111-4111-8111-111111111111';
const _cancelledId = '22222222-2222-4222-8222-222222222222';

/// Fake backend for `/api/notifications` and `/api/notifications/:id/read`.
class _FakeNotificationsApi {
  _FakeNotificationsApi({this.items, this.failReads = false});

  final bool failReads;
  final requests = <http.Request>[];
  late final List<Map<String, dynamic>> notifications =
      items ??
      [
        {
          'id': _acceptedId,
          'order_id': 'o1',
          'type': 'order_accepted',
          'title': 'Order accepted',
          'body': 'Your order is ready for pickup at 1:02 PM.',
          'is_read': false,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toUtc()
              .toIso8601String(),
        },
        {
          'id': _cancelledId,
          'order_id': 'o2',
          'type': 'order_cancelled',
          'title': 'Order cancelled',
          'body': 'The shop could not take your order.',
          'is_read': true,
          'created_at': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toUtc()
              .toIso8601String(),
        },
      ];
  final List<Map<String, dynamic>>? items;

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    if (request.method == 'GET' && path == '/api/notifications') {
      return http.Response(jsonEncode({'notifications': notifications}), 200);
    }
    final read = RegExp(r'^/api/notifications/([^/]+)/read$').firstMatch(path);
    if (request.method == 'PATCH' && read != null) {
      if (failReads) {
        return http.Response(jsonEncode({'message': 'Server error'}), 500);
      }
      final item = notifications.firstWhere((n) => n['id'] == read[1]);
      item['is_read'] = true;
      return http.Response(jsonEncode({'notification': item}), 200);
    }
    return http.Response(jsonEncode({'message': 'Not found'}), 404);
  });

  List<http.Request> get reads =>
      requests.where((r) => r.method == 'PATCH').toList();
}

Future<void> _pumpScreen(WidgetTester tester, _FakeNotificationsApi api) async {
  await tester.pumpWidget(
    MaterialApp(home: NotificationsScreen(client: api.client)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AuthService.token = 'student-token');
  tearDown(AuthService.logout);

  testWidgets('lists notifications from the API', (tester) async {
    final api = _FakeNotificationsApi();
    await _pumpScreen(tester, api);

    final get = api.requests.single;
    expect(get.url.path, '/api/notifications');
    expect(get.headers['Authorization'], 'Bearer student-token');
    expect(find.text('Order accepted'), findsOneWidget);
    expect(
      find.text('Your order is ready for pickup at 1:02 PM.'),
      findsOneWidget,
    );
    expect(find.text('Order cancelled'), findsOneWidget);
    expect(find.text('5m ago'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('tapping an unread notification marks it read', (tester) async {
    final api = _FakeNotificationsApi();
    await _pumpScreen(tester, api);

    await tester.tap(find.text('Order accepted'));
    await tester.pumpAndSettle();

    expect(api.reads.single.url.path, '/api/notifications/$_acceptedId/read');
    expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
    expect(find.text('Mark all read'), findsNothing);

    // Tapping an already-read notification sends nothing.
    await tester.tap(find.text('Order cancelled'));
    await tester.pumpAndSettle();
    expect(api.reads, hasLength(1));
  });

  testWidgets('a failed mark-read is undone and explained', (tester) async {
    final api = _FakeNotificationsApi(failReads: true);
    await _pumpScreen(tester, api);

    await tester.tap(find.text('Order accepted'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unread-dot')), findsOneWidget);
    expect(
      find.text('The server is unavailable. Please try again later.'),
      findsOneWidget,
    );
  });

  testWidgets('mark all read marks every unread notification', (tester) async {
    final api = _FakeNotificationsApi(
      items: [
        for (final id in [_acceptedId, _cancelledId])
          {
            'id': id,
            'type': 'order_accepted',
            'title': 'Order $id',
            'body': 'Ready',
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
      ],
    );
    await _pumpScreen(tester, api);
    expect(find.byKey(const ValueKey('unread-dot')), findsNWidgets(2));

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(api.reads, hasLength(2));
    expect(find.byKey(const ValueKey('unread-dot')), findsNothing);
  });

  testWidgets('shows an empty state', (tester) async {
    await _pumpScreen(tester, _FakeNotificationsApi(items: []));
    expect(find.textContaining('No notifications yet.'), findsOneWidget);
  });

  testWidgets('without a session it asks the student to sign in', (
    tester,
  ) async {
    AuthService.logout();
    final api = _FakeNotificationsApi();
    await _pumpScreen(tester, api);

    expect(api.requests, isEmpty);
    expect(
      find.text('Please sign in to see your notifications.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('profile shows the unread count and opens the screen', (
    tester,
  ) async {
    final api = _FakeNotificationsApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentProfileView(
            user: const {'name': 'Nuwan', 'role': 'student'},
            onLogout: () {},
            onOrders: () {},
            notificationsClient: api.client,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 new'), findsOneWidget);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    await tester.tap(find.text('Order accepted'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The badge refreshes after returning.
    expect(find.text('1 new'), findsNothing);
  });

  testWidgets('preview profile keeps the sample notice', (tester) async {
    final api = _FakeNotificationsApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentProfileView(
            isPreview: true,
            user: const {'name': 'Preview'},
            onLogout: () {},
            onOrders: () {},
            notificationsClient: api.client,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(api.requests, isEmpty);
    expect(
      find.text('No new notifications. Live notifications are not connected.'),
      findsOneWidget,
    );
  });
}

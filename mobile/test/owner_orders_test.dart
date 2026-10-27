import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/owner/owner_dashboard_screen.dart';

const _orderId = 'a1b2c3d4-0000-4000-8000-000000000001';

/// Fake backend for `/api/orders/shop` and `/api/orders/:id/status`.
class _FakeOrdersApi {
  _FakeOrdersApi({this.patchStatusCode = 200});

  final int patchStatusCode;
  final requests = <http.Request>[];
  final orders = <Map<String, dynamic>>[
    {
      'id': _orderId,
      'status': 'pending',
      'total': '1300.00',
      'pickup_time': null,
      'note': 'Less spicy please',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 3))
          .toUtc()
          .toIso8601String(),
      'student_name': 'Nuwan Perera',
      'items': [
        {
          'menu_item_id': 'x',
          'name': 'Chicken Kottu',
          'quantity': 2,
          'unit_price': '500.00',
        },
        {
          'menu_item_id': 'y',
          'name': 'Passion Juice',
          'quantity': 1,
          'unit_price': '300.00',
        },
      ],
    },
  ];

  late final client = MockClient((request) async {
    requests.add(request);
    if (request.method == 'GET' && request.url.path == '/api/orders/shop') {
      return http.Response(jsonEncode({'orders': orders}), 200);
    }
    if (request.method == 'PATCH' &&
        request.url.path == '/api/orders/$_orderId/status') {
      if (patchStatusCode != 200) {
        return http.Response(
          jsonEncode({'message': 'Order not found'}),
          patchStatusCode,
        );
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      orders.first['status'] = body['status'];
      orders.first['pickup_time'] = body['pickup_time'];
      return http.Response(jsonEncode({'order': orders.first}), 200);
    }
    return http.Response(jsonEncode({'message': 'Not found'}), 404);
  });

  /// Order list requests only (the dashboard also loads the shop and menu).
  List<http.Request> get orderGets => requests
      .where((r) => r.method == 'GET' && r.url.path == '/api/orders/shop')
      .toList();

  List<http.Request> get patches =>
      requests.where((r) => r.method == 'PATCH').toList();
}

Future<void> _pumpDashboard(WidgetTester tester, _FakeOrdersApi api) async {
  tester.view.physicalSize = const Size(390, 1260);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: OwnerDashboardScreen(client: api.client)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AuthService.token = 'owner-token');
  tearDown(AuthService.logout);

  testWidgets('loads pending orders from the API', (tester) async {
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);

    final get = api.orderGets.single;
    expect(get.url.path, '/api/orders/shop');
    expect(get.headers['Authorization'], 'Bearer owner-token');

    expect(find.text('Nuwan Perera'), findsOneWidget);
    expect(find.text('2× Chicken Kottu\n1× Passion Juice'), findsOneWidget);
    expect(find.text('Note: Less spicy please'), findsOneWidget);
    expect(find.text('LKR 1,300'), findsOneWidget);
    expect(find.text('#A1B2C3D4'), findsOneWidget);
    expect(find.text('3m ago'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);
    expect(find.text('Preview · Sample orders only'), findsNothing);
  });

  testWidgets('confirm asks for a pickup time and accepts the order', (
    tester,
  ) async {
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();
    expect(find.text('Ready for pickup in'), findsOneWidget);
    final before = DateTime.now();
    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();

    final body = jsonDecode(api.patches.single.body) as Map<String, dynamic>;
    expect(body['status'], 'accepted');
    final pickup = DateTime.parse(body['pickup_time'] as String);
    expect(pickup.difference(before).inMinutes, inInclusiveRange(14, 15));
    expect(
      find.text('Order #A1B2C3D4 accepted. The student has been notified.'),
      findsOneWidget,
    );

    // The list reloads; the order moves to history.
    expect(find.text('0 new'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Accepted · Pickup'), findsOneWidget);
  });

  testWidgets('cancelling the pickup dialog sends nothing', (tester) async {
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);

    await tester.tap(find.text('Confirm Order'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(api.patches, isEmpty);
    expect(find.text('1 new'), findsOneWidget);
  });

  testWidgets('reject asks for confirmation and cancels the order', (
    tester,
  ) async {
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reject order?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await tester.pumpAndSettle();

    final body = jsonDecode(api.patches.single.body) as Map<String, dynamic>;
    expect(body, {'status': 'cancelled'});
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets('an order already handled elsewhere shows a message', (
    tester,
  ) async {
    final api = _FakeOrdersApi(patchStatusCode: 404);
    await _pumpDashboard(tester, api);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Reject'));
    await tester.pumpAndSettle();

    expect(
      find.text('This order was already handled or cancelled by the student.'),
      findsOneWidget,
    );
    // It reloads the list after the failed action.
    expect(api.orderGets, hasLength(2));
  });

  testWidgets('without a session it asks the owner to sign in', (tester) async {
    AuthService.logout();
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);

    expect(api.requests, isEmpty);
    expect(find.text('Please sign in to manage orders.'), findsOneWidget);
  });
  testWidgets('bell shows the pending count and opens pending orders', (
    tester,
  ) async {
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);

    final bell = find.byTooltip('1 pending order');
    expect(bell, findsOneWidget);
    expect(find.descendant(of: bell, matching: find.text('1')), findsOneWidget);

    // From another tab, the bell jumps back to the pending list.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(bell);
    await tester.pumpAndSettle();
    expect(find.text('Pending Orders'), findsOneWidget);
    expect(find.text('Nuwan Perera'), findsOneWidget);
  });

  testWidgets('bell has no badge when nothing is pending', (tester) async {
    final api = _FakeOrdersApi();
    api.orders.first['status'] = 'accepted';
    await _pumpDashboard(tester, api);

    expect(find.byTooltip('No pending orders'), findsOneWidget);
  });

  testWidgets('a newly arrived order is announced', (tester) async {
    final api = _FakeOrdersApi();
    await _pumpDashboard(tester, api);
    expect(find.textContaining('New order from'), findsNothing);

    api.orders.insert(0, {
      ...api.orders.first,
      'id': 'f00dcafe-0000-4000-8000-000000000002',
      'student_name': 'Rashmi Silva',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await tester.tap(find.byTooltip('1 pending order'));
    await tester.pumpAndSettle();

    expect(find.text('New order from Rashmi Silva'), findsOneWidget);
    expect(find.byTooltip('2 pending orders'), findsOneWidget);
  });
}

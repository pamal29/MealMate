import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/home/home_screen.dart';
import 'package:mealmate/features/home/models/shop.dart';
import 'package:mealmate/features/ordering/live_orders.dart';
import 'package:mealmate/features/ordering/student_api.dart';
import 'package:mealmate/features/ordering/student_orders_screen.dart';
import 'package:mealmate/features/ordering/tray.dart';

const _shopId = 'aaaaaaaa-0000-4000-8000-000000000001';
const _itemId = 'bbbbbbbb-0000-4000-8000-000000000001';
const _pendingId = 'd0000001-0000-4000-8000-000000000001';
const _acceptedId = 'd0000002-0000-4000-8000-000000000002';

/// Fake backend for `/api/shops` and `/api/orders`.
class _FakeStudentApi {
  _FakeStudentApi({this.refuseOrder = false});

  final bool refuseOrder;
  final requests = <http.Request>[];

  http.Response _json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status);

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    if (request.method == 'GET' && path == '/api/shops') {
      return _json([
        {
          'id': _shopId,
          'name': 'Campus Kitchen',
          'category': 'Rice & Curry',
          'location': 'Main canteen',
          'rating': '4.5',
          'is_open': true,
        },
      ]);
    }
    if (request.method == 'GET' && path == '/api/shops/$_shopId') {
      return _json({
        'shop': {'id': _shopId, 'name': 'Campus Kitchen'},
        'items': [
          {
            'id': _itemId,
            'name': 'Fish Bun',
            'description': 'Spicy fish',
            'price': '175.00',
          },
        ],
      });
    }
    if (request.method == 'POST' && path == '/api/orders') {
      if (refuseOrder) return _json({'message': 'Shop is closed'}, 409);
      return _json({
        'order': {
          'id': _pendingId,
          'status': 'pending',
          'total': '350.00',
          'pickup_time': null,
          'note': null,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      }, 201);
    }
    if (request.method == 'GET' && path == '/api/orders/mine') {
      return _json({
        'orders': [
          {
            'id': _pendingId,
            'status': 'pending',
            'total': '350.00',
            'pickup_time': null,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'shop_id': _shopId,
            'shop_name': 'Campus Kitchen',
            'items': [
              {'name': 'Fish Bun', 'quantity': 2, 'unit_price': '175.00'},
            ],
          },
          {
            'id': _acceptedId,
            'status': 'accepted',
            'total': '480.50',
            'pickup_time': DateTime.now()
                .add(const Duration(minutes: 20))
                .toUtc()
                .toIso8601String(),
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'shop_id': _shopId,
            'shop_name': 'Campus Kitchen',
            'items': [
              {'name': 'Fried Rice', 'quantity': 1, 'unit_price': '480.50'},
            ],
          },
        ],
      });
    }
    if (request.method == 'PATCH' && path == '/api/orders/$_pendingId/cancel') {
      return _json({
        'order': {'id': _pendingId, 'status': 'cancelled'},
      });
    }
    return _json({'message': 'Not found'}, 404);
  });

  Iterable<http.Request> sent(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == path);
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Opens the shop from the home screen and adds two Fish Buns.
Future<void> _fillTray(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('View'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Add Fish Bun'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Increase Fish Bun'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('View Tray'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AuthService.token = 'student-token';
    LiveOrders.instance.orders.clear();
  });
  tearDown(() {
    AuthService.logout();
    StudentApi.client = null;
  });

  testWidgets('home lists real shops instead of the samples', (tester) async {
    _tallScreen(tester);
    final api = _FakeStudentApi();
    StudentApi.client = api.client;
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Campus Kitchen'), findsOneWidget);
    expect(find.text('Royal Box'), findsNothing);
  });

  testWidgets('home explains when shops cannot be loaded', (tester) async {
    _tallScreen(tester);
    StudentApi.client = MockClient(
      (_) async => http.Response('{"message":"x"}', 500),
    );
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('The server is unavailable. Please try again later.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Royal Box'), findsNothing);
  });

  testWidgets('shop menu shows real items and no invented details', (
    tester,
  ) async {
    _tallScreen(tester);
    StudentApi.client = _FakeStudentApi().client;
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(find.text('Fish Bun'), findsOneWidget);
    expect(find.text('LKR 175'), findsOneWidget);
    expect(find.text('Chicken Fried Rice (SUSL Special)'), findsNothing);
    expect(find.text('Open till 7:00 PM'), findsNothing);
    expect(find.textContaining('(184)'), findsNothing);
  });

  testWidgets('checkout sends the order to the backend', (tester) async {
    _tallScreen(tester);
    final api = _FakeStudentApi();
    StudentApi.client = api.client;
    await _fillTray(tester);

    // The backend adds no packaging fee, so neither does the app.
    expect(find.text('Campus Packaging'), findsNothing);
    await tester.tap(find.text('Place order (LKR 350)'));
    await tester.pumpAndSettle();

    final body = jsonDecode(
      api.sent('POST', '/api/orders').single.body,
    ) as Map<String, dynamic>;
    expect(body, {
      'shop_id': _shopId,
      'items': [
        {'menu_item_id': _itemId, 'quantity': 2},
      ],
    });
    expect(find.text('Order Placed\nSuccessfully!'), findsOneWidget);
    expect(find.textContaining('Your order was sent to'), findsOneWidget);
    expect(find.textContaining('Preview only'), findsNothing);
  });

  testWidgets('a refused order keeps the tray and shows why', (tester) async {
    _tallScreen(tester);
    StudentApi.client = _FakeStudentApi(refuseOrder: true).client;
    await _fillTray(tester);

    await tester.tap(find.text('Place order (LKR 350)'));
    await tester.pumpAndSettle();

    expect(find.text('Shop is closed'), findsOneWidget);
    expect(find.text('Place order (LKR 350)'), findsOneWidget);
  });

  testWidgets('my orders loads real orders and cancels a pending one', (
    tester,
  ) async {
    _tallScreen(tester);
    final api = _FakeStudentApi();
    StudentApi.client = api.client;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StudentOrdersScreen(isPreview: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active 2'), findsOneWidget);
    expect(find.text('• Pending'), findsOneWidget);
    expect(find.text('• Confirmed'), findsOneWidget);
    expect(find.text('LKR 480.50'), findsOneWidget);
    expect(find.text('Preview · Sample orders'), findsNothing);

    await tester.tap(find.text('#D0000001'));
    await tester.pumpAndSettle();
    expect(find.text('Preview next status'), findsNothing);
    await tester.tap(find.text('Cancel order'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel order'));
    await tester.pumpAndSettle();

    expect(api.sent('PATCH', '/api/orders/$_pendingId/cancel'), hasLength(1));
    expect(find.text('• Cancelled'), findsOneWidget);
    expect(find.text('Cancel order'), findsNothing);
  });

  test('prices keep cents and drop trailing zeros', () {
    expect(parsePrice('175.00'), 175);
    expect(money(parsePrice('175.00')), '175');
    expect(money(parsePrice('480.50')), '480.50');
  });

  test('a new menu removes items no longer on sale from the tray', () {
    const shop = Shop(
      id: 's',
      name: 'Shop',
      category: '',
      location: '',
      rating: 0,
      isOpen: true,
      imageAsset: '',
    );
    const bun = FoodItem('bun', 'Bun', '', '', 100, null);
    const tea = FoodItem('tea', 'Tea', '', '', 50, null);
    final tray = Tray(shop, live: true)..setMenu(const [bun, tea]);
    tray
      ..change(bun, 2)
      ..change(tea, 1);
    expect(tray.total, 250);

    tray.setMenu(const [bun]);

    expect(tray.count, 2);
    expect(tray.total, 200);
    tray.dispose();
  });
}

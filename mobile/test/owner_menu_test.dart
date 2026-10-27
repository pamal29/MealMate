import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/owner/owner_dashboard_screen.dart';

const _riceId = '11111111-1111-4111-8111-111111111111';

/// Fake backend for the owner's shop (`/api/shops`) and menu (`/api/menu`).
class _FakeShopApi {
  _FakeShopApi({bool hasShop = true, this.failSaves = false})
    : shop = hasShop
          ? {
              'id': 'shop-1',
              'name': 'Royal Box',
              'category': 'Rice & Curry',
              'location': 'Main canteen',
              'is_open': true,
            }
          : null;

  Map<String, dynamic>? shop;
  final bool failSaves;
  final requests = <http.Request>[];
  final menu = <Map<String, dynamic>>[
    {
      'id': _riceId,
      'name': 'Chicken Fried Rice',
      'description': 'Basmati, egg',
      'price': '480.50',
      'is_available': true,
    },
  ];

  http.Response _json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status);

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    if (failSaves && request.method != 'GET') {
      return _json({'message': 'Price must be a number, 0 or more'}, 400);
    }
    switch ((request.method, path)) {
      case ('GET', '/api/orders/shop'):
        return _json({'orders': []});
      case ('GET', '/api/shops/mine'):
        return shop == null
            ? _json({'message': 'You have not created a shop yet'}, 404)
            : _json(shop!);
      case ('POST', '/api/shops'):
        shop = {'id': 'shop-2', ...body, 'is_open': true};
        return _json(shop!, 201);
      case ('PUT', '/api/shops/mine'):
        shop = {...shop!, ...body};
        return _json(shop!);
      case ('GET', '/api/menu/mine'):
        return shop == null
            ? _json({'message': 'Create your shop first'}, 404)
            : _json(menu);
      case ('POST', '/api/menu'):
        final item = {
          'id': 'new-${menu.length}',
          ...body,
          'is_available': true,
        };
        menu.insert(0, item);
        return _json(item, 201);
    }
    final item = RegExp(r'^/api/menu/(.+)$').firstMatch(path);
    if (item != null) {
      final index = menu.indexWhere((m) => m['id'] == item[1]);
      if (request.method == 'DELETE') {
        menu.removeAt(index);
        return _json({'message': 'Item deleted successfully'});
      }
      if (request.method == 'PUT') {
        menu[index] = {...menu[index], ...body};
        return _json(menu[index]);
      }
    }
    return _json({'message': 'Not found'}, 404);
  });

  List<Map<String, dynamic>> sent(String method, String path) => [
    for (final r in requests)
      if (r.method == method && r.url.path == path)
        jsonDecode(r.body.isEmpty ? '{}' : r.body) as Map<String, dynamic>,
  ];
}

Future<void> _pumpDashboard(WidgetTester tester, _FakeShopApi api) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(home: OwnerDashboardScreen(client: api.client)),
  );
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.text('Home'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AuthService.token = 'owner-token');
  tearDown(AuthService.logout);

  testWidgets('shows the real shop and menu', (tester) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);

    // Orders tab header uses the owner's shop.
    expect(find.text('Royal Box'), findsOneWidget);
    expect(find.text('Main canteen'), findsOneWidget);
    expect(find.text('Shan Food Cabin'), findsNothing);

    await _openMenu(tester);
    expect(find.text('Chicken Fried Rice'), findsOneWidget);
    expect(find.text('LKR 480.50'), findsOneWidget);
    expect(find.text('Preview · Changes are not published'), findsNothing);
    // The backend has no categories yet, so the filter chips are hidden.
    expect(find.text('Short Eats'), findsNothing);
  });

  testWidgets('availability switch saves to the API', (tester) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);
    await _openMenu(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(api.sent('PUT', '/api/menu/$_riceId'), [
      {'is_available': false},
    ]);
    expect(find.text('• Out of Stock'), findsOneWidget);
  });

  testWidgets('adds a new item without photo or category', (tester) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);
    await _openMenu(tester);

    await tester.tap(find.text('+ New Item'));
    await tester.pumpAndSettle();
    expect(find.text('Food image'), findsNothing);
    expect(find.text('Food category *'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Fish Bun');
    await tester.enterText(find.byType(TextFormField).at(1), 'Spicy fish');
    await tester.enterText(find.byType(TextFormField).at(2), '175');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(api.sent('POST', '/api/menu'), [
      {'name': 'Fish Bun', 'description': 'Spicy fish', 'price': 175},
    ]);
    expect(find.text('Fish Bun added.'), findsOneWidget);
    expect(find.text('Fish Bun'), findsOneWidget);
  });

  testWidgets('a new item saved as unavailable is switched off', (
    tester,
  ) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);
    await _openMenu(tester);

    await tester.tap(find.text('+ New Item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Tea');
    await tester.enterText(find.byType(TextFormField).at(2), '50');
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(api.sent('PUT', '/api/menu/new-1'), [
      {'is_available': false},
    ]);
  });

  testWidgets('edits an existing item', (tester) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);
    await _openMenu(tester);

    await tester.tap(find.byTooltip('Edit Chicken Fried Rice'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '480.50'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(2), '500');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(api.sent('PUT', '/api/menu/$_riceId'), [
      {
        'name': 'Chicken Fried Rice',
        'description': 'Basmati, egg',
        'price': 500,
        'is_available': true,
      },
    ]);
    expect(find.text('LKR 500'), findsOneWidget);
  });

  testWidgets('a failed save keeps the editor open', (tester) async {
    final api = _FakeShopApi(failSaves: true);
    await _pumpDashboard(tester, api);
    await _openMenu(tester);

    await tester.tap(find.byTooltip('Edit Chicken Fried Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Food Item'), findsOneWidget);
    expect(find.text('Price must be a number, 0 or more'), findsOneWidget);
  });

  testWidgets('deletes an item after confirming', (tester) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);
    await _openMenu(tester);

    await tester.tap(find.byTooltip('Delete Chicken Fried Rice'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      api.requests.where((r) => r.method == 'DELETE').single.url.path,
      '/api/menu/$_riceId',
    );
    expect(find.text('Chicken Fried Rice'), findsNothing);
    expect(find.text('Chicken Fried Rice deleted.'), findsOneWidget);
  });

  testWidgets('an owner without a shop can set one up', (tester) async {
    final api = _FakeShopApi(hasShop: false);
    await _pumpDashboard(tester, api);
    expect(find.text('No shop yet'), findsOneWidget);

    await _openMenu(tester);
    expect(
      find.text('Create your shop first. Then you can add menu items.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Set up shop'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set up your shop'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'Eat Art');
    await tester.enterText(fields.at(1), 'Short Eats');
    await tester.enterText(fields.at(2), 'Library road');
    await tester.tap(find.text('Create shop'));
    await tester.pumpAndSettle();

    expect(api.sent('POST', '/api/shops'), [
      {'name': 'Eat Art', 'category': 'Short Eats', 'location': 'Library road'},
    ]);
    expect(find.text('Eat Art'), findsOneWidget);

    // The menu reloads for the new shop.
    await _openMenu(tester);
    expect(find.text('+ New Item'), findsOneWidget);
    expect(find.textContaining('Create your shop first'), findsNothing);
  });

  testWidgets('closing the shop saves and updates the header', (tester) async {
    final api = _FakeShopApi();
    await _pumpDashboard(tester, api);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Open for orders'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(api.sent('PUT', '/api/shops/mine'), [
      {'is_open': false},
    ]);
    expect(find.text('Closed for orders'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Closed'), findsOneWidget);
  });
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mealmate/features/home/home_screen.dart';
import 'package:mealmate/features/home/home_style.dart';
import 'package:mealmate/features/ordering/order_pages.dart';
import 'package:mealmate/features/ordering/preview_orders.dart';
import 'package:mealmate/features/owner/food_editor_screen.dart';
import 'package:mealmate/features/owner/shop_profile_screen.dart';

void main() {
  setUp(() => PreviewOrders.instance.reset());
  Future<void> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Checkout success, tracking and home navigation share the order',
    (tester) async {
      await setup(tester);
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen(isPreview: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add Chicken Fried Rice (SUSL Special)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Tray'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place preview order (LKR 520)'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderSuccessScreen), findsOneWidget);
      expect(PreviewOrders.instance.orders.first.total, 520);
      await tester.ensureVisible(find.text('Track My Order'));
      await tester.tap(find.text('Track My Order'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderDetailsScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Preview next status'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Preview next status'));
      await tester.pumpAndSettle();
      expect(PreviewOrders.instance.orders.first.status, OrderStatus.confirmed);
      await tester.tap(find.text('Orders').last);
      await tester.pumpAndSettle();
      expect(find.text('Active 4'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Nearby Shops'), findsOneWidget);
    },
  );

  testWidgets('Closed orders show no payment due and cannot advance', (
    tester,
  ) async {
    await setup(tester);
    for (final status in [OrderStatus.rejected, OrderStatus.cancelled]) {
      final order = PreviewOrders.instance.orders.firstWhere(
        (o) => o.status == status,
      );
      await tester.pumpWidget(
        MaterialApp(home: OrderDetailsScreen(order: order)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Order ${status.name}'), findsOneWidget);
      expect(find.text('No payment is due for this order.'), findsOneWidget);
      expect(find.text('Preview next status'), findsNothing);
      PreviewOrders.instance.advance(order);
      expect(order.status, status);
    }
  });

  testWidgets(
    'Food editor validates price, rejects invalid images and cancels safely',
    (tester) async {
      await setup(tester);
      final dish = MenuDish(
        'Rice',
        'Basmati',
        480,
        'Rice & Curry',
        'assets/food/rice.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FoodEditorScreen(
            dish: dish,
            pickImage: () async =>
                XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'bad.jpg'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change image'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a JPG or PNG image.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, '0');
      await tester.ensureVisible(find.text('Save item'));
      await tester.tap(find.text('Save item'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a price greater than LKR 0.'), findsOneWidget);
      expect(dish.price, 480);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Seven screen previews and narrow layouts', (tester) async {
    await setup(tester);
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final order = PreviewOrders.instance.orders.first;
    final screens = <String, Widget>{
      'shop-profile': Scaffold(
        appBar: AppBar(title: const Text('Shop Profile')),
        body: ShopProfileScreen(onManageMenu: () {}, onAccount: () {}),
      ),
      'order-success': OrderSuccessScreen(order: order, onNavigate: (_) {}),
      'order-tracking': OrderDetailsScreen(order: order, onNavigate: (_) {}),
      'order-rejected': OrderDetailsScreen(
        order: PreviewOrders.instance.orders[3],
        onNavigate: (_) {},
      ),
      'order-cancelled': OrderDetailsScreen(
        order: PreviewOrders.instance.orders[4],
        onNavigate: (_) {},
      ),
      'food-add': const FoodEditorScreen(),
      'food-edit': FoodEditorScreen(
        dish: MenuDish(
          'Chicken Fried Rice',
          'Basmati, roast chicken, egg',
          480,
          'Rice & Curry',
          'assets/food/rice.jpg',
        ),
      ),
    };
    for (final entry in screens.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: HomeStyle.theme,
            home: entry.value,
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MaterialApp));
        for (final asset in [
          'assets/shops/shan-food-cabin.jpg',
          'assets/food/rice.jpg',
          'assets/food/samosa.jpg',
        ]) {
          if (context.mounted) await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.key);
      if (const bool.fromEnvironment('CAPTURE_ORDERS')) {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/${entry.key}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${entry.key} narrow');
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.physicalSize = const Size(390, 1100);
    }
  });
}

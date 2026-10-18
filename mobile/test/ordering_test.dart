import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/home/models/shop.dart';
import 'package:mealmate/features/ordering/tray.dart';
import 'package:mealmate/features/ordering/shop_menu_screen.dart';
import 'package:mealmate/features/ordering/checkout_screen.dart';

void main() {
  test('Tray computes totals, removes items, caps quantities, and clears packaging', () {
    final tray = Tray(mockShops[1]);
    tray.change(sampleMenu[0], 1);
    tray.change(sampleMenu[1], 2);
    expect(tray.count, 3);
    expect(tray.subtotal, 780);
    expect(tray.total, 820);
    tray.change(sampleMenu[1], -1);
    expect(tray.total, 670);
    tray.remove(sampleMenu[0]);
    expect(tray.total, 190);
    tray.change(sampleMenu[1], 30);
    expect(tray.quantity(sampleMenu[1]), 20);
    tray.clear();
    expect(tray.total, 0);
    expect(tray.packaging, 0);
    tray.dispose();
  });
  testWidgets(
    'Menu and checkout share quantities and do not fake order success',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1076);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tray = Tray(mockShops[1]);
      addTearDown(tray.dispose);
      await tester.pumpWidget(MaterialApp(home: ShopMenuScreen(tray: tray)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add Vegetable Samosa (2 pcs)'));
      await tester.pumpAndSettle();
      expect(tray.total, 190);
      await tester.tap(find.text('View Tray'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Increase Vegetable Samosa (2 pcs)'));
      await tester.pumpAndSettle();
      expect(tray.total, 340);
      await tester.tap(find.text('Place Order (LKR 340)'));
      await tester.pumpAndSettle();
      expect(find.text('Ordering is not available yet'), findsOneWidget);
      await tester.tap(find.text('Keep browsing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Your tray is empty'), findsOneWidget);
      expect(tray.count, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Screen previews and narrow layouts', (tester) async {
    tester.view.physicalSize = const Size(390, 1076);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final tray = Tray(mockShops[1])..change(sampleMenu[0], 1);
    addTearDown(tray.dispose);
    AuthService.user = {'name': 'Pamal'};
    addTearDown(AuthService.logout);
    Future<void> render(Widget screen, String name) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(debugShowCheckedModeBanner: false, home: screen),
        ),
      );
      await tester.runAsync(() async {
        for (final path in [
          tray.shop.imageAsset,
          ...sampleMenu.map((item) => item.image),
        ]) {
          await precacheImage(
            AssetImage(path),
            tester.element(find.byType(MaterialApp)),
          );
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_ORDERING')) {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }

    await render(ShopMenuScreen(tray: tray), 'menu-preview');
    tray.change(sampleMenu[1], 2);
    tester.view.physicalSize = const Size(390, 800);
    await render(CheckoutScreen(tray: tray), 'checkout-preview');
    tester.view.physicalSize = const Size(320, 568);
    for (final screen in [
      ShopMenuScreen(tray: tray),
      CheckoutScreen(tray: tray),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

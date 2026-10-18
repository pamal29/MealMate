import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/home/home_screen.dart';
import 'package:mealmate/features/home/models/shop.dart';
import 'package:mealmate/features/home/widgets/shop_card.dart';
import 'package:mealmate/features/ordering/checkout_screen.dart';
import 'package:mealmate/features/ordering/shop_menu_screen.dart';

void main() {
  testWidgets('Home to menu to checkout and back preserves the selected tray', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1076);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Shan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopMenuScreen), findsOneWidget);
    expect(find.text('Shan Food Cabin'), findsOneWidget);
    await tester.tap(find.byTooltip('Add Chicken Fried Rice (SUSL Special)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Tray'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(find.text('Place Order (LKR 520)'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase Chicken Fried Rice (SUSL Special)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('2 Items in Tray • LKR 960'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby Shops'), findsOneWidget);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('2 Items in Tray • LKR 960'), findsOneWidget);
    await tester.tap(find.text('View Tray'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse menu'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopMenuScreen), findsOneWidget);
    expect(find.text('0 Items in Tray • LKR 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search, category filters, details and navigation work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 964);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShopCard), findsNWidgets(3));
    await tester.enterText(find.byType(TextField), 'royal');
    await tester.pumpAndSettle();
    expect(find.byType(ShopCard), findsOneWidget);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken Fried Rice (SUSL Special)'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ChoiceChip).first, const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Short Eats'));
    await tester.pumpAndSettle();
    expect(find.text('Shan Food Cabin'), findsOneWidget);
    expect(find.text('Royal Box'), findsNothing);
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.text('Explore shops'), findsOneWidget);
    expect(find.byType(ShopCard), findsNWidgets(3));
    await tester.enterText(find.byType(TextField), 'no such shop');
    await tester.pumpAndSettle();
    expect(find.text('No matching shops'), findsOneWidget);
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('Your orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home renders at design size and small size with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 964);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AuthService.user = {'name': 'Pamal'};
    addTearDown(AuthService.logout);
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomeScreen(),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final shop in mockShops) {
        await precacheImage(
          AssetImage(shop.imageAsset),
          tester.element(find.byType(HomeScreen)),
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_HOME')) {
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/home-preview.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Eat Art'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/features/home/models/shop.dart';
import 'package:mealmate/features/ordering/tray.dart';
import 'package:mealmate/features/ordering/shop_menu_screen.dart';
import 'package:mealmate/features/ordering/checkout_screen.dart';
import 'package:mealmate/features/ordering/preview_orders.dart';

void main() {
  const closed = Shop(
    id: 'closed',
    name: 'Closed shop',
    category: 'Rice & Curry',
    location: 'Campus',
    rating: 4,
    isOpen: false,
    imageAsset: 'assets/shops/royal-box.jpg',
  );

  test('Closed shops cannot add items or place orders', () {
    final tray = Tray(closed);
    addTearDown(tray.dispose);
    tray.change(sampleMenu.first, 1);
    expect(tray.count, 0);
    expect(() => PreviewOrders.instance.place(tray), throwsStateError);
  });

  testWidgets('Closed menu shows its status and disables adding food', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1076);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tray = Tray(closed);
    addTearDown(tray.dispose);
    await tester.pumpWidget(MaterialApp(home: ShopMenuScreen(tray: tray)));
    await tester.pumpAndSettle();
    expect(find.text('Closed'), findsOneWidget);
    expect(find.text('Open Now'), findsNothing);
    final add = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == 'Add ${sampleMenu.first.name}',
      ),
    );
    expect(add.onPressed, isNull);
    await tester.pumpWidget(MaterialApp(home: CheckoutScreen(tray: tray)));
    await tester.pumpAndSettle();
    expect(find.text('Shop is closed'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

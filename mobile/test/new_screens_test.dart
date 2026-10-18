import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/auth/owner_login_screen.dart';
import 'package:mealmate/features/auth/register_screen.dart';
import 'package:mealmate/features/auth/student_profile_view.dart';
import 'package:mealmate/features/home/home_style.dart';
import 'package:mealmate/features/home/models/shop.dart';
import 'package:mealmate/features/ordering/shop_menu_screen.dart';
import 'package:mealmate/features/ordering/student_orders_screen.dart';
import 'package:mealmate/features/ordering/tray.dart';
import 'package:mealmate/features/owner/menu_management_screen.dart';
import 'package:mealmate/features/owner/owner_dashboard_screen.dart';

void main() {
  Future<void> size(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(Widget body) => MaterialApp(
    theme: HomeStyle.theme,
    home: Scaffold(body: body),
  );

  testWidgets('Menu search, stock, create, edit and delete work locally', (
    tester,
  ) async {
    await size(tester);
    await tester.pumpWidget(app(const MenuManagementScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restock'));
    await tester.pumpAndSettle();
    expect(find.text('• Out of Stock'), findsNothing);
    await tester.tap(find.text('+ New Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Lime Juice');
    await tester.enterText(find.byType(TextFormField).at(1), 'Fresh lime');
    await tester.enterText(find.byType(TextFormField).at(2), '180');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Lime');
    await tester.pumpAndSettle();
    expect(find.text('Lime Juice'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit Lime Juice'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '190');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 190'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Lime Juice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No matching dishes.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Food sheet adds selected quantity and respects the tray cap', (
    tester,
  ) async {
    await size(tester);
    final tray = Tray(mockShops.first);
    addTearDown(tray.dispose);
    final font = FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: HomeStyle.theme,
          home: ShopMenuScreen(tray: tray),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(sampleMenu.first.name));
    await tester.pumpAndSettle();
    if (const bool.fromEnvironment('CAPTURE_NEW')) {
      await tester.runAsync(() async {
        final context = tester.element(find.byType(ShopMenuScreen));
        await precacheImage(AssetImage(tray.shop.imageAsset), context);
        if (!context.mounted) return;
        await precacheImage(AssetImage(sampleMenu.first.image), context);
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/food-sheet.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.byTooltip('Increase item quantity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Order'));
    await tester.pumpAndSettle();
    expect(tray.count, 2);
    expect(tray.subtotal, 960);
    tray.change(sampleMenu.first, 18);
    await tester.pumpAndSettle();
    await tester.tap(find.text(sampleMenu.first.name));
    await tester.pumpAndSettle();
    final button = find.ancestor(
      of: find.text('Add to Order'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });

  testWidgets('Owner login rejects a student session', (tester) async {
    await size(tester);
    addTearDown(AuthService.logout);
    await tester.pumpWidget(
      MaterialApp(
        home: OwnerLoginScreen(
          onLogin: (_, _) async {
            AuthService.user = {'role': 'student'};
            AuthService.token = 'test';
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.ensureVisible(find.text('→ Login'));
    await tester.tap(find.text('→ Login'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use a shop-owner account'), findsOneWidget);
    expect(find.byType(OwnerDashboardScreen), findsNothing);
    expect(AuthService.token, isNull);
  });

  testWidgets('Profile edits and order tabs respond to taps', (tester) async {
    await size(tester);
    var openedOrders = false;
    await tester.pumpWidget(
      app(
        StudentProfileView(
          isPreview: true,
          user: const {'name': 'Pamal', 'email': 'pamal@example.com'},
          onLogout: () {},
          onOrders: () => openedOrders = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Preview Student');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Preview Student'), findsOneWidget);
    await tester.tap(find.text('My Orders'));
    expect(openedOrders, isTrue);
    await tester.pumpWidget(app(const StudentOrdersScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Pending'), findsNothing);
    expect(find.text('• Rejected'), findsOneWidget);
    await tester.tap(find.text('Royal Box'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Sample order for preview only.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'New screens render at design width and narrow large-text width',
    (tester) async {
      await size(tester);
      final font = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final screens = <String, Widget>{
        'menu-management': app(const MenuManagementScreen()),
        'student-profile': app(
          StudentProfileView(
            isPreview: true,
            user: const {
              'name': 'Pamal Perera',
              'email': 'pamal@example.com',
              'phone': '+94 71 234 5678',
            },
            onLogout: () {},
            onOrders: () {},
          ),
        ),
        'register': const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RegisterScreen(),
        ),
        'student-orders': app(const StudentOrdersScreen()),
        'owner-login': const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: OwnerLoginScreen(),
        ),
      };
      for (final entry in screens.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: key, child: entry.value));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        if (const bool.fromEnvironment('CAPTURE_NEW')) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
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
    },
  );
}

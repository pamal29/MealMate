import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/auth/login_screen.dart';
import 'package:mealmate/features/owner/owner_dashboard_screen.dart';

void main() {
  testWidgets('Owner preview, decisions, undo, history and exit work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Preview shop-owner dashboard'));
    await tester.tap(find.text('Preview shop-owner dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(OwnerDashboardScreen), findsOneWidget);
    expect(find.text('3 new'), findsOneWidget);
    await tester.tap(find.text('Confirm Order').first);
    await tester.pumpAndSettle();
    expect(find.text('2 new'), findsOneWidget);
    expect(find.text('Nuwan Perera'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('3 new'), findsOneWidget);
    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Nuwan Perera'), findsOneWidget);
    expect(find.text('Rejected · Preview'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('+ New Item'), findsOneWidget);
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text('Order History'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Account / Back to login'));
    await tester.tap(find.text('Account / Back to login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Owner login routes to dashboard', (tester) async {
    addTearDown(AuthService.logout);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, _) async {
            AuthService.user = {'role': 'shop_owner', 'name': 'Owner'};
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'owner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(OwnerDashboardScreen), findsOneWidget);
  });

  testWidgets('Dashboard preview and narrow layout', (tester) async {
    tester.view.physicalSize = const Size(390, 1260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const MaterialApp(home: OwnerDashboardScreen(isPreview: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_OWNER')) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/owner-preview.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: OwnerDashboardScreen(isPreview: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Dulara'), 200);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/main.dart';
import 'package:mealmate/features/auth/auth_service.dart';
import 'package:mealmate/features/auth/login_screen.dart';
import 'package:mealmate/features/home/home_screen.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Future<void> Function(String, String)? login,
  }) async {
    tester.view.physicalSize = const Size(390, 886);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLogin: login ?? (_, _) async {})),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
  }

  testWidgets('App starts on login', (tester) async {
    await tester.pumpWidget(const MealMateApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Invalid form does not call login', (tester) async {
    var calls = 0;
    await mount(
      tester,
      login: (_, _) async {
        calls++;
      },
    );
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('Password visibility can be toggled', (tester) async {
    await mount(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
  });

  testWidgets(
    'Pending login disables submission and reports rejected credentials',
    (tester) async {
      final pending = Completer<void>();
      await mount(tester, login: (_, _) => pending.future);
      await fill(tester);
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.completeError(
        const AuthException('Incorrect email or password. Please try again.'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Incorrect email or password. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets('Successful login opens home', (tester) async {
    await mount(
      tester,
      login: (email, password) async {
        expect(email, 'student@example.com');
        expect(password, 'password123');
      },
    );
    await fill(tester);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('Preview opens without login and can return to login', (
    tester,
  ) async {
    var calls = 0;
    await mount(
      tester,
      login: (_, _) async {
        calls++;
      },
    );
    await tester.ensureVisible(find.text('Explore preview — no login needed'));
    await tester.tap(find.text('Explore preview — no login needed'));
    await tester.pumpAndSettle();
    expect(find.text('Preview mode · Sample menu'), findsOneWidget);
    expect(calls, 0);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Student · Sabaragamuwa University · Preview'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('Small screen and larger text remain scrollable', (tester) async {
    await mount(tester);
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Shop Login'));
    await tester.pumpAndSettle();
    // Let the test framework report layout exceptions with full diagnostics.
  });
}

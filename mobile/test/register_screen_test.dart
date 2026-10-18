import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealmate/features/auth/register_screen.dart';
import 'package:mealmate/features/auth/login_screen.dart';
import 'package:mealmate/features/home/home_screen.dart';

void main() {
  testWidgets('Register link opens registration form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register'));
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
  });
  testWidgets('Registration validates passwords and opens home', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          onRegister: (name, email, password, {String role = 'student'}) async {
            calls++;
            expect(name, 'Student');
            expect(email, 'student@example.com');
            expect(password, 'secret123');
            expect(role, 'student');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Student');
    await tester.enterText(fields.at(1), 'student@example.com');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.enterText(fields.at(4), 'different');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(fields.at(4), 'secret123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

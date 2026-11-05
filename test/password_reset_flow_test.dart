import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stark_vms/screens/auth/reset_password_screen.dart';
import 'package:stark_vms/screens/auth/register_screen.dart';

void main() {
  group('Password Reset & Registration UI Flow Tests (Assignment 2)', () {
    testWidgets('ResetPasswordScreen renders Step 1 with email input and security advisory', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(initialEmail: 'tester@example.com'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & security advisory
      expect(find.text('Reset Account Password'), findsOneWidget);
      expect(find.textContaining('Security Advisory: This is an educational demo portal'), findsOneWidget);

      // Verify email input is pre-filled
      expect(find.text('tester@example.com'), findsOneWidget);

      // Verify submit button & demo helper button
      expect(find.text('Send Verification Code'), findsOneWidget);
      expect(find.textContaining('Pre-fill Demo Account'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen validates empty email input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your registered email address.'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders security notice and safe demo password helper', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create an Account'), findsOneWidget);
      expect(find.textContaining('Security Advisory: This is an educational demo portal'), findsOneWidget);

      // Verify all 4 registration input fields (Name, Email, Password, Confirm Password)
      expect(find.byType(TextFormField), findsNWidgets(4));
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123!');
      await tester.pumpAndSettle();

      expect(find.text('Password123!'), findsNWidgets(2));
    });
  });
}

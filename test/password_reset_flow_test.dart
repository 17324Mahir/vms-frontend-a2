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
      expect(find.text('Fill Test Password (Password123!)'), findsOneWidget);

      // Ensure button is visible in scrollview and tap
      await tester.ensureVisible(find.text('Fill Test Password (Password123!)'));
      await tester.tap(find.text('Fill Test Password (Password123!)'));
      await tester.pumpAndSettle();

      // Password fields should now have Password123!
      expect(find.byType(TextFormField), findsNWidgets(4));
    });
  });
}

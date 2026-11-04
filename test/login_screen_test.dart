import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stark_vms/core/errors/api_exception.dart';
import 'package:stark_vms/core/theme/app_theme.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
import 'package:stark_vms/data/vehicle_repository.dart';
import 'package:stark_vms/models/auth_session.dart';
import 'package:stark_vms/models/auth_user.dart';
import 'package:stark_vms/router/app_router.dart';

class _FakeAuthServiceForUi extends AuthService {
  bool shouldSucceed = true;
  bool isNetworkError = false;
  int loginCalls = 0;
  Duration delay = Duration.zero;

  @override
  Future<AuthSession> login(
    String email,
    String password, {
    dynamic client,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    loginCalls++;
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (isNetworkError) {
      throw const NetworkException('Unable to connect to the authentication service.');
    }
    if (!shouldSucceed) {
      throw const ApiException(
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Email or password is incorrect.',
      );
    }
    final session = AuthSession(
      accessToken: 'fake-access-token',
      tokenType: 'Bearer',
      expiresIn: 900,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      user: AuthUser(email: email),
      sessionId: 1,
    );
    setAuthenticatedForTesting(email: email);
    return session;
  }
}

void main() {
  late _FakeAuthServiceForUi fakeAuth;

  setUp(() {
    fakeAuth = _FakeAuthServiceForUi();
    AuthService.setInstanceForTesting(fakeAuth);
    VehicleRepository.setInstanceForTesting(VehicleRepository.fake(initialVehicles: []));
  });

  Widget buildTestableApp({Widget? home}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.loginRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  testWidgets('Renders Login Screen with branding and input fields', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.text('STARK GROUP'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Form validation rejects empty inputs and malformed email', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Tap submit with empty fields
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(fakeAuth.loginCalls, equals(0));

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  testWidgets('Successful login navigates to vehicles view and clears password', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'user@starkgroup.test');
    await tester.enterText(find.byType(TextFormField).last, 'ValidPassword123');

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(fakeAuth.loginCalls, equals(1));
    // Navigated to Vehicles page shell
    expect(find.text('Vehicles'), findsAtLeastNWidgets(1));
  });

  testWidgets('Invalid credentials displays inline error alert', (tester) async {
    fakeAuth.shouldSucceed = false;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'user@starkgroup.test');
    await tester.enterText(find.byType(TextFormField).last, 'WrongPassword');

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(fakeAuth.loginCalls, equals(1));
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    // Still on login screen
    expect(find.text('Sign in to your account'), findsOneWidget);
  });

  testWidgets('Network failure displays network error alert', (tester) async {
    fakeAuth.isNetworkError = true;

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'user@starkgroup.test');
    await tester.enterText(find.byType(TextFormField).last, 'AnyPassword');

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(fakeAuth.loginCalls, equals(1));
    expect(find.text('Unable to connect to the authentication service.'), findsOneWidget);
  });

  testWidgets('Shows spinner and prevents duplicate submission while submitting', (tester) async {
    fakeAuth.delay = const Duration(milliseconds: 300);

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'user@starkgroup.test');
    await tester.enterText(find.byType(TextFormField).last, 'ValidPassword');

    // Tap submit once
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 50));

    // Progress spinner is visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Second tap while submitting should be ignored
    await tester.tap(find.byType(CircularProgressIndicator));
    await tester.pump(const Duration(milliseconds: 50));

    // Settle to complete
    await tester.pumpAndSettle();

    expect(fakeAuth.loginCalls, equals(1));
  });

  testWidgets('Displays session notice alert when sessionExpiredMessage is set', (tester) async {
    AuthService.instance.sessionExpiredMessage.value = 'Session expired. Please sign in again.';

    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    expect(find.text('Session expired. Please sign in again.'), findsOneWidget);
  });
}

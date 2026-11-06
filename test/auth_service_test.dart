import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stark_vms/core/config/api_config.dart';
import 'package:stark_vms/core/errors/api_exception.dart';
import 'package:stark_vms/data/api/vehicle_api_client.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
import 'package:stark_vms/data/auth/session_storage.dart';
import 'package:stark_vms/data/mock_data.dart';
import 'package:stark_vms/data/vehicle_repository.dart';
import 'package:stark_vms/router/app_router.dart';
import 'package:stark_vms/screens/auth/login_screen.dart';

void main() {
  group('AuthService Unit & Session Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      AuthService.setInstanceForTesting(authService);
      VehicleRepository.setInstanceForTesting(VehicleRepository.fake(initialVehicles: initialMockVehicles));
    });

    test('Successful login sets in-memory session and returns AuthSession', () async {
      final mockClient = MockClient((request) async {
        expect(request.url, equals(ApiConfig.authLoginUri));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], equals('learner@example.test'));

        return http.Response(
          jsonEncode({
            'accessToken': 'test-signed-jwt-token-12345',
            'tokenType': 'Bearer',
            'expiresIn': 900,
            'user': {'email': 'learner@example.test'}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final session = await authService.login(
        'learner@example.test',
        'ValidTestPassword@123',
        client: mockClient,
      );

      expect(session.accessToken, equals('test-signed-jwt-token-12345'));
      expect(session.tokenType, equals('Bearer'));
      expect(session.expiresIn, equals(900));
      expect(session.user.email, equals('learner@example.test'));
      expect(session.isExpired, isFalse);

      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentEmail, equals('learner@example.test'));
    });

    test('Invalid credentials throws ApiException with generic message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 401,
            'code': 'INVALID_CREDENTIALS',
            'message': 'Email or password is incorrect.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => authService.login('learner@example.test', 'WrongPassword', client: mockClient),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Email or password is incorrect.'),
        )),
      );

      expect(authService.isAuthenticated, isFalse);
    });

    test('Network failure throws NetworkException', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      expect(
        () => authService.login('learner@example.test', 'AnyPassword', client: mockClient),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Sign-out clears in-memory session and wipes vehicle repository cache', () {
      authService.setAuthenticatedForTesting(email: 'user@starkgroup.test');
      expect(authService.isAuthenticated, isTrue);
      expect(VehicleRepository.instance.allVehicles.isNotEmpty, isTrue);

      authService.signOut();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentSession, isNull);
      expect(VehicleRepository.instance.allVehicles.isEmpty, isTrue);
    });

    test('Multiple simultaneous 401 responses only trigger sign-out safely once', () {
      authService.setAuthenticatedForTesting(email: 'user@starkgroup.test');
      expect(authService.isAuthenticated, isTrue);

      // Concurrent 401 calls
      authService.handleUnauthorized(reason: 'Session expired.');
      authService.handleUnauthorized(reason: 'Session expired.');
      authService.handleUnauthorized(reason: 'Session expired.');

      expect(authService.isAuthenticated, isFalse);
      expect(authService.sessionExpiredMessage.value, equals('Session expired.'));
    });

    test('Late 401 from old session does not invalidate newer session', () {
      // First session
      authService.setAuthenticatedForTesting(email: 'first@starkgroup.test');
      final firstSessionId = authService.currentSession!.sessionId;

      // User signs out and logs in as second session
      authService.signOut();
      authService.setAuthenticatedForTesting(email: 'second@starkgroup.test');
      final secondSessionId = authService.currentSession!.sessionId;
      expect(secondSessionId, isNot(equals(firstSessionId)));

      // Late 401 arriving from first session
      authService.handleUnauthorized(forSessionId: firstSessionId);

      // Second session remains fully authenticated
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentEmail, equals('second@starkgroup.test'));
    });
  });

  group('VehicleApiClient Token Attachment & Security', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      AuthService.setInstanceForTesting(authService);
    });

    test('Attaches Authorization Bearer token to trusted backend requests', () async {
      authService.setAuthenticatedForTesting(
        email: 'test@starkgroup.test',
        token: 'signed-bearer-token-xyz',
      );

      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient, authService: authService);
      await apiClient.getVehicles();

      expect(capturedAuthHeader, equals('Bearer signed-bearer-token-xyz'));
    });

    test('Receiving 401 on protected vehicle request triggers centralized handleUnauthorized', () async {
      authService.setAuthenticatedForTesting(
        email: 'test@starkgroup.test',
        token: 'expired-token',
      );
      expect(authService.isAuthenticated, isTrue);

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 401,
            'code': 'UNAUTHORIZED',
            'message': 'Full authentication is required',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = VehicleApiClient(client: mockClient, authService: authService);

      await expectLater(
        apiClient.getVehicles(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Centralized session has been cleared
      expect(authService.isAuthenticated, isFalse);
      expect(authService.sessionExpiredMessage.value, contains('Session expired'));
    });
  });

  group('Route Guards', () {
    setUp(() {
      final authService = AuthService();
      AuthService.setInstanceForTesting(authService);
    });

    test('Unauthenticated access to protected route redirects to LoginScreen', () {
      expect(AuthService.instance.isAuthenticated, isFalse);

      final route = AppRouter.generateRoute(const RouteSettings(name: AppRouter.vehiclesRoute));

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(
        // Fake BuildContext
        _FakeBuildContext(),
      );
      expect(widget, isA<LoginScreen>());
    });
  });

  group('Session Storage & Page Reload Persistence', () {
    late _InMemorySessionStorage testStorage;

    setUp(() {
      testStorage = _InMemorySessionStorage();
      SessionStorage.setInstanceForTesting(testStorage);
    });

    tearDown(() {
      SessionStorage.resetInstance();
    });

    test('Login persists session tokens to session storage for page reloads', () async {
      final authService = AuthService();
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'persisted-jwt-token-xyz',
            'tokenType': 'Bearer',
            'expiresIn': 3600,
            'user': {'email': 'operator@starkgroup.test'}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await authService.login('operator@starkgroup.test', 'Password123!', client: mockClient);

      expect(testStorage.read('access_token'), equals('persisted-jwt-token-xyz'));
      expect(testStorage.read('email'), equals('operator@starkgroup.test'));
      expect(testStorage.read('token_type'), equals('Bearer'));
      expect(testStorage.read('expires_in'), equals('3600'));
      expect(testStorage.read('expires_at'), isNotNull);
    });

    test('AuthService restores active session on initialization/refresh when valid', () {
      testStorage.write('access_token', 'restored-token-abc');
      testStorage.write('email', 'restored@starkgroup.test');
      testStorage.write('token_type', 'Bearer');
      testStorage.write('expires_in', '900');
      testStorage.write('expires_at', DateTime.now().add(const Duration(minutes: 10)).toIso8601String());

      final newService = AuthService();

      expect(newService.isAuthenticated, isTrue);
      expect(newService.currentEmail, equals('restored@starkgroup.test'));
      expect(newService.currentSession?.accessToken, equals('restored-token-abc'));
    });

    test('AuthService discards expired token during initialization', () {
      testStorage.write('access_token', 'stale-token');
      testStorage.write('email', 'stale@starkgroup.test');
      testStorage.write('expires_at', DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String());

      final newService = AuthService();

      expect(newService.isAuthenticated, isFalse);
      expect(testStorage.read('access_token'), isNull);
    });

    test('Sign out wipes persisted tokens from session storage', () async {
      testStorage.write('access_token', 'token-to-clear');
      testStorage.write('email', 'user@starkgroup.test');
      testStorage.write('expires_at', DateTime.now().add(const Duration(minutes: 10)).toIso8601String());

      final authService = AuthService();
      expect(authService.isAuthenticated, isTrue);

      authService.signOut();

      expect(authService.isAuthenticated, isFalse);
      expect(testStorage.read('access_token'), isNull);
      expect(testStorage.read('email'), isNull);
    });
  });
}

class _InMemorySessionStorage extends SessionStorage {
  final Map<String, String> _data = {};

  @override
  void write(String key, String value) => _data[key] = value;

  @override
  String? read(String key) => _data[key];

  @override
  void remove(String key) => _data.remove(key);

  @override
  void clear() => _data.clear();
}

class _FakeBuildContext extends Fake implements BuildContext {}

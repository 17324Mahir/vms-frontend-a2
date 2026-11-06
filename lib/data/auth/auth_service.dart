import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/errors/api_exception.dart';
import '../../models/auth_session.dart';
import '../../models/auth_user.dart';
import '../driver_repository.dart';
import '../vehicle_repository.dart';
import 'session_storage.dart';

/// Centralized service managing client-side authentication, session state, and JWT bearer tokens.
///
/// Session persistence:
/// - On Flutter Web, tokens are persisted to `sessionStorage` (tab-scoped) so that
///   page reloads do not require re-authentication.
/// - `sessionStorage` is automatically cleared when the browser tab is closed.
/// - On non-web platforms and in tests, a no-op stub is used (pure in-memory).
/// - Signing out clears session tokens from both memory and `sessionStorage`,
///   and flushes private vehicle records from cache.
class AuthService {
  static AuthService _instance = AuthService();
  static AuthService get instance => _instance;

  @visibleForTesting
  static void setInstanceForTesting(AuthService fake) {
    _instance = fake;
  }

  /// Test-only constructor simulating in-memory authentication state.
  @visibleForTesting
  AuthService.fake({bool authenticated = false, String email = 'tester@starkgroup.test'}) {
    if (authenticated) {
      setAuthenticatedForTesting(email: email);
    }
  }

  AuthService() {
    _restoreSession();
  }

  /// Attempts to restore a previously persisted session from sessionStorage (web only).
  void _restoreSession() {
    try {
      final storage = SessionStorage.instance;
      final token = storage.read('access_token');
      final email = storage.read('email');
      final expiresAtStr = storage.read('expires_at');

      if (token == null || token.isEmpty || email == null || expiresAtStr == null) return;

      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        // Token expired — clear stale data
        storage.clear();
        return;
      }

      final tokenType = storage.read('token_type') ?? 'Bearer';
      final expiresIn = int.tryParse(storage.read('expires_in') ?? '') ?? 900;
      final sessionId = int.tryParse(storage.read('session_id') ?? '') ?? 1;

      _sessionCounter = sessionId;
      _currentSession = AuthSession(
        accessToken: token,
        tokenType: tokenType,
        expiresIn: expiresIn,
        expiresAt: expiresAt,
        user: AuthUser(email: email),
        sessionId: sessionId,
      );
      sessionNotifier.value = _currentSession;
    } catch (_) {
      // Gracefully degrade — session restore is best-effort
    }
  }

  /// Persists the current session to sessionStorage so it survives page reloads.
  void _persistSession(AuthSession session) {
    try {
      final storage = SessionStorage.instance;
      storage.write('access_token', session.accessToken);
      storage.write('token_type', session.tokenType);
      storage.write('expires_in', session.expiresIn.toString());
      storage.write('expires_at', session.expiresAt.toIso8601String());
      storage.write('email', session.user.email);
      storage.write('session_id', session.sessionId.toString());
    } catch (_) {
      // Best-effort persistence; in-memory session still works
    }
  }

  /// Clears persisted session data from sessionStorage.
  void _clearPersistedSession() {
    try {
      SessionStorage.instance.clear();
    } catch (_) {}
  }

  @visibleForTesting
  void setAuthenticatedForTesting({String email = 'tester@starkgroup.test', String token = 'fake-test-jwt'}) {
    _currentSession = AuthSession(
      accessToken: token,
      tokenType: 'Bearer',
      expiresIn: 900,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      user: AuthUser(email: email),
      sessionId: ++_sessionCounter,
    );
    sessionNotifier.value = _currentSession;
  }

  AuthSession? _currentSession;
  int _sessionCounter = 0;

  /// Holds a one-time message when a session expires or is invalidated (e.g. 401 from backend).
  final ValueNotifier<String?> sessionExpiredMessage = ValueNotifier<String?>(null);

  /// Reactive notifier for authentication state changes.
  final ValueNotifier<AuthSession?> sessionNotifier = ValueNotifier<AuthSession?>(null);

  bool get isAuthenticated {
    final session = _currentSession;
    if (session == null) return false;
    if (session.isExpired) {
      _currentSession = null;
      sessionNotifier.value = null;
      return false;
    }
    return true;
  }

  AuthSession? get currentSession => isAuthenticated ? _currentSession : null;

  String? get currentEmail => currentSession?.user.email;

  Timer? _keepAliveTimer;

  /// Starts a periodic background heartbeat (every 5 minutes) to keep the backend warm
  /// while the web app is open in a browser tab.
  void startKeepAlive() {
    _keepAliveTimer?.cancel();
    unawaited(warmUpBackend());
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(warmUpBackend());
    });
  }

  /// Preemptively pings the cloud backend to wake it up from idle sleep.
  Future<void> warmUpBackend() async {
    try {
      final client = http.Client();
      await client
          .get(ApiConfig.baseUri.replace(path: '/api'))
          .timeout(const Duration(seconds: 45));
      client.close();
    } catch (_) {
      // Best-effort warm up; errors are ignored
    }
  }

  /// Authenticates against `POST /api/auth/login`.
  Future<AuthSession> login(
    String email,
    String password, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient
          .post(
            ApiConfig.authLoginUri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Expected JSON object in login response.');
        }

        final accessToken = decoded['accessToken'] as String? ?? '';
        final tokenType = decoded['tokenType'] as String? ?? 'Bearer';
        final expiresIn = (decoded['expiresIn'] as num?)?.toInt() ?? 900;
        final userMap = decoded['user'] as Map<String, dynamic>? ?? {};
        final user = AuthUser.fromJson(userMap);

        final session = AuthSession(
          accessToken: accessToken,
          tokenType: tokenType,
          expiresIn: expiresIn,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
          user: user,
          sessionId: ++_sessionCounter,
        );

        _clearLocalCaches();
        _currentSession = session;
        sessionExpiredMessage.value = null;
        sessionNotifier.value = session;
        _persistSession(session);
        return session;
      }

      // Handle login failure
      throw _parseLoginError(response);
    } on TimeoutException catch (e) {
      throw NetworkException(
        'The server is taking longer than usual to respond (cloud service may be waking up from idle). Please wait a moment and try again.',
        e,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to the authentication service. Please check your network connection.',
        e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error during authentication: ${e.message}',
        e,
      );
    } finally {
      if (!isCustomClient) {
        httpClient.close();
      }
    }
  }

  /// Registers a new user account against `POST /api/auth/register`.
  Future<AuthSession> register(
    String name,
    String email,
    String password, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient
          .post(
            ApiConfig.authRegisterUri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Expected JSON object in register response.');
        }

        final accessToken = decoded['accessToken'] as String? ?? '';
        final tokenType = decoded['tokenType'] as String? ?? 'Bearer';
        final expiresIn = (decoded['expiresIn'] as num?)?.toInt() ?? 900;
        final userMap = decoded['user'] as Map<String, dynamic>? ?? {};
        final user = AuthUser.fromJson(userMap);

        final session = AuthSession(
          accessToken: accessToken,
          tokenType: tokenType,
          expiresIn: expiresIn,
          expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
          user: user,
          sessionId: ++_sessionCounter,
        );

        _clearLocalCaches();
        _currentSession = session;
        sessionExpiredMessage.value = null;
        sessionNotifier.value = session;
        _persistSession(session);
        return session;
      }

      throw _parseRegisterError(response);
    } on TimeoutException catch (e) {
      throw NetworkException(
        'The server is taking longer than usual to respond (cloud service may be waking up from idle). Please wait a moment and try again.',
        e,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to the registration service. Please check your network connection.',
        e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error during registration: ${e.message}',
        e,
      );
    } finally {
      if (!isCustomClient) {
        httpClient.close();
      }
    }
  }

  ApiException _parseRegisterError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code'] as String? ?? 'HTTP_${response.statusCode}';
        final message = decoded['message'] as String? ?? 'Registration failed.';
        return ApiException(
          statusCode: (decoded['status'] as num?)?.toInt() ?? response.statusCode,
          code: code,
          message: message,
          path: decoded['path'] as String?,
        );
      }
    } catch (_) {}

    return ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Registration failed with status code ${response.statusCode}.',
    );
  }

  /// Direct in-app password reset against `POST /api/auth/reset-password`.
  Future<String> resetPassword(
    String email,
    String newPassword, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient
          .post(
            ApiConfig.authResetPasswordUri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'newPassword': newPassword.trim(),
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['message'] as String? ?? 'Password has been successfully updated.';
        }
        return 'Password has been successfully updated.';
      }

      throw _parseResetPasswordError(response);
    } on TimeoutException catch (e) {
      throw NetworkException(
        'The server is taking longer than usual to respond. Please wait a moment and try again.',
        e,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to the password reset service. Please check your network connection.',
        e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error during password reset: ${e.message}',
        e,
      );
    } finally {
      if (!isCustomClient) {
        httpClient.close();
      }
    }
  }

  ApiException _parseResetPasswordError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code'] as String? ?? 'HTTP_${response.statusCode}';
        final message = decoded['message'] as String? ?? 'Password reset failed.';
        return ApiException(
          statusCode: (decoded['status'] as num?)?.toInt() ?? response.statusCode,
          code: code,
          message: message,
          path: decoded['path'] as String?,
        );
      }
    } catch (_) {}

    return ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Password reset failed with status code ${response.statusCode}.',
    );
  }

  /// Checks whether an account exists based strictly on email address.
  Future<bool> checkEmailExists(String email, {http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient
          .get(
            ApiConfig.authCheckEmailUri(email),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['exists'] as bool? ?? false;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (!isCustomClient) httpClient.close();
    }
  }

  /// Initiates password reset by dispatching a 6-digit OTP code to the email address.
  Future<ForgotPasswordResult> sendPasswordResetCode(
    String email, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient
          .post(
            ApiConfig.authForgotPasswordUri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ForgotPasswordResult(
            message: decoded['message'] as String? ?? 'Verification code sent.',
            email: decoded['email'] as String? ?? email,
            emailSent: decoded['emailSent'] as bool? ?? false,
            demoOtp: decoded['demoOtp'] as String?,
          );
        }
        return ForgotPasswordResult(
          message: 'Verification code sent.',
          email: email,
          emailSent: false,
        );
      }

      throw _parseResetPasswordError(response);
    } on TimeoutException catch (e) {
      throw NetworkException('The server is taking longer than usual to respond. Please try again.', e);
    } on SocketException catch (e) {
      throw NetworkException('Unable to connect to the password reset service. Please check your network connection.', e);
    } on http.ClientException catch (e) {
      throw NetworkException('Network error during password reset request: ${e.message}', e);
    } finally {
      if (!isCustomClient) httpClient.close();
    }
  }

  /// Verifies the 6-digit email OTP code and updates the password.
  Future<String> verifyResetCode(
    String email,
    String code,
    String newPassword, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final httpClient = client ?? http.Client();
    final isCustomClient = client != null;

    try {
      final response = await httpClient
          .post(
            ApiConfig.authVerifyResetCodeUri,
            headers: const {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'code': code.trim(),
              'newPassword': newPassword.trim(),
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['message'] as String? ?? 'Password has been successfully updated.';
        }
        return 'Password has been successfully updated.';
      }

      throw _parseResetPasswordError(response);
    } on TimeoutException catch (e) {
      throw NetworkException('The server is taking longer than usual to respond. Please try again.', e);
    } on SocketException catch (e) {
      throw NetworkException('Unable to connect to the verification service. Please check your network connection.', e);
    } on http.ClientException catch (e) {
      throw NetworkException('Network error during code verification: ${e.message}', e);
    } finally {
      if (!isCustomClient) httpClient.close();
    }
  }

  /// Centrally handles 401 Unauthorized responses emitted by protected API endpoints.
  /// Prevents race conditions from older expired requests clearing a newer active session.
  void handleUnauthorized({int? forSessionId, String? reason}) {
    if (_currentSession == null) return;

    if (forSessionId != null && forSessionId != _currentSession?.sessionId) {
      // Ignored: this 401 belongs to an older, already terminated session
      return;
    }

    signOut(reason: reason ?? 'Session expired. Please sign in again.');
  }

  /// Clears in-memory session tokens, persisted session storage, notifies listeners,
  /// and wipes private cached fleet data.
  void signOut({String? reason}) {
    _currentSession = null;
    sessionNotifier.value = null;
    if (reason != null) {
      sessionExpiredMessage.value = reason;
    }
    _clearPersistedSession();
    _clearLocalCaches();
  }

  /// Flushes all cached vehicle and driver fleet records across active repositories.
  void _clearLocalCaches() {
    VehicleRepository.instance.clearCache();
    DriverRepository.instance.clearCache();
  }

  void clearExpiredNotice() {
    sessionExpiredMessage.value = null;
  }

  ApiException _parseLoginError(http.Response response) {
    if (response.statusCode == 401) {
      return const ApiException(
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Email or password is incorrect.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiException(
          statusCode: (decoded['status'] as num?)?.toInt() ?? response.statusCode,
          code: decoded['code'] as String? ?? 'HTTP_${response.statusCode}',
          message: decoded['message'] as String? ?? 'Sign in failed.',
          path: decoded['path'] as String?,
        );
      }
    } catch (_) {}

    return ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Sign in failed with status code ${response.statusCode}.',
    );
  }
}

/// Result returned by [AuthService.sendPasswordResetCode].
class ForgotPasswordResult {
  final String message;
  final String email;
  final bool emailSent;
  final String? demoOtp;

  const ForgotPasswordResult({
    required this.message,
    required this.email,
    required this.emailSent,
    this.demoOtp,
  });
}


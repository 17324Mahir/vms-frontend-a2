import 'auth_user.dart';

/// In-memory authentication session holding the JWT access token and expiration.
///
/// Security constraints:
/// - Stored strictly in memory (never persisted to localStorage, sessionStorage, or preferences).
/// - Expiration is enforced locally as well as server-side.
/// - Carries a unique sessionId to prevent race conditions from stale requests.
class AuthSession {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final DateTime expiresAt;
  final AuthUser user;
  final int sessionId;

  AuthSession({
    required this.accessToken,
    this.tokenType = 'Bearer',
    required this.expiresIn,
    required this.expiresAt,
    required this.user,
    required this.sessionId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

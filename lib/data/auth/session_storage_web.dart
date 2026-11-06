import 'package:web/web.dart' as web;
import 'session_storage.dart';

/// Web implementation that persists session data to `window.sessionStorage`.
///
/// `sessionStorage` is tab-scoped: data survives page reloads but is automatically
/// cleared when the browser tab is closed — a good security balance for JWT tokens.
class _WebSessionStorage extends SessionStorage {
  static const _prefix = 'stark_vms_';

  web.Storage get _storage => web.window.sessionStorage;

  @override
  void write(String key, String value) {
    try {
      _storage.setItem('$_prefix$key', value);
    } catch (_) {
      // Quota exceeded or private browsing — silently degrade to in-memory only
    }
  }

  @override
  String? read(String key) {
    try {
      final value = _storage.getItem('$_prefix$key');
      return value;
    } catch (_) {
      return null;
    }
  }

  @override
  void remove(String key) {
    try {
      _storage.removeItem('$_prefix$key');
    } catch (_) {}
  }

  @override
  void clear() {
    try {
      for (final key in ['access_token', 'token_type', 'expires_in', 'expires_at', 'email', 'session_id']) {
        _storage.removeItem('$_prefix$key');
      }
    } catch (_) {}
  }
}

SessionStorage createSessionStorage() => _WebSessionStorage();


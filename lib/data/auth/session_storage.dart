import 'package:flutter/foundation.dart';
import 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart' as platform;

/// Platform-agnostic interface for persisting session tokens across page reloads.
///
/// On Flutter Web, delegates to `window.sessionStorage` (tab-scoped, cleared on tab close).
/// On all other platforms (mobile, desktop, tests), operates as a silent no-op.
abstract class SessionStorage {
  static SessionStorage? _instance;

  static SessionStorage get instance => _instance ??= platform.createSessionStorage();

  @visibleForTesting
  static void setInstanceForTesting(SessionStorage storage) {
    _instance = storage;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Persist a key-value pair.
  void write(String key, String value);

  /// Read a previously persisted value, or null if absent.
  String? read(String key);

  /// Remove a single key.
  void remove(String key);

  /// Remove all session keys managed by this storage.
  void clear();
}


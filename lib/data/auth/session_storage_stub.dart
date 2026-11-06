import 'session_storage.dart';

/// Stub implementation used on non-web platforms (mobile, desktop, tests).
/// All operations are silent no-ops — session data lives only in memory.
class _StubSessionStorage extends SessionStorage {
  @override
  void write(String key, String value) {}

  @override
  String? read(String key) => null;

  @override
  void remove(String key) {}

  @override
  void clear() {}
}

SessionStorage createSessionStorage() => _StubSessionStorage();


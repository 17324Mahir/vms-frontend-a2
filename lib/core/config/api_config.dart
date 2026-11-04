/// Centralized API configuration for the Stark Group VMS Flutter frontend.
///
/// Reads the backend origin from the compile-time environment variable `API_BASE_URL`:
/// `--dart-define=API_BASE_URL=http://localhost:8080`
///
/// NOTE:
/// - Values compiled into a Flutter Web bundle are embedded in client JavaScript and visible to end users.
/// - Changing `--dart-define` values requires restarting the dev server or rebuilding the web application.
class ApiConfig {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Validated base URI with trailing slashes stripped.
  static final Uri baseUri = _parseAndValidateBaseUri(_rawBaseUrl);

  static Uri _parseAndValidateBaseUri(String raw) {
    var trimmed = raw.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.isEmpty) {
      throw const FormatException('API_BASE_URL cannot be empty.');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw FormatException(
        'Invalid API_BASE_URL: "$raw". Must include valid scheme (http/https) and host authority.',
      );
    }
    return uri;
  }

  /// Base vehicles collection URI: `${baseUri}/api/vehicles`
  static Uri get vehiclesUri => baseUri.replace(path: '/api/vehicles');

  /// Single vehicle resource URI: `${baseUri}/api/vehicles/{id}`
  static Uri vehicleUri(int id) => baseUri.replace(path: '/api/vehicles/$id');

  /// Authentication login endpoint URI: `${baseUri}/api/auth/login`
  static Uri get authLoginUri => baseUri.replace(path: '/api/auth/login');

  /// Authentication register endpoint URI: `${baseUri}/api/auth/register`
  static Uri get authRegisterUri => baseUri.replace(path: '/api/auth/register');
}

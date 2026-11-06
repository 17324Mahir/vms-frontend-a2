/// Centralized API configuration for the Stark Group VMS Flutter frontend.
///
/// Reads the backend origin from the compile-time environment variable `API_BASE_URL`:
/// `--dart-define=API_BASE_URL=http://localhost:8080`
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

  /// Vehicle status update URI: `${baseUri}/api/vehicles/{id}/status`
  static Uri vehicleStatusUri(int id) => baseUri.replace(path: '/api/vehicles/$id/status');

  /// Assign driver URI: `${baseUri}/api/vehicles/{id}/assign-driver/{driverId}`
  static Uri vehicleAssignDriverUri(int id, int driverId) =>
      baseUri.replace(path: '/api/vehicles/$id/assign-driver/$driverId');

  /// Unassign driver URI: `${baseUri}/api/vehicles/{id}/unassign-driver`
  static Uri vehicleUnassignDriverUri(int id) =>
      baseUri.replace(path: '/api/vehicles/$id/unassign-driver');

  /// Vehicle documents URI: `${baseUri}/api/vehicles/{id}/documents`
  static Uri vehicleDocumentsUri(int vehicleId) =>
      baseUri.replace(path: '/api/vehicles/$vehicleId/documents');

  /// Single vehicle document URI: `${baseUri}/api/vehicles/{id}/documents/{docId}`
  static Uri vehicleDocumentUri(int vehicleId, int docId) =>
      baseUri.replace(path: '/api/vehicles/$vehicleId/documents/$docId');

  /// Document download URI: `${baseUri}/api/vehicles/{vehicleId}/documents/{docId}/download`
  static Uri vehicleDocumentDownloadUri(int vehicleId, int docId) =>
      baseUri.replace(path: '/api/vehicles/$vehicleId/documents/$docId/download');

  /// Global documents collection URI: `${baseUri}/api/documents`
  static Uri get documentsUri => baseUri.replace(path: '/api/documents');

  /// Vehicle maintenance collection URI: `${baseUri}/api/vehicles/{id}/maintenance`
  static Uri vehicleMaintenanceUri(int vehicleId) =>
      baseUri.replace(path: '/api/vehicles/$vehicleId/maintenance');

  /// Single maintenance record URI: `${baseUri}/api/vehicles/{id}/maintenance/{mId}`
  static Uri vehicleMaintenanceItemUri(int vehicleId, int mId) =>
      baseUri.replace(path: '/api/vehicles/$vehicleId/maintenance/$mId');

  /// Global maintenance collection URI: `${baseUri}/api/maintenance`
  static Uri get maintenanceUri => baseUri.replace(path: '/api/maintenance');

  /// Drivers collection URI: `${baseUri}/api/drivers`
  static Uri get driversUri => baseUri.replace(path: '/api/drivers');

  /// Single driver URI: `${baseUri}/api/drivers/{id}`
  static Uri driverUri(int id) => baseUri.replace(path: '/api/drivers/$id');

  /// Available drivers URI: `${baseUri}/api/drivers/available`
  static Uri get availableDriversUri => baseUri.replace(path: '/api/drivers/available');

  /// Dashboard statistics URI: `${baseUri}/api/dashboard/stats`
  static Uri get dashboardStatsUri => baseUri.replace(path: '/api/dashboard/stats');

  /// Authentication login endpoint URI: `${baseUri}/api/auth/login`
  static Uri get authLoginUri => baseUri.replace(path: '/api/auth/login');

  /// Authentication register endpoint URI: `${baseUri}/api/auth/register`
  static Uri get authRegisterUri => baseUri.replace(path: '/api/auth/register');

  /// Authentication reset password endpoint URI: `${baseUri}/api/auth/reset-password`
  static Uri get authResetPasswordUri => baseUri.replace(path: '/api/auth/reset-password');

  /// Authentication forgot password (request OTP) endpoint URI: `${baseUri}/api/auth/forgot-password`
  static Uri get authForgotPasswordUri => baseUri.replace(path: '/api/auth/forgot-password');

  /// Authentication verify reset code endpoint URI: `${baseUri}/api/auth/verify-reset-code`
  static Uri get authVerifyResetCodeUri => baseUri.replace(path: '/api/auth/verify-reset-code');

  /// Authentication email availability check endpoint URI: `${baseUri}/api/auth/check-email?email={email}`
  static Uri authCheckEmailUri(String email) =>
      baseUri.replace(path: '/api/auth/check-email', queryParameters: {'email': email.trim().toLowerCase()});
}

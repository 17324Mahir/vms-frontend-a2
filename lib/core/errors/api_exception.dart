/// Represents a single validation field error returned by the backend.
class ApiFieldError {
  final String field;
  final String message;

  const ApiFieldError({
    required this.field,
    required this.message,
  });

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// Typed exception representing an HTTP failure response from the backend.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final String? path;
  final List<ApiFieldError> fieldErrors;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.path,
    this.fieldErrors = const [],
  });

  /// Returns the specific validation error message for a given [fieldName], if any.
  String? getFieldError(String fieldName) {
    final target = fieldName.trim().toLowerCase();
    for (final err in fieldErrors) {
      if (err.field.trim().toLowerCase() == target) {
        return err.message;
      }
    }
    return null;
  }

  bool get isDuplicateVehicleNumber =>
      code == 'DUPLICATE_VEHICLE_NUMBER' || statusCode == 409;

  bool get isNotFound =>
      code == 'VEHICLE_NOT_FOUND' || statusCode == 404;

  bool get isValidationFailed =>
      code == 'VALIDATION_FAILED' || statusCode == 400;

  @override
  String toString() =>
      'ApiException(status: $statusCode, code: $code, message: $message)';
}

/// Represents transport, connectivity, timeout, or DNS failures.
class NetworkException implements Exception {
  final String message;
  final Object? originalError;

  const NetworkException(this.message, [this.originalError]);

  @override
  String toString() => 'NetworkException: $message';
}

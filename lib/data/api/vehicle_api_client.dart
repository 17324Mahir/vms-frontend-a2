import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/errors/api_exception.dart';
import '../../models/page_response.dart';
import '../../models/vehicle.dart';
import '../auth/auth_service.dart';

/// Reusable HTTP client communicating with the Stark Group Vehicle REST API.
class VehicleApiClient {
  final http.Client _client;
  final AuthService _authService;
  final bool _isCustomClient;
  final Duration timeout;

  VehicleApiClient({
    http.Client? client,
    AuthService? authService,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _authService = authService ?? AuthService.instance,
       _isCustomClient = client != null;

  void dispose() {
    if (!_isCustomClient) {
      _client.close();
    }
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  /// Fetches all vehicles from `GET /api/vehicles`.
  Future<List<Vehicle>> getVehicles() async {
    return _send('GET', ApiConfig.vehiclesUri, (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Expected JSON array of vehicles');
      }
      return decoded
          .cast<Map<String, dynamic>>()
          .map<Vehicle>(Vehicle.fromJson)
          .toList();
    });
  }

  Future<List<String>> getCompanies() {
    final uri = ApiConfig.vehiclesUri.replace(path: '/api/vehicles/companies');
    return _send('GET', uri, (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.any((item) => item is! String)) {
        throw const FormatException('Expected a list of company names');
      }
      return List<String>.from(decoded);
    });
  }

  /// Paginated and filtered search via `GET /api/vehicles`.
  Future<PageResponse<Vehicle>> searchVehicles({
    int page = 0,
    int size = 10,
    String? search,
    VehicleStatus? status,
    String? company,
    String sortBy = 'id',
    String sortDir = 'asc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': sortBy,
      'sortDir': sortDir,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (status != null) {
      queryParams['status'] = status.toBackendString();
    }
    if (company != null &&
        company.trim().isNotEmpty &&
        company != 'All Companies') {
      queryParams['company'] = company.trim();
    }

    final uri = ApiConfig.vehiclesUri.replace(queryParameters: queryParams);

    return _send('GET', uri, (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Expected JSON object for paginated vehicles',
        );
      }
      return PageResponse.fromJson(decoded, Vehicle.fromJson);
    });
  }

  /// Fetches a single vehicle from `GET /api/vehicles/{id}`.
  Future<Vehicle> getVehicle(int id) async {
    return _send('GET', ApiConfig.vehicleUri(id), (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object for vehicle');
      }
      return Vehicle.fromJson(decoded);
    });
  }

  /// Registers a new vehicle via `POST /api/vehicles`.
  Future<Vehicle> createVehicle(Map<String, dynamic> payload) async {
    return _send('POST', ApiConfig.vehiclesUri, (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object for created vehicle');
      }
      return Vehicle.fromJson(decoded);
    }, body: jsonEncode(payload));
  }

  /// Fully updates an existing vehicle via `PUT /api/vehicles/{id}`.
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> payload) async {
    return _send('PUT', ApiConfig.vehicleUri(id), (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object for updated vehicle');
      }
      return Vehicle.fromJson(decoded);
    }, body: jsonEncode(payload));
  }

  /// Updates vehicle operational status via `PATCH /api/vehicles/{id}/status`.
  Future<Vehicle> updateVehicleStatus(int id, VehicleStatus status) async {
    return _send('PATCH', ApiConfig.vehicleStatusUri(id), (response) {
      final decoded = jsonDecode(response.body);
      return Vehicle.fromJson(decoded as Map<String, dynamic>);
    }, body: jsonEncode({'status': status.toBackendString()}));
  }

  /// Assigns a driver to a vehicle via `POST /api/vehicles/{id}/assign-driver/{driverId}`.
  Future<Vehicle> assignDriver(int vehicleId, int driverId) async {
    return _send(
      'POST',
      ApiConfig.vehicleAssignDriverUri(vehicleId, driverId),
      (response) {
        final decoded = jsonDecode(response.body);
        return Vehicle.fromJson(decoded as Map<String, dynamic>);
      },
    );
  }

  /// Unassigns driver from vehicle via `POST /api/vehicles/{id}/unassign-driver`.
  Future<Vehicle> unassignDriver(int vehicleId) async {
    return _send('POST', ApiConfig.vehicleUnassignDriverUri(vehicleId), (
      response,
    ) {
      final decoded = jsonDecode(response.body);
      return Vehicle.fromJson(decoded as Map<String, dynamic>);
    });
  }

  /// Deletes a vehicle via `DELETE /api/vehicles/{id}`.
  Future<void> deleteVehicle(int id) async {
    await _send('DELETE', ApiConfig.vehicleUri(id), (_) {});
  }

  Future<T> _send<T>(
    String method,
    Uri uri,
    T Function(http.Response response) parser, {
    String? body,
  }) async {
    final requestHeaders = Map<String, String>.from(_headers);

    final isTrustedOrigin =
        uri.scheme == ApiConfig.baseUri.scheme &&
        uri.host == ApiConfig.baseUri.host &&
        uri.port == ApiConfig.baseUri.port;

    if (isTrustedOrigin && _authService.isAuthenticated) {
      final token = _authService.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    }

    final currentSessionId = _authService.currentSession?.sessionId;

    try {
      final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: requestHeaders)
              .timeout(timeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: requestHeaders, body: body)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: requestHeaders)
              .timeout(timeout);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(response);
      }

      if (response.statusCode == 401) {
        _authService.handleUnauthorized(
          forSessionId: currentSessionId,
          reason: 'Session expired. Please sign in again.',
        );
      }

      throw _parseError(response);
    } on TimeoutException catch (e) {
      throw NetworkException(
        'Request to $uri timed out after ${timeout.inSeconds} seconds.',
        e,
      );
    } on SocketException catch (e) {
      throw NetworkException(
        'Unable to connect to the backend server at $uri. Please verify the backend is running.',
        e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        'Network error communicating with $uri: ${e.message}',
        e,
      );
    } on FormatException catch (e) {
      throw ApiException(
        statusCode: 500,
        code: 'PARSING_ERROR',
        message:
            'Invalid response format received from the server: ${e.message}',
      );
    }
  }

  ApiException _parseError(http.Response response) {
    if (response.body.trim().isEmpty) {
      return ApiException(
        statusCode: response.statusCode,
        code: 'HTTP_${response.statusCode}',
        message: 'Request failed with status code ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final fieldErrorsList = <ApiFieldError>[];
        if (decoded['fieldErrors'] is List) {
          for (final item in (decoded['fieldErrors'] as List)) {
            if (item is Map<String, dynamic>) {
              fieldErrorsList.add(ApiFieldError.fromJson(item));
            }
          }
        }

        return ApiException(
          statusCode:
              (decoded['status'] as num?)?.toInt() ?? response.statusCode,
          code: decoded['code'] as String? ?? 'HTTP_${response.statusCode}',
          message:
              decoded['message'] as String? ??
              'An error occurred (HTTP ${response.statusCode}).',
          path: decoded['path'] as String?,
          fieldErrors: fieldErrorsList,
        );
      }
    } catch (_) {
      // Body is not JSON
    }

    return ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Request failed with status code ${response.statusCode}.',
    );
  }
}

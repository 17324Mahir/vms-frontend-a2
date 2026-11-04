import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/errors/api_exception.dart';
import '../../models/maintenance_record.dart';
import '../auth/auth_service.dart';

class MaintenanceApiClient {
  final http.Client _client;
  final AuthService _authService;
  final bool _isCustomClient;
  final Duration timeout;

  MaintenanceApiClient({
    http.Client? client,
    AuthService? authService,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
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

  Future<List<MaintenanceRecord>> getMaintenanceHistory(int vehicleId) async {
    return _send('GET', ApiConfig.vehicleMaintenanceUri(vehicleId), (response) {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const FormatException('Expected JSON array of maintenance records');
      }
      return decoded
          .cast<Map<String, dynamic>>()
          .map<MaintenanceRecord>(MaintenanceRecord.fromJson)
          .toList();
    });
  }

  Future<MaintenanceRecord> recordMaintenance(int vehicleId, Map<String, dynamic> payload) async {
    return _send(
      'POST',
      ApiConfig.vehicleMaintenanceUri(vehicleId),
      (response) {
        final decoded = jsonDecode(response.body);
        return MaintenanceRecord.fromJson(decoded as Map<String, dynamic>);
      },
      body: jsonEncode(payload),
    );
  }

  Future<MaintenanceRecord> updateMaintenance(int vehicleId, int mId, Map<String, dynamic> payload) async {
    return _send(
      'PUT',
      ApiConfig.vehicleMaintenanceItemUri(vehicleId, mId),
      (response) {
        final decoded = jsonDecode(response.body);
        return MaintenanceRecord.fromJson(decoded as Map<String, dynamic>);
      },
      body: jsonEncode(payload),
    );
  }

  Future<void> deleteMaintenance(int vehicleId, int mId) async {
    await _send('DELETE', ApiConfig.vehicleMaintenanceItemUri(vehicleId, mId), (_) {});
  }

  Future<T> _send<T>(
    String method,
    Uri uri,
    T Function(http.Response response) parser, {
    String? body,
  }) async {
    final requestHeaders = Map<String, String>.from(_headers);

    final isTrustedOrigin = uri.scheme == ApiConfig.baseUri.scheme &&
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
          response = await _client.get(uri, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await _client.post(uri, headers: requestHeaders, body: body).timeout(timeout);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: requestHeaders, body: body).timeout(timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: requestHeaders).timeout(timeout);
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
      throw NetworkException('Request to $uri timed out after ${timeout.inSeconds} seconds.', e);
    } on SocketException catch (e) {
      throw NetworkException('Unable to connect to the backend server at $uri.', e);
    } on http.ClientException catch (e) {
      throw NetworkException('Network error communicating with $uri: ${e.message}', e);
    } on FormatException catch (e) {
      throw ApiException(
        statusCode: 500,
        code: 'PARSING_ERROR',
        message: 'Invalid response format received from the server: ${e.message}',
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
          statusCode: (decoded['status'] as num?)?.toInt() ?? response.statusCode,
          code: decoded['code'] as String? ?? 'HTTP_${response.statusCode}',
          message: decoded['message'] as String? ?? 'An error occurred (HTTP ${response.statusCode}).',
          path: decoded['path'] as String?,
          fieldErrors: fieldErrorsList,
        );
      }
    } catch (_) {
      // Non-JSON response
    }

    return ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
      message: 'Request failed with status code ${response.statusCode}.',
    );
  }
}


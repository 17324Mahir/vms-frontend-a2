import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stark_vms/core/errors/api_exception.dart';
import 'package:stark_vms/data/api/vehicle_api_client.dart';
import 'package:stark_vms/models/vehicle.dart';

void main() {
  group('Vehicle Model & Serialization', () {
    test('Parses numeric integer ID from JSON', () {
      final json = {
        'id': 42,
        'vehicleNumber': 'SG-1001',
        'company': 'Stark Industries',
        'type': 'Sedan',
        'brand': 'Tesla',
        'model': 'Model S',
        'status': 'ACTIVE',
      };

      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.id, equals(42));
      expect(vehicle.vehicleNumber, equals('SG-1001'));
      expect(vehicle.status, equals(VehicleStatus.active));
    });

    test('Throws FormatException for unknown server status (no silent fallback)', () {
      final json = {
        'id': 1,
        'vehicleNumber': 'SG-1001',
        'company': 'Stark Industries',
        'type': 'Sedan',
        'brand': 'Tesla',
        'model': 'Model S',
        'status': 'UNKNOWN_STATUS',
      };

      expect(() => Vehicle.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('toCreateUpdateJson contains strictly the six business fields and excludes id', () {
      const vehicle = Vehicle(
        id: 999,
        vehicleNumber: 'SG-2024-X',
        company: 'Stark Logistics',
        type: 'Van',
        brand: 'Ford',
        model: 'Transit',
        status: VehicleStatus.maintenance,
      );

      final json = vehicle.toCreateUpdateJson();
      expect(json.containsKey('id'), isFalse);
      expect(json['vehicleNumber'], equals('SG-2024-X'));
      expect(json['company'], equals('Stark Logistics'));
      expect(json['type'], equals('Van'));
      expect(json['brand'], equals('Ford'));
      expect(json['model'], equals('Transit'));
      expect(json['status'], equals('MAINTENANCE'));
    });
  });

  group('VehicleApiClient HTTP Operations', () {
    test('getVehicles sends GET to /api/vehicles and parses list', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/vehicles'));
        expect(request.headers['Accept'], equals('application/json'));

        final responseBody = jsonEncode([
          {
            'id': 1,
            'vehicleNumber': 'SG-1001',
            'company': 'Stark Industries',
            'type': 'Sedan',
            'brand': 'Tesla',
            'model': 'Model S',
            'status': 'ACTIVE',
          }
        ]);
        return http.Response(responseBody, 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final vehicles = await apiClient.getVehicles();

      expect(vehicles.length, equals(1));
      expect(vehicles.first.id, equals(1));
      expect(vehicles.first.vehicleNumber, equals('SG-1001'));
    });

    test('createVehicle sends POST with JSON body and parses created vehicle', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/vehicles'));
        expect(request.headers['Content-Type'], contains('application/json'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['vehicleNumber'], equals('SG-2024'));
        expect(body.containsKey('id'), isFalse);

        final responseBody = jsonEncode({
          'id': 101,
          'vehicleNumber': 'SG-2024',
          'company': 'Stark Security',
          'type': 'SUV',
          'brand': 'Ford',
          'model': 'Explorer',
          'status': 'ACTIVE',
        });
        return http.Response(responseBody, 201, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      final created = await apiClient.createVehicle({
        'vehicleNumber': 'SG-2024',
        'company': 'Stark Security',
        'type': 'SUV',
        'brand': 'Ford',
        'model': 'Explorer',
        'status': 'ACTIVE',
      });

      expect(created.id, equals(101));
      expect(created.vehicleNumber, equals('SG-2024'));
    });

    test('deleteVehicle handles 204 No Content with empty body without JSON errors', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, equals('/api/vehicles/42'));
        return http.Response('', 204);
      });

      final apiClient = VehicleApiClient(client: mockClient);
      await expectLater(apiClient.deleteVehicle(42), completes);
    });

    test('Parses 400 validation error with fieldErrors list', () async {
      final mockClient = MockClient((request) async {
        final errorPayload = jsonEncode({
          'timestamp': '2026-11-03T00:00:00Z',
          'status': 400,
          'code': 'VALIDATION_FAILED',
          'message': 'Validation failed for request',
          'path': '/api/vehicles',
          'fieldErrors': [
            {'field': 'vehicleNumber', 'message': 'Vehicle number must not be blank'}
          ]
        });
        return http.Response(errorPayload, 400, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      try {
        await apiClient.createVehicle({});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, equals(400));
        expect(e.code, equals('VALIDATION_FAILED'));
        expect(e.isValidationFailed, isTrue);
        expect(e.getFieldError('vehicleNumber'), equals('Vehicle number must not be blank'));
      }
    });

    test('Parses 409 duplicate vehicle number error', () async {
      final mockClient = MockClient((request) async {
        final errorPayload = jsonEncode({
          'timestamp': '2026-11-03T00:00:00Z',
          'status': 409,
          'code': 'DUPLICATE_VEHICLE_NUMBER',
          'message': 'A vehicle with this Vehicle Number already exists.',
          'path': '/api/vehicles'
        });
        return http.Response(errorPayload, 409, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      try {
        await apiClient.createVehicle({'vehicleNumber': 'SG-1001'});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, equals(409));
        expect(e.isDuplicateVehicleNumber, isTrue);
        expect(e.message, contains('already exists'));
      }
    });

    test('Parses 404 vehicle not found error', () async {
      final mockClient = MockClient((request) async {
        final errorPayload = jsonEncode({
          'timestamp': '2026-11-03T00:00:00Z',
          'status': 404,
          'code': 'VEHICLE_NOT_FOUND',
          'message': 'Vehicle not found with ID: 999',
          'path': '/api/vehicles/999'
        });
        return http.Response(errorPayload, 404, headers: {'content-type': 'application/json'});
      });

      final apiClient = VehicleApiClient(client: mockClient);
      try {
        await apiClient.getVehicle(999);
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, equals(404));
        expect(e.isNotFound, isTrue);
      }
    });
  });
}

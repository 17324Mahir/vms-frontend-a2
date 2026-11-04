import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stark_vms/core/theme/app_theme.dart';
import 'package:stark_vms/data/api/vehicle_api_client.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
import 'package:stark_vms/data/vehicle_repository.dart';
import 'package:stark_vms/router/app_router.dart';
import 'package:stark_vms/screens/auth/login_screen.dart';

void main() {
  setUp(() {
    AuthService.instance.setAuthenticatedForTesting(
      email: 'admin@starkgroup.test',
      token: 'valid-test-bearer-token',
    );
  });

  Widget buildApp({String initialRoute = AppRouter.vehiclesRoute}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  group('Vehicle CRUD Workflow Tests', () {
    testWidgets('1. Initial list loading shows clear loading treatment',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) => completer.future);
      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pump(); // Start frame without settling async future

      expect(find.text('Loading fleet registry...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));

      completer.complete(
          http.Response('[]', 200, headers: {'content-type': 'application/json'}));
      await tester.pumpAndSettle();
    });

    testWidgets('2. Successful load displays records in the table',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockVehicles = [
        {
          'id': 10,
          'vehicleNumber': 'STK-0010',
          'company': 'Stark Industries',
          'type': 'Sedan',
          'brand': 'Audi',
          'model': 'e-tron GT',
          'status': 'ACTIVE',
        },
        {
          'id': 20,
          'vehicleNumber': 'STK-0020',
          'company': 'Stark Logistics',
          'type': 'Van',
          'brand': 'Ford',
          'model': 'Transit',
          'status': 'MAINTENANCE',
        },
      ];

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockVehicles), 200,
            headers: {'content-type': 'application/json'});
      });
      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('STK-0010'), findsOneWidget);
      expect(find.text('STK-0020'), findsOneWidget);
      expect(find.text('Total: 2 vehicles'), findsOneWidget);
    });

    testWidgets(
        '3. Empty collection displays true empty state with Register Vehicle action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      });
      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No vehicles registered'), findsOneWidget);
      expect(
          find.widgetWithText(ElevatedButton, 'Register vehicle'), findsAtLeast(1));
    });

    testWidgets(
        '4. Failed load displays useful error and Retry button recovers state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            jsonEncode({
              'status': 500,
              'code': 'INTERNAL_ERROR',
              'message': 'Database connection refused.',
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'vehicleNumber': 'STK-RECOVERED',
              'company': 'Stark Industries',
              'type': 'Sedan',
              'brand': 'Tesla',
              'model': 'Model S',
              'status': 'ACTIVE',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Unable to load fleet data'), findsOneWidget);
      expect(find.textContaining('Database connection refused'), findsOneWidget);

      final retryBtn = find.widgetWithText(ElevatedButton, 'Retry connection');
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(find.text('STK-RECOVERED'), findsOneWidget);
    });

    testWidgets(
        '5. Refresh failure preserves existing records and shows warning banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'vehicleNumber': 'STK-PRESERVED',
                'company': 'Stark Industries',
                'type': 'Sedan',
                'brand': 'Tesla',
                'model': 'Model S',
                'status': 'ACTIVE',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'status': 503,
            'code': 'SERVICE_UNAVAILABLE',
            'message': 'Temporary network disconnect.',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('STK-PRESERVED'), findsOneWidget);

      // Trigger refresh
      final refreshBtn = find.byTooltip('Refresh');
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      // Previously loaded vehicle is STILL visible
      expect(find.text('STK-PRESERVED'), findsOneWidget);
      // Warning banner is displayed
      expect(
          find.textContaining(
              'Could not refresh fleet data: Temporary network disconnect.'),
          findsOneWidget);
    });

    testWidgets('6. Successful create uses server-returned ID and returns to list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/vehicles') {
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.method == 'POST' && request.url.path == '/api/vehicles') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          // Server returns generated numeric ID 777
          final created = {
            'id': 777,
            'vehicleNumber': body['vehicleNumber'],
            'company': body['company'],
            'type': body['type'],
            'brand': body['brand'],
            'model': body['model'],
            'status': body['status'],
          };
          return http.Response(jsonEncode(created), 201,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Click register
      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Register vehicle').first);
      await tester.pumpAndSettle();

      expect(find.text('Register Vehicle'), findsAtLeast(1));

      // Fill form
      await tester.enterText(find.byType(TextFormField).at(0), 'STK-777');
      await tester.enterText(find.byType(TextFormField).at(1), 'Stark Jets');
      await tester.enterText(find.byType(TextFormField).at(2), 'Sky Cruiser');

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register vehicle'));
      await tester.pumpAndSettle();

      // Returned to list and shows success SnackBar
      expect(find.text('Fleet Registry'), findsOneWidget);
      expect(
          find.text('Vehicle STK-777 successfully registered.'), findsOneWidget);
      expect(find.text('STK-777'), findsOneWidget);

      // Verify repository has the server-generated ID
      final saved =
          repo.allVehicles.firstWhere((v) => v.vehicleNumber == 'STK-777');
      expect(saved.id, equals(777));
    });

    testWidgets('7. Create failure preserves entered inputs and shows error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'status': 500,
              'code': 'INTERNAL_ERROR',
              'message': 'Failed to insert row into database.',
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Register vehicle').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'STK-FAIL-01');
      await tester.enterText(find.byType(TextFormField).at(1), 'Preserved Brand');
      await tester.enterText(find.byType(TextFormField).at(2), 'Preserved Model');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register vehicle'));
      await tester.pumpAndSettle();

      // Form remains open and entered inputs are intact
      expect(find.text('Register Vehicle'), findsAtLeast(1));
      expect(find.text('STK-FAIL-01'), findsOneWidget);
      expect(find.text('Preserved Brand'), findsOneWidget);
      expect(find.text('Preserved Model'), findsOneWidget);
      expect(
          find.textContaining('Failed to insert row into database.'), findsOneWidget);
    });

    testWidgets(
        '8. Successful update preserves existing ID without duplicating row',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final initialVehicle = {
        'id': 42,
        'vehicleNumber': 'STK-0042',
        'company': 'Stark Industries',
        'type': 'Sedan',
        'brand': 'Audi',
        'model': 'R8',
        'status': 'ACTIVE',
      };

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/vehicles') {
          return http.Response(jsonEncode([initialVehicle]), 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.method == 'PUT' && request.url.path == '/api/vehicles/42') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final updated = {
            'id': 42, // Preserves ID 42
            'vehicleNumber': body['vehicleNumber'],
            'company': body['company'],
            'type': body['type'],
            'brand': body['brand'],
            'model': body['model'],
            'status': body['status'],
          };
          return http.Response(jsonEncode(updated), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap Edit icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Vehicle'), findsAtLeast(1));

      // Change Model
      await tester.enterText(find.byType(TextFormField).at(2), 'R8 V10 Plus');

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      // Back on list
      expect(find.text('Fleet Registry'), findsOneWidget);
      expect(
          find.text('Vehicle STK-0042 successfully updated.'), findsOneWidget);

      // Verify row count is strictly 1 (no duplicate row added)
      expect(repo.totalCount, equals(1));
      final updated = repo.allVehicles.first;
      expect(updated.id, equals(42));
      expect(updated.model, equals('R8 V10 Plus'));
    });

    testWidgets(
        '9. Duplicate-number error displays inline on Vehicle Number field',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response('[]', 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'status': 409,
              'code': 'DUPLICATE_VEHICLE_NUMBER',
              'message': 'Vehicle with number STK-DUPE already exists',
              'fieldErrors': [
                {
                  'field': 'vehicleNumber',
                  'message': 'A vehicle with this Vehicle Number already exists.',
                }
              ],
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Register vehicle').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'STK-DUPE');
      await tester.enterText(find.byType(TextFormField).at(1), 'Brand');
      await tester.enterText(find.byType(TextFormField).at(2), 'Model');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register vehicle'));
      await tester.pumpAndSettle();

      // Inline error appears under Vehicle Number
      expect(
          find.text('A vehicle with this Vehicle Number already exists.'),
          findsOneWidget);
      // Form stays open
      expect(find.text('Register Vehicle'), findsAtLeast(1));
    });

    testWidgets(
        '10. Canceling delete dialog makes no request and preserves record',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool deleteAttempted = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 100,
                'vehicleNumber': 'STK-KEEP-ME',
                'company': 'Stark Industries',
                'type': 'Sedan',
                'brand': 'Audi',
                'model': 'A8',
                'status': 'ACTIVE',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          deleteAttempted = true;
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('STK-KEEP-ME'), findsOneWidget);

      // Click delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmation dialog is shown
      expect(find.text('Delete Vehicle'), findsAtLeast(1));
      expect(find.textContaining('STK-KEEP-ME'), findsAtLeast(1));

      // Click Keep Vehicle (Cancel)
      await tester.tap(find.widgetWithText(OutlinedButton, 'Keep Vehicle'));
      await tester.pumpAndSettle();

      // Dialog closed, no delete request made, vehicle preserved
      expect(deleteAttempted, isFalse);
      expect(find.text('STK-KEEP-ME'), findsOneWidget);
      expect(repo.totalCount, equals(1));
    });

    testWidgets(
        '11. Successful 204 delete removes record from list and shows confirmation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 101,
                'vehicleNumber': 'STK-DELETE-ME',
                'company': 'Stark Industries',
                'type': 'Sedan',
                'brand': 'Audi',
                'model': 'A8',
                'status': 'ACTIVE',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE' &&
            request.url.path == '/api/vehicles/101') {
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('STK-DELETE-ME'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap Delete Vehicle in confirmation dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Vehicle'));
      await tester.pumpAndSettle();

      // Record removed
      expect(find.text('STK-DELETE-ME'), findsNothing);
      expect(repo.totalCount, equals(0));
      expect(find.text('Vehicle STK-DELETE-ME was removed from the fleet.'),
          findsOneWidget);
      expect(find.text('No vehicles registered'), findsOneWidget);
    });

    testWidgets('12. Failed delete preserves record and shows error message',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 102,
                'vehicleNumber': 'STK-FAIL-DEL',
                'company': 'Stark Industries',
                'type': 'Sedan',
                'brand': 'Audi',
                'model': 'A8',
                'status': 'ACTIVE',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({
              'status': 500,
              'code': 'DATABASE_ERROR',
              'message':
                  'Cannot delete vehicle due to foreign key constraint.',
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Vehicle'));
      await tester.pumpAndSettle();

      // Record preserved
      expect(find.text('STK-FAIL-DEL'), findsOneWidget);
      expect(repo.totalCount, equals(1));
      // Error SnackBar displayed
      expect(
          find.textContaining(
              'Cannot delete vehicle due to foreign key constraint.'),
          findsOneWidget);
    });

    testWidgets(
        '13. Pagination resets to valid page after deleting the only item on page 2',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 11 vehicles: page 1 has 10, page 2 has 1 ('STK-PAGE2-LAST')
      final list = List.generate(
        11,
        (i) => {
          'id': i + 1,
          'vehicleNumber':
              i == 10 ? 'STK-PAGE2-LAST' : 'STK-P1-${i.toString().padLeft(2, '0')}',
          'company': 'Stark Industries',
          'type': 'Sedan',
          'brand': 'Brand',
          'model': 'Model',
          'status': 'ACTIVE',
        },
      );

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(list), 200,
              headers: {'content-type': 'application/json'});
        }
        if (request.method == 'DELETE' &&
            request.url.path == '/api/vehicles/11') {
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final repo = VehicleRepository(
        apiClient: VehicleApiClient(client: mockClient),
      );
      VehicleRepository.setInstanceForTesting(repo);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Page 1 of 2'), findsOneWidget);

      // Navigate to page 2
      final nextPageBtn = find.widgetWithText(OutlinedButton, 'Next');
      await tester.tap(nextPageBtn);
      await tester.pumpAndSettle();

      expect(find.text('Page 2 of 2'), findsOneWidget);
      expect(find.text('STK-PAGE2-LAST'), findsOneWidget);

      // Delete the only vehicle on page 2
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Vehicle'));
      await tester.pumpAndSettle();

      // Page automatically clamped back to page 1 without empty state or error
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.text('Total: 10 vehicles'), findsOneWidget);
    });

    testWidgets('14. Unauthenticated route access redirects immediately to Login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Explicitly sign out
      AuthService.instance.signOut();

      await tester.pumpWidget(buildApp(initialRoute: AppRouter.vehiclesRoute));
      await tester.pumpAndSettle();

      // Guarded: redirected to Login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
    });
  });
}

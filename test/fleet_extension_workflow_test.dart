import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stark_vms/core/theme/app_theme.dart';
import 'package:stark_vms/data/api/dashboard_api_client.dart';
import 'package:stark_vms/data/api/driver_api_client.dart';
import 'package:stark_vms/data/api/vehicle_api_client.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
import 'package:stark_vms/data/driver_repository.dart';
import 'package:stark_vms/data/vehicle_repository.dart';
import 'package:stark_vms/models/driver.dart';
import 'package:stark_vms/models/maintenance_record.dart';
import 'package:stark_vms/models/vehicle.dart';
import 'package:stark_vms/models/vehicle_document.dart';
import 'package:stark_vms/router/app_router.dart';
import 'package:stark_vms/screens/dashboard/dashboard_screen.dart';
import 'package:stark_vms/screens/documents/document_list_screen.dart';
import 'package:stark_vms/screens/drivers/driver_form_screen.dart';
import 'package:stark_vms/screens/drivers/driver_list_screen.dart';
import 'package:stark_vms/screens/maintenance/maintenance_list_screen.dart';
import 'package:stark_vms/screens/vehicles/vehicle_details_screen.dart';
import 'package:stark_vms/screens/vehicles/vehicle_form_screen.dart';

void main() {
  setUp(() {
    AuthService.instance.setAuthenticatedForTesting(
      email: 'admin@starkgroup.com',
      token: 'synthetic-jwt-test-token',
    );
  });

  tearDown(() {
    AuthService.instance.signOut();
  });

  testWidgets(
    'Dashboard renders fleet data at desktop and phone widths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final httpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'totalVehicles': 12,
            'activeVehicles': 8,
            'maintenanceVehicles': 2,
            'inactiveVehicles': 2,
            'expiredDocuments': 2,
            'expiringSoonDocuments': 3,
            'totalMaintenanceCost': 720.75,
            'upcomingExpiries': [
              {
                'id': 1,
                'vehicleId': 17,
                'vehicleNumber': 'STK-17',
                'documentType': 'INSURANCE',
                'documentNumber': 'DOC-17',
                'expiryDate': '2030-07-15',
                'expiryStatus': 'EXPIRING_SOON',
              },
            ],
            'recentMaintenance': [
              {
                'id': 1,
                'vehicleId': 18,
                'vehicleNumber': 'STK-18',
                'maintenanceType': 'OTHER',
                'maintenanceDate': '2030-07-12',
                'workshopVendor': 'Stark Workshop',
                'odometerReading': 12000,
                'cost': 120.64,
              },
            ],
          }),
          200,
        );
      });
      addTearDown(httpClient.close);
      final apiClient = DashboardApiClient(client: httpClient);

      for (final width in [1440.0, 390.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: DashboardScreen(apiClient: apiClient),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Fleet Dashboard'), findsOneWidget);
        expect(find.text('Vehicle status'), findsOneWidget);
        expect(find.text('8 active in service'), findsOneWidget);
        expect(find.text('2 expired, 3 within 30 days'), findsOneWidget);
        expect(find.textContaining('DOC-17'), findsOneWidget);
        expect(find.textContaining('Stark Workshop'), findsOneWidget);
      }
    },
  );

  testWidgets('DriverListScreen renders title and Add Driver action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DriverListScreen(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    expect(find.text('Drivers'), findsWidgets);
    expect(find.text('Add Driver'), findsWidgets);
  });

  testWidgets('DriverFormScreen renders required fields and validates input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DriverFormScreen(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    expect(find.text('Register New Driver'), findsOneWidget);
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Driver License Number *'), findsOneWidget);

    // Attempt to submit empty form
    final saveButton = find.text('Save Driver');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Driver name is required'), findsOneWidget);
  });

  testWidgets('Vehicle details resolves refreshable links and legacy arguments',
      (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final path = AppRouter.vehicleDetailsPath(99, initialTab: 1);
    final routeSettings = [
      RouteSettings(name: path),
      const RouteSettings(
        name: AppRouter.vehicleDetailsRoute,
        arguments: {'id': 99, 'initialTab': 1},
      ),
    ];

    for (final settings in routeSettings) {
      final route = AppRouter.generateRoute(settings) as MaterialPageRoute;
      final details = route.builder(context) as VehicleDetailsScreen;
      expect(details.vehicleId, 99);
      expect(details.initialTab, 1);
      expect(route.settings.name, path);
    }
  });

  testWidgets('Invalid vehicle details URLs show a recovery screen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      onGenerateInitialRoutes: (_) => [
        AppRouter.generateRoute(
          const RouteSettings(name: '/vehicles/details?id=%FF'),
        ),
      ],
    ));

    expect(find.text('Back to Vehicles'), findsOneWidget);
    expect(find.byType(VehicleDetailsScreen), findsNothing);
  });

  testWidgets('VehicleDetailsScreen renders tabs for Documents and Maintenance', (tester) async {
    final testVehicle = Vehicle(
      id: 99,
      vehicleNumber: 'SG-TEST-99',
      company: 'Stark Industries',
      type: 'Sedan',
      brand: 'Audi',
      model: 'e-tron',
      status: VehicleStatus.active,
    );
    VehicleRepository.instance.reset([testVehicle]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VehicleDetailsScreen(
          vehicleId: 99,
          initialVehicle: testVehicle,
        ),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
    await tester.pump();

    expect(find.text('SG-TEST-99 Details'), findsOneWidget);
    expect(find.text('Documents (0)'), findsOneWidget);
    expect(find.text('Maintenance History (0)'), findsOneWidget);
  });

  group('Existing driver assignments', () {
    const driver = DriverSummary(
      id: 14,
      name: 'Avery Driver',
      licenseNumber: 'DL-014',
      status: 'ASSIGNED',
    );
    const vehicle = Vehicle(
      id: 77,
      vehicleNumber: 'SG-77',
      company: 'Stark Industries',
      type: 'Sedan',
      brand: 'Audi',
      model: 'e-tron',
      status: VehicleStatus.active,
      assignedDriver: driver,
    );

    setUp(() {
      final originalDrivers = DriverRepository.instance;
      final originalVehicles = VehicleRepository.instance;
      addTearDown(() {
        DriverRepository.instance = originalDrivers;
        VehicleRepository.setInstanceForTesting(originalVehicles);
      });
    });

    testWidgets('can unassign a driver absent from the available list', (tester) async {
      DriverRepository.instance = DriverRepository(
        apiClient: DriverApiClient(client: MockClient((request) async {
          expect(request.url.path, '/api/drivers/available');
          return http.Response('[]', 200);
        })),
      );
      var unassignRequests = 0;
      VehicleRepository.setInstanceForTesting(VehicleRepository(
        apiClient: VehicleApiClient(client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/vehicles/77/unassign-driver');
          unassignRequests++;
          return http.Response(jsonEncode(vehicle.toMap()), 200);
        })),
      ));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const VehicleDetailsScreen(vehicleId: 77, initialVehicle: vehicle),
      ));

      await tester.tap(find.text('Driver: Avery Driver'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Avery Driver (DL-014)'), findsOneWidget);
      await tester.tap(find.text('Save Assignment'));
      await tester.pumpAndSettle();
      expect(unassignRequests, 0);

      await tester.tap(find.text('Driver: Avery Driver'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No Driver (Unassigned)').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Assignment'));
      await tester.pumpAndSettle();

      expect(unassignRequests, 1);
      expect(find.text('Assign Driver'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing retains the driver when the available list fails', (tester) async {
      DriverRepository.instance = DriverRepository(
        apiClient: DriverApiClient(client: MockClient((request) async {
          expect(request.url.path, '/api/drivers/available');
          return http.Response('', 500);
        })),
      );
      Map<String, dynamic>? payload;
      VehicleRepository.setInstanceForTesting(VehicleRepository(
        apiClient: VehicleApiClient(client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/vehicles/77');
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(vehicle.toMap()), 200);
        })),
      ));

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: const VehicleFormScreen(vehicleToEdit: vehicle),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Avery Driver (DL-014)'), findsOneWidget);

      final save = find.text('Save changes');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(payload?['assignedDriverId'], 14);
      expect(tester.takeException(), isNull);
    });
  });

  test('Document expiry status calculations are accurate', () {
    final expiredDoc = VehicleDocument(
      id: 1,
      vehicleId: 10,
      documentType: DocumentType.insurance,
      expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      expiryStatus: 'EXPIRED',
      daysUntilExpiry: -5,
    );

    expect(expiredDoc.expiryStatus, 'EXPIRED');
    expect(expiredDoc.expiryStatusLabel, contains('Expired (5 d ago)'));

    final expiringSoonDoc = VehicleDocument(
      id: 2,
      vehicleId: 10,
      documentType: DocumentType.taxToken,
      expiryDate: DateTime.now().add(const Duration(days: 12)),
      expiryStatus: 'EXPIRING_SOON',
      daysUntilExpiry: 12,
    );

    expect(expiringSoonDoc.expiryStatus, 'EXPIRING_SOON');
    expect(expiringSoonDoc.expiryStatusLabel, contains('Expiring in 12 d'));
  });

  test('DriverStatus and MaintenanceType serialization works correctly', () {
    expect(DriverStatus.available.toBackendString(), 'AVAILABLE');
    expect(DriverStatus.assigned.toBackendString(), 'ASSIGNED');
    expect(DriverStatus.fromBackendString('ON_LEAVE'), DriverStatus.onLeave);

    expect(MaintenanceType.routineService.toBackendString(), 'ROUTINE_SERVICE');
    expect(MaintenanceType.oilChange.toBackendString(), 'OIL_CHANGE');
    expect(MaintenanceType.fromBackendString('BRAKE_SERVICE'), MaintenanceType.brakeService);
  });

  testWidgets('DocumentListScreen renders Fleet Documents title and refresh button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DocumentListScreen(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    expect(find.text('Fleet Documents'), findsWidgets);
  });

  testWidgets('MaintenanceListScreen renders Fleet Maintenance title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MaintenanceListScreen(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    expect(find.text('Fleet Maintenance'), findsWidgets);
  });

  testWidgets('VehicleDetailsScreen opens Maintenance History tab when initialTab is 1', (tester) async {
    final testVehicle = Vehicle(
      id: 88,
      vehicleNumber: 'SG-TAB-88',
      company: 'Stark Industries',
      type: 'SUV',
      brand: 'Tesla',
      model: 'Model X',
      status: VehicleStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VehicleDetailsScreen(
          vehicleId: 88,
          initialVehicle: testVehicle,
          initialTab: 1,
        ),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
    await tester.pump();

    // Verify Tab 1 content is visible (Lifetime Spend)
    expect(find.textContaining('Lifetime Spend:'), findsOneWidget);
  });
}

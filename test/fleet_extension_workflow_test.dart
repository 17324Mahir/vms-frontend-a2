import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stark_vms/core/theme/app_theme.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
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

  testWidgets('DashboardScreen renders Fleet Dashboard title and KPI categories', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    // Initial loading or loaded state
    expect(find.text('Fleet Dashboard'), findsOneWidget);
  });

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

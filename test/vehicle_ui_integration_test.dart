import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stark_vms/core/theme/app_theme.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
import 'package:stark_vms/data/vehicle_repository.dart';
import 'package:stark_vms/models/vehicle.dart';
import 'package:stark_vms/router/app_router.dart';

void main() {
  setUp(() {
    AuthService.instance.setAuthenticatedForTesting(email: 'tester@starkgroup.test');
  });

  Widget buildApp() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.vehiclesRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }

  testWidgets('Renders empty fleet state when repository has 0 records',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = VehicleRepository.fake(initialVehicles: []);
    VehicleRepository.setInstanceForTesting(fakeRepo);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No vehicles registered'), findsOneWidget);
    expect(find.text('The fleet registry is currently empty. Add your first vehicle to get started.'), findsOneWidget);
  });

  testWidgets('Renders error state with Retry button when initial load fails',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = VehicleRepository.fake(initialVehicles: []);
    VehicleRepository.setInstanceForTesting(fakeRepo);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Force error state
    fakeRepo.reset([]);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    fakeRepo.notifyListeners();

    expect(find.text('No vehicles registered'), findsOneWidget);
  });

  testWidgets('Backend 409 duplicate vehicle number preserves form input and shows inline error',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final fakeRepo = VehicleRepository.fake(initialVehicles: [
      const Vehicle(
        id: 1,
        vehicleNumber: 'SG-1001',
        company: 'Stark Industries',
        type: 'Sedan',
        brand: 'Tesla',
        model: 'Model S',
        status: VehicleStatus.active,
      )
    ]);
    VehicleRepository.setInstanceForTesting(fakeRepo);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Open Register Vehicle screen
    await tester.tap(find.text('Register vehicle'));
    await tester.pumpAndSettle();

    // Fill form with duplicate number
    await tester.enterText(find.byType(TextFormField).at(0), 'sg-1001');
    await tester.enterText(find.byType(TextFormField).at(1), 'Tesla');
    await tester.enterText(find.byType(TextFormField).at(2), 'Model 3');

    // Tap Register
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register vehicle'));
    await tester.pumpAndSettle();

    // Form remains open and displays duplicate error
    expect(find.text('Register Vehicle'), findsAtLeast(1));
    expect(find.textContaining('already registered'), findsOneWidget);
    // Values preserved
    expect(find.text('Tesla'), findsOneWidget);
    expect(find.text('Model 3'), findsOneWidget);
  });
}

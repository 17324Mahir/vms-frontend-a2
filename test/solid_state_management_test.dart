import 'package:flutter_test/flutter_test.dart';
import 'package:stark_vms/data/auth/auth_service.dart';
import 'package:stark_vms/data/auth/session_storage.dart';
import 'package:stark_vms/data/driver_repository.dart';
import 'package:stark_vms/data/vehicle_repository.dart';
import 'package:stark_vms/models/vehicle.dart';

class _InMemorySessionStorage extends SessionStorage {
  final Map<String, String> _data = {};

  @override
  void write(String key, String value) => _data[key] = value;

  @override
  String? read(String key) => _data[key];

  @override
  void remove(String key) => _data.remove(key);

  @override
  void clear() => _data.clear();
}

/// Test-Driven Specification for ADR-003: Client State Management & Cache Reconciliation.
/// Validates SOLID principles (SRP, DIP) and Zero-Trust tenant session clearing in Flutter.
void main() {
  group('SOLID Architecture & Client State Management Specifications', () {
    setUp(() {
      AuthService.instance.signOut();
      VehicleRepository.instance.clearCache();
      DriverRepository.instance.clearCache();
      SessionStorage.resetInstance();
    });

    tearDown(() {
      AuthService.instance.signOut();
      VehicleRepository.instance.clearCache();
      DriverRepository.instance.clearCache();
      SessionStorage.resetInstance();
    });

    test('SRP & DIP: VehicleRepository acts as reactive Single-Source-of-Truth with ChangeNotifier', () {
      final fakeRepo = VehicleRepository.fake(initialVehicles: [
        const Vehicle(
          id: 101,
          vehicleNumber: 'SOLID-V-01',
          company: 'Acme Fleet',
          type: 'Electric',
          brand: 'Tesla',
          model: 'Model Y',
          status: VehicleStatus.active,
        ),
      ]);

      int notificationCount = 0;
      void listener() => notificationCount++;

      fakeRepo.addListener(listener);

      expect(fakeRepo.allVehicles.length, 1);
      expect(fakeRepo.allVehicles.first.vehicleNumber, 'SOLID-V-01');

      fakeRepo.clearCache();
      expect(notificationCount, 1);
      expect(fakeRepo.allVehicles, isEmpty);

      fakeRepo.removeListener(listener);
    });

    test('Data Ownership & Security Guardrail: Sign-out executes clean repository purge across contexts', () async {
      final fakeRepo = VehicleRepository.fake(initialVehicles: [
        const Vehicle(
          id: 201,
          vehicleNumber: 'TENANT-A-01',
          company: 'Confidential Tenant A',
          type: 'Diesel',
          brand: 'Volvo',
          model: 'FH16',
          status: VehicleStatus.active,
        ),
      ]);
      VehicleRepository.setInstanceForTesting(fakeRepo);

      expect(VehicleRepository.instance.allVehicles, isNotEmpty);

      // Sign out current authenticated tenant
      AuthService.instance.signOut();

      // Assert complete Zero-Trust state purge to prevent cross-tenant UI leakage
      expect(VehicleRepository.instance.allVehicles, isEmpty,
          reason: 'Vehicle repository must be purged on sign-out to prevent data leakage');
    });

    test('DIP Abstraction: Default stub operates gracefully without throwing exceptions in test harness', () {
      final storage = SessionStorage.instance;

      // Operations should be silent no-ops and never throw in VM/mobile test runtime
      expect(() => storage.write('auth_token', 'token-123'), returnsNormally);
      expect(storage.read('auth_token'), isNull);
      expect(() => storage.remove('auth_token'), returnsNormally);
      expect(() => storage.clear(), returnsNormally);
    });

    test('DIP Abstraction: Injected SessionStorage implementation adheres to storage contract', () {
      final testStorage = _InMemorySessionStorage();
      SessionStorage.setInstanceForTesting(testStorage);

      final storage = SessionStorage.instance;
      storage.write('auth_token', 'synthetic-guardrail-jwt');
      storage.write('user_email', 'tenant-test@stark.test');

      expect(storage.read('auth_token'), equals('synthetic-guardrail-jwt'));
      expect(storage.read('user_email'), equals('tenant-test@stark.test'));

      storage.clear();
      expect(storage.read('auth_token'), isNull);
      expect(storage.read('user_email'), isNull);
    });
  });
}

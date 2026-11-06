import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/page_response.dart';
import '../models/vehicle.dart';
import 'api/vehicle_api_client.dart';
import 'mock_data.dart';

/// Field options for sorting the vehicle list.
enum VehicleSortField { vehicleNumber, company }

/// Centralized state manager and repository for Stark Group VMS fleet data.
///
/// Communicates with the Spring Boot backend REST API while providing a
/// single reactive source of truth for the Flutter presentation layer.
class VehicleRepository extends ChangeNotifier {
  static VehicleRepository instance = VehicleRepository();

  /// Injectable instance for unit and widget testing.
  static void setInstanceForTesting(VehicleRepository testRepo) {
    instance = testRepo;
  }

  final VehicleApiClient? _apiClient;
  final bool _isFake;

  VehicleRepository({VehicleApiClient? apiClient})
    : _apiClient = apiClient ?? VehicleApiClient(),
      _isFake = false;

  /// Test-only constructor simulating the backend in-memory without network calls.
  VehicleRepository.fake({List<Vehicle>? initialVehicles})
    : _apiClient = null,
      _isFake = true {
    if (initialVehicles != null) {
      _vehicles.addAll(initialVehicles);
    }
  }

  final List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _fetchCounter = 0;

  /// Unmodifiable view of all vehicle records loaded into memory.
  List<Vehicle> get allVehicles => List.unmodifiable(_vehicles);

  /// Total count of all loaded vehicles.
  int get totalCount => _vehicles.length;

  /// Whether a fetch operation is currently in flight.
  bool get isLoading => _isLoading;

  /// Current network or server error message, if any.
  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;

  /// Clears in-memory vehicle cache upon user sign-out or session invalidation.
  void clearCache() {
    _fetchCounter++;
    _vehicles.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Resets test seed data (used by widget tests).
  void reset([List<Vehicle>? seed]) {
    _vehicles.clear();
    _vehicles.addAll(seed ?? initialMockVehicles);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetches vehicles from `GET /api/vehicles`.
  ///
  /// [silent] keeps the current list displayed without showing a full-page spinner.
  Future<void> fetchVehicles({bool silent = false}) async {
    if (_isFake) return;
    if (_isLoading) return;

    final fetchId = ++_fetchCounter;
    _isLoading = true;
    if (!silent) {
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final serverVehicles = await _apiClient!.getVehicles();
      if (fetchId != _fetchCounter) return;

      _vehicles.clear();
      _vehicles.addAll(serverVehicles);
      _errorMessage = null;
    } catch (e) {
      if (fetchId != _fetchCounter) return;
      _errorMessage = e is ApiException
          ? e.message
          : (e is NetworkException ? e.message : e.toString());
      rethrow;
    } finally {
      if (fetchId == _fetchCounter) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Fetches an individual vehicle from `GET /api/vehicles/{id}` and updates local cache.
  Future<Vehicle> fetchVehicleById(int id) async {
    if (_isFake) {
      final local = getById(id);
      if (local != null) return local;
      throw const ApiException(
        statusCode: 404,
        code: 'VEHICLE_NOT_FOUND',
        message: 'Vehicle not found.',
      );
    }

    final vehicle = await _apiClient!.getVehicle(id);
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
    } else {
      _vehicles.insert(0, vehicle);
    }
    notifyListeners();
    return vehicle;
  }

  /// Registers a new vehicle with the backend and updates local state.
  Future<Vehicle> add(Vehicle vehicle, {int? assignedDriverId}) async {
    if (_isFake) {
      _vehicles.removeWhere((v) => v.id == vehicle.id && v.id != 0);
      _vehicles.insert(0, vehicle);
      notifyListeners();
      return vehicle;
    }

    final created = await _apiClient!.createVehicle(
      vehicle.toCreateUpdateJson(assignedDriverId: assignedDriverId),
    );
    _vehicles.removeWhere((v) => v.id == created.id);
    _vehicles.insert(0, created);
    notifyListeners();
    return created;
  }

  /// Updates an existing vehicle with the backend and updates local state.
  Future<Vehicle> update(Vehicle vehicle, {int? assignedDriverId}) async {
    if (_isFake) {
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle;
        notifyListeners();
      }
      return vehicle;
    }

    final updated = await _apiClient!.updateVehicle(
      vehicle.id,
      vehicle.toCreateUpdateJson(assignedDriverId: assignedDriverId),
    );
    final index = _vehicles.indexWhere((v) => v.id == updated.id);
    if (index != -1) {
      _vehicles[index] = updated;
    } else {
      _vehicles.insert(0, updated);
    }
    notifyListeners();
    return updated;
  }

  /// Quick status update for a vehicle.
  Future<Vehicle> updateStatus(int id, VehicleStatus status) async {
    if (_isFake) {
      final v = getById(id);
      if (v != null) {
        final updated = v.copyWith(status: status);
        final idx = _vehicles.indexWhere((x) => x.id == id);
        if (idx != -1) _vehicles[idx] = updated;
        notifyListeners();
        return updated;
      }
      throw const ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'Vehicle not found',
      );
    }

    final updated = await _apiClient!.updateVehicleStatus(id, status);
    final idx = _vehicles.indexWhere((x) => x.id == id);
    if (idx != -1) {
      _vehicles[idx] = updated;
    } else {
      _vehicles.insert(0, updated);
    }
    notifyListeners();
    return updated;
  }

  /// Assigns a driver to a vehicle.
  Future<Vehicle> assignDriver(int vehicleId, int driverId) async {
    if (_isFake) return getById(vehicleId)!;
    final updated = await _apiClient!.assignDriver(vehicleId, driverId);
    final idx = _vehicles.indexWhere((x) => x.id == vehicleId);
    if (idx != -1) {
      _vehicles[idx] = updated;
    }
    notifyListeners();
    return updated;
  }

  /// Unassigns driver from vehicle.
  Future<Vehicle> unassignDriver(int vehicleId) async {
    if (_isFake) return getById(vehicleId)!;
    final updated = await _apiClient!.unassignDriver(vehicleId);
    final idx = _vehicles.indexWhere((x) => x.id == vehicleId);
    if (idx != -1) {
      _vehicles[idx] = updated;
    }
    notifyListeners();
    return updated;
  }

  Future<List<String>> fetchCompanies() async {
    if (!_isFake) return _apiClient!.getCompanies();
    return _vehicles.map((vehicle) => vehicle.company).toSet().toList()..sort();
  }

  /// Server-side paginated and filtered search.
  Future<PageResponse<Vehicle>> searchPaged({
    int page = 0,
    int size = 10,
    String? search,
    VehicleStatus? status,
    String? company,
    VehicleSortField sortField = VehicleSortField.vehicleNumber,
    bool sortAscending = true,
  }) async {
    if (_isFake) {
      final filtered = query(
        searchQuery: search,
        statusFilter: status,
        companyFilter: company,
        sortField: sortField,
        sortAscending: sortAscending,
      );
      final start = min(page * size, filtered.length);
      final end = min(start + size, filtered.length);
      final totalPages = (filtered.length / size).ceil();
      return PageResponse(
        content: filtered.sublist(start, end),
        page: page,
        size: size,
        totalElements: filtered.length,
        totalPages: totalPages,
        first: page == 0,
        last: page + 1 >= totalPages,
      );
    }
    return _apiClient!.searchVehicles(
      page: page,
      size: size,
      search: search,
      status: status,
      company: company,
      sortBy: sortField.name,
      sortDir: sortAscending ? 'asc' : 'desc',
    );
  }

  /// Deletes a vehicle by its unique ID.
  Future<void> delete(int id) async {
    if (_isFake) {
      _vehicles.removeWhere((v) => v.id == id);
      notifyListeners();
      return;
    }

    try {
      await _apiClient!.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isNotFound) {
        // Vehicle already removed remotely; reconcile local list
        _vehicles.removeWhere((v) => v.id == id);
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Retrieve a vehicle from local memory by its unique stable ID.
  Vehicle? getById(int id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check whether a vehicle number already exists (case-insensitive client advisory).
  bool isVehicleNumberDuplicate(String vehicleNumber, {int? excludeId}) {
    final normalized = vehicleNumber.trim().toUpperCase();
    return _vehicles.any((v) {
      if (excludeId != null && v.id == excludeId) return false;
      return v.vehicleNumber.trim().toUpperCase() == normalized;
    });
  }

  /// Filter, search, and sort vehicles against the loaded dataset.
  List<Vehicle> query({
    String? searchQuery,
    VehicleStatus? statusFilter,
    String? companyFilter,
    VehicleSortField sortField = VehicleSortField.vehicleNumber,
    bool sortAscending = true,
  }) {
    // 1. Filter
    final filtered = _vehicles.where((vehicle) {
      // Search matching Vehicle Number, Company, Brand, and Model
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matches =
            vehicle.vehicleNumber.toLowerCase().contains(q) ||
            vehicle.company.toLowerCase().contains(q) ||
            vehicle.brand.toLowerCase().contains(q) ||
            vehicle.model.toLowerCase().contains(q);
        if (!matches) return false;
      }

      // Status filter
      if (statusFilter != null && vehicle.status != statusFilter) {
        return false;
      }

      // Company filter
      if (companyFilter != null &&
          companyFilter.isNotEmpty &&
          companyFilter != 'All Companies' &&
          vehicle.company != companyFilter) {
        return false;
      }

      return true;
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      int comparison;
      switch (sortField) {
        case VehicleSortField.vehicleNumber:
          comparison = a.vehicleNumber.compareTo(b.vehicleNumber);
          break;
        case VehicleSortField.company:
          comparison = a.company.compareTo(b.company);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });

    return filtered;
  }
}

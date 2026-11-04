import 'package:flutter/foundation.dart';
import '../core/errors/api_exception.dart';
import '../models/driver.dart';
import '../models/page_response.dart';
import 'api/driver_api_client.dart';

class DriverRepository extends ChangeNotifier {
  static DriverRepository instance = DriverRepository();

  final DriverApiClient _apiClient;

  DriverRepository({DriverApiClient? apiClient})
      : _apiClient = apiClient ?? DriverApiClient();

  final List<Driver> _drivers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Driver> get drivers => List.unmodifiable(_drivers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearCache() {
    _drivers.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDrivers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _apiClient.getAllDrivers();
      _drivers.clear();
      _drivers.addAll(list);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : (e is NetworkException ? e.message : e.toString());
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PageResponse<Driver>> searchDrivers({
    int page = 0,
    int size = 10,
    String? search,
    DriverStatus? status,
    String sortBy = 'name',
    String sortDir = 'asc',
  }) async {
    return _apiClient.searchDrivers(
      page: page,
      size: size,
      search: search,
      status: status,
      sortBy: sortBy,
      sortDir: sortDir,
    );
  }

  Future<List<Driver>> getAvailableDrivers() async {
    try {
      return await _apiClient.getAvailableDrivers();
    } catch (_) {
      return [];
    }
  }

  Future<Driver> getDriverById(int id) async {
    return _apiClient.getDriver(id);
  }

  Future<Driver> createDriver(Map<String, dynamic> payload) async {
    final created = await _apiClient.createDriver(payload);
    _drivers.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<Driver> updateDriver(int id, Map<String, dynamic> payload) async {
    final updated = await _apiClient.updateDriver(id, payload);
    final index = _drivers.indexWhere((d) => d.id == id);
    if (index != -1) {
      _drivers[index] = updated;
    }
    notifyListeners();
    return updated;
  }

  Future<void> deleteDriver(int id) async {
    await _apiClient.deleteDriver(id);
    _drivers.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}

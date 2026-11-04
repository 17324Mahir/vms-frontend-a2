import 'vehicle_document.dart';
import 'maintenance_record.dart';

class DashboardStats {
  final int totalVehicles;
  final int activeVehicles;
  final int maintenanceVehicles;
  final int inactiveVehicles;
  final int totalDrivers;
  final int availableDrivers;
  final int assignedDrivers;
  final int totalDocuments;
  final int expiredDocuments;
  final int expiringSoonDocuments;
  final double totalMaintenanceCost;
  final int totalMaintenanceRecords;
  final List<VehicleDocument> upcomingExpiries;
  final List<MaintenanceRecord> recentMaintenance;

  const DashboardStats({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.maintenanceVehicles,
    required this.inactiveVehicles,
    required this.totalDrivers,
    required this.availableDrivers,
    required this.assignedDrivers,
    required this.totalDocuments,
    required this.expiredDocuments,
    required this.expiringSoonDocuments,
    required this.totalMaintenanceCost,
    required this.totalMaintenanceRecords,
    required this.upcomingExpiries,
    required this.recentMaintenance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final expiries = (json['upcomingExpiries'] as List<dynamic>? ?? [])
        .map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>))
        .toList();
    final maintenance = (json['recentMaintenance'] as List<dynamic>? ?? [])
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardStats(
      totalVehicles: json['totalVehicles'] as int? ?? 0,
      activeVehicles: json['activeVehicles'] as int? ?? 0,
      maintenanceVehicles: json['maintenanceVehicles'] as int? ?? 0,
      inactiveVehicles: json['inactiveVehicles'] as int? ?? 0,
      totalDrivers: json['totalDrivers'] as int? ?? 0,
      availableDrivers: json['availableDrivers'] as int? ?? 0,
      assignedDrivers: json['assignedDrivers'] as int? ?? 0,
      totalDocuments: json['totalDocuments'] as int? ?? 0,
      expiredDocuments: json['expiredDocuments'] as int? ?? 0,
      expiringSoonDocuments: json['expiringSoonDocuments'] as int? ?? 0,
      totalMaintenanceCost: (json['totalMaintenanceCost'] as num?)?.toDouble() ?? 0.0,
      totalMaintenanceRecords: json['totalMaintenanceRecords'] as int? ?? 0,
      upcomingExpiries: expiries,
      recentMaintenance: maintenance,
    );
  }
}


import 'package:flutter/material.dart';

/// Supported vehicle operational statuses.
enum VehicleStatus {
  active('Active'),
  inactive('Inactive'),
  maintenance('Maintenance');

  final String label;
  const VehicleStatus(this.label);

  /// Status string expected by the Spring Boot backend
  String toBackendString() {
    switch (this) {
      case VehicleStatus.active:
        return 'ACTIVE';
      case VehicleStatus.inactive:
        return 'INACTIVE';
      case VehicleStatus.maintenance:
        return 'MAINTENANCE';
    }
  }

  /// Explicitly parses backend status string into [VehicleStatus].
  static VehicleStatus fromBackendString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ACTIVE':
        return VehicleStatus.active;
      case 'INACTIVE':
        return VehicleStatus.inactive;
      case 'MAINTENANCE':
        return VehicleStatus.maintenance;
      default:
        throw FormatException(
          'Unknown vehicle status "$value". Supported statuses are ACTIVE, INACTIVE, MAINTENANCE.',
        );
    }
  }

  /// Status badge text color
  Color get textColor {
    switch (this) {
      case VehicleStatus.active:
        return const Color(0xFF15803D); // Green 700
      case VehicleStatus.inactive:
        return const Color(0xFF475569); // Slate 600
      case VehicleStatus.maintenance:
        return const Color(0xFFB45309); // Amber 700
    }
  }

  /// Status badge background tint
  Color get backgroundColor {
    switch (this) {
      case VehicleStatus.active:
        return const Color(0xFFDCFCE7); // Green 100
      case VehicleStatus.inactive:
        return const Color(0xFFF1F5F9); // Slate 100
      case VehicleStatus.maintenance:
        return const Color(0xFFFEF3C7); // Amber 100
    }
  }

  /// Status badge border color
  Color get borderColor {
    switch (this) {
      case VehicleStatus.active:
        return const Color(0xFF86EFAC); // Green 300
      case VehicleStatus.inactive:
        return const Color(0xFFCBD5E1); // Slate 300
      case VehicleStatus.maintenance:
        return const Color(0xFFFCD34D); // Amber 300
    }
  }

  /// Indicator dot color
  Color get dotColor {
    switch (this) {
      case VehicleStatus.active:
        return const Color(0xFF16A34A); // Green 600
      case VehicleStatus.inactive:
        return const Color(0xFF64748B); // Slate 500
      case VehicleStatus.maintenance:
        return const Color(0xFFD97706); // Amber 600
    }
  }
}

class DriverSummary {
  final int id;
  final String name;
  final String licenseNumber;
  final String? phone;
  final String status;

  const DriverSummary({
    required this.id,
    required this.name,
    required this.licenseNumber,
    this.phone,
    required this.status,
  });

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
    return DriverSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'AVAILABLE',
    );
  }
}

/// Core vehicle domain model representing a fleet asset in the Stark Group VMS.
class Vehicle {
  final int id;
  final String vehicleNumber;
  final String company;
  final String type;
  final String brand;
  final String model;
  final VehicleStatus status;
  final DriverSummary? assignedDriver;
  final int documentCount;
  final int maintenanceCount;
  final double totalMaintenanceCost;

  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
    this.assignedDriver,
    this.documentCount = 0,
    this.maintenanceCount = 0,
    this.totalMaintenanceCost = 0.0,
  });

  /// Full brand and model display name (e.g. "Toyota Camry")
  String get brandModel => '$brand $model';

  Vehicle copyWith({
    int? id,
    String? vehicleNumber,
    String? company,
    String? type,
    String? brand,
    String? model,
    VehicleStatus? status,
    DriverSummary? assignedDriver,
    int? documentCount,
    int? maintenanceCount,
    double? totalMaintenanceCost,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      documentCount: documentCount ?? this.documentCount,
      maintenanceCount: maintenanceCount ?? this.maintenanceCount,
      totalMaintenanceCost: totalMaintenanceCost ?? this.totalMaintenanceCost,
    );
  }

  Map<String, dynamic> toCreateUpdateJson({int? assignedDriverId}) {
    return {
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type,
      'brand': brand,
      'model': model,
      'status': status.toBackendString(),
      'assignedDriverId': ?assignedDriverId,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type,
      'brand': brand,
      'model': model,
      'status': status.toBackendString(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is num) {
      parsedId = rawId.toInt();
    } else if (rawId is String) {
      final parsed = int.tryParse(rawId);
      if (parsed != null) {
        parsedId = parsed;
      } else {
        throw FormatException('Vehicle ID must be a numeric integer, but got: "$rawId"');
      }
    } else {
      throw FormatException('Invalid or missing vehicle ID: $rawId');
    }

    DriverSummary? driver;
    if (json['assignedDriver'] != null && json['assignedDriver'] is Map<String, dynamic>) {
      driver = DriverSummary.fromJson(json['assignedDriver'] as Map<String, dynamic>);
    }

    return Vehicle(
      id: parsedId,
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      company: json['company'] as String? ?? '',
      type: json['type'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      status: VehicleStatus.fromBackendString(json['status'] as String? ?? ''),
      assignedDriver: driver,
      documentCount: json['documentCount'] as int? ?? 0,
      maintenanceCount: json['maintenanceCount'] as int? ?? 0,
      totalMaintenanceCost: (json['totalMaintenanceCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle.fromJson(map);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          vehicleNumber == other.vehicleNumber;

  @override
  int get hashCode => id.hashCode ^ vehicleNumber.hashCode;
}

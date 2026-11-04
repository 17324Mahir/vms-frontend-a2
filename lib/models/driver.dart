import 'package:flutter/material.dart';

enum DriverStatus {
  available('Available'),
  assigned('Assigned'),
  onLeave('On Leave'),
  inactive('Inactive');

  final String label;
  const DriverStatus(this.label);

  String toBackendString() {
    switch (this) {
      case DriverStatus.available:
        return 'AVAILABLE';
      case DriverStatus.assigned:
        return 'ASSIGNED';
      case DriverStatus.onLeave:
        return 'ON_LEAVE';
      case DriverStatus.inactive:
        return 'INACTIVE';
    }
  }

  static DriverStatus fromBackendString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'AVAILABLE':
        return DriverStatus.available;
      case 'ASSIGNED':
        return DriverStatus.assigned;
      case 'ON_LEAVE':
        return DriverStatus.onLeave;
      case 'INACTIVE':
        return DriverStatus.inactive;
      default:
        return DriverStatus.available;
    }
  }

  Color get textColor {
    switch (this) {
      case DriverStatus.available:
        return const Color(0xFF15803D);
      case DriverStatus.assigned:
        return const Color(0xFF1D4ED8);
      case DriverStatus.onLeave:
        return const Color(0xFFB45309);
      case DriverStatus.inactive:
        return const Color(0xFF475569);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DriverStatus.available:
        return const Color(0xFFDCFCE7);
      case DriverStatus.assigned:
        return const Color(0xFFDBEAFE);
      case DriverStatus.onLeave:
        return const Color(0xFFFEF3C7);
      case DriverStatus.inactive:
        return const Color(0xFFF1F5F9);
    }
  }
}

class Driver {
  final int id;
  final String name;
  final String licenseNumber;
  final String? phone;
  final String? email;
  final DriverStatus status;
  final DateTime? licenseExpiryDate;
  final int? assignedVehicleId;
  final String? assignedVehicleNumber;
  final String expiryStatus; // EXPIRED, EXPIRING_SOON, VALID
  final int? daysUntilExpiry;

  const Driver({
    required this.id,
    required this.name,
    required this.licenseNumber,
    this.phone,
    this.email,
    required this.status,
    this.licenseExpiryDate,
    this.assignedVehicleId,
    this.assignedVehicleNumber,
    this.expiryStatus = 'VALID',
    this.daysUntilExpiry,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as int,
      name: json['name'] as String,
      licenseNumber: json['licenseNumber'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: DriverStatus.fromBackendString(json['status'] as String? ?? 'AVAILABLE'),
      licenseExpiryDate: json['licenseExpiryDate'] != null ? DateTime.parse(json['licenseExpiryDate'] as String) : null,
      assignedVehicleId: json['assignedVehicleId'] as int?,
      assignedVehicleNumber: json['assignedVehicleNumber'] as String?,
      expiryStatus: json['expiryStatus'] as String? ?? 'VALID',
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'licenseNumber': licenseNumber,
    'phone': phone,
    'email': email,
    'status': status.toBackendString(),
    'licenseExpiryDate': ?licenseExpiryDate?.toIso8601String().substring(0, 10),
  };
}

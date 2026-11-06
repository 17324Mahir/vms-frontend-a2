enum MaintenanceType {
  routineService('Routine Service'),
  oilChange('Oil & Filter Change'),
  tireReplacement('Tire Replacement'),
  brakeService('Brake Service'),
  engineRepair('Engine Repair'),
  batterySystem('Battery & Electrical'),
  transmission('Transmission'),
  bodywork('Bodywork & Detailing'),
  inspection('Safety Inspection'),
  other('Other Maintenance');

  final String label;
  const MaintenanceType(this.label);

  String toBackendString() {
    switch (this) {
      case MaintenanceType.routineService:
        return 'ROUTINE_SERVICE';
      case MaintenanceType.oilChange:
        return 'OIL_CHANGE';
      case MaintenanceType.tireReplacement:
        return 'TIRE_REPLACEMENT';
      case MaintenanceType.brakeService:
        return 'BRAKE_SERVICE';
      case MaintenanceType.engineRepair:
        return 'ENGINE_REPAIR';
      case MaintenanceType.batterySystem:
        return 'BATTERY_SYSTEM';
      case MaintenanceType.transmission:
        return 'TRANSMISSION';
      case MaintenanceType.bodywork:
        return 'BODYWORK';
      case MaintenanceType.inspection:
        return 'INSPECTION';
      case MaintenanceType.other:
        return 'OTHER';
    }
  }

  static MaintenanceType fromBackendString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ROUTINE_SERVICE':
        return MaintenanceType.routineService;
      case 'OIL_CHANGE':
        return MaintenanceType.oilChange;
      case 'TIRE_REPLACEMENT':
        return MaintenanceType.tireReplacement;
      case 'BRAKE_SERVICE':
        return MaintenanceType.brakeService;
      case 'ENGINE_REPAIR':
        return MaintenanceType.engineRepair;
      case 'BATTERY_SYSTEM':
        return MaintenanceType.batterySystem;
      case 'TRANSMISSION':
        return MaintenanceType.transmission;
      case 'BODYWORK':
        return MaintenanceType.bodywork;
      case 'INSPECTION':
        return MaintenanceType.inspection;
      default:
        return MaintenanceType.other;
    }
  }
}

class MaintenanceRecord {
  final int id;
  final int vehicleId;
  final String? vehicleNumber;
  final DateTime maintenanceDate;
  final MaintenanceType maintenanceType;
  final double cost;
  final String workshopVendor;
  final int? odometerReading;
  final String? notes;
  final DateTime? createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    this.vehicleNumber,
    required this.maintenanceDate,
    required this.maintenanceType,
    required this.cost,
    required this.workshopVendor,
    this.odometerReading,
    this.notes,
    this.createdAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as int,
      vehicleId: json['vehicleId'] as int,
      vehicleNumber: json['vehicleNumber'] as String?,
      maintenanceDate: DateTime.parse(json['maintenanceDate'] as String),
      maintenanceType: MaintenanceType.fromBackendString(json['maintenanceType'] as String? ?? 'OTHER'),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      workshopVendor: json['workshopVendor'] as String? ?? 'Workshop',
      odometerReading: json['odometerReading'] as int?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson({String? updateVehicleStatus}) => {
    'maintenanceDate': maintenanceDate.toIso8601String().substring(0, 10),
    'maintenanceType': maintenanceType.toBackendString(),
    'cost': cost,
    'workshopVendor': workshopVendor,
    'odometerReading': odometerReading,
    'notes': notes,
    'updateVehicleStatus': ?updateVehicleStatus,
  };
}

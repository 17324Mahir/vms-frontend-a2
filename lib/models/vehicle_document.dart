import 'package:flutter/material.dart';

enum DocumentType {
  registration('Registration'),
  taxToken('Tax Token'),
  insurance('Insurance'),
  fitnessCertificate('Fitness Certificate'),
  other('Other Document');

  final String label;
  const DocumentType(this.label);

  String toBackendString() {
    switch (this) {
      case DocumentType.registration:
        return 'REGISTRATION';
      case DocumentType.taxToken:
        return 'TAX_TOKEN';
      case DocumentType.insurance:
        return 'INSURANCE';
      case DocumentType.fitnessCertificate:
        return 'FITNESS_CERTIFICATE';
      case DocumentType.other:
        return 'OTHER';
    }
  }

  static DocumentType fromBackendString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'REGISTRATION':
        return DocumentType.registration;
      case 'TAX_TOKEN':
        return DocumentType.taxToken;
      case 'INSURANCE':
        return DocumentType.insurance;
      case 'FITNESS_CERTIFICATE':
        return DocumentType.fitnessCertificate;
      default:
        return DocumentType.other;
    }
  }
}

class VehicleDocument {
  final int id;
  final int vehicleId;
  final String? vehicleNumber;
  final DocumentType documentType;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime expiryDate;
  final String? fileName;
  final String? fileType;
  final String? fileData;
  final bool hasFileData;
  final String? notes;
  final String expiryStatus; // EXPIRED, EXPIRING_SOON, VALID
  final int? daysUntilExpiry;
  final DateTime? createdAt;

  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    this.vehicleNumber,
    required this.documentType,
    this.documentNumber,
    this.issueDate,
    required this.expiryDate,
    this.fileName,
    this.fileType,
    this.fileData,
    this.hasFileData = false,
    this.notes,
    this.expiryStatus = 'VALID',
    this.daysUntilExpiry,
    this.createdAt,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'] as int,
      vehicleId: json['vehicleId'] as int,
      vehicleNumber: json['vehicleNumber'] as String?,
      documentType: DocumentType.fromBackendString(json['documentType'] as String? ?? 'OTHER'),
      documentNumber: json['documentNumber'] as String?,
      issueDate: json['issueDate'] != null ? DateTime.parse(json['issueDate'] as String) : null,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      fileData: json['fileData'] as String?,
      hasFileData: json['hasFileData'] as bool? ?? false,
      notes: json['notes'] as String?,
      expiryStatus: json['expiryStatus'] as String? ?? 'VALID',
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'documentType': documentType.toBackendString(),
    'documentNumber': documentNumber,
    'issueDate': ?issueDate?.toIso8601String().substring(0, 10),
    'expiryDate': expiryDate.toIso8601String().substring(0, 10),
    'fileName': fileName,
    'fileType': fileType,
    'fileData': fileData,
    'notes': notes,
  };

  Color get statusBadgeTextColor {
    switch (expiryStatus) {
      case 'EXPIRED':
        return const Color(0xFFDC2626);
      case 'EXPIRING_SOON':
        return const Color(0xFFB45309);
      case 'VALID':
      default:
        return const Color(0xFF15803D);
    }
  }

  Color get statusBadgeBgColor {
    switch (expiryStatus) {
      case 'EXPIRED':
        return const Color(0xFFFEE2E2);
      case 'EXPIRING_SOON':
        return const Color(0xFFFEF3C7);
      case 'VALID':
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  String get expiryStatusLabel {
    if (expiryStatus == 'EXPIRED') {
      final days = (daysUntilExpiry ?? 0).abs();
      return 'Expired ($days d ago)';
    } else if (expiryStatus == 'EXPIRING_SOON') {
      final days = daysUntilExpiry ?? 0;
      return 'Expiring in $days d';
    } else {
      final days = daysUntilExpiry ?? 0;
      return 'Valid ($days d left)';
    }
  }
}

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/file_download_helper.dart';
import '../../data/api/document_api_client.dart';
import '../../data/api/maintenance_api_client.dart';
import '../../data/driver_repository.dart';
import '../../data/vehicle_repository.dart';
import '../../models/maintenance_record.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../router/app_router.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/workspace_section_header.dart';
import '../../widgets/workspace_record_card.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/status_badge.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final int vehicleId;
  final Vehicle? initialVehicle;
  final List<VehicleDocument>? initialDocuments;
  final List<MaintenanceRecord>? initialMaintenance;
  final int initialTab;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
    this.initialDocuments,
    this.initialMaintenance,
    this.initialTab = 0,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen>
    with SingleTickerProviderStateMixin {
  final VehicleRepository _vehicleRepo = VehicleRepository.instance;
  final DocumentApiClient _docClient = DocumentApiClient();
  final MaintenanceApiClient _maintClient = MaintenanceApiClient();
  final DriverRepository _driverRepo = DriverRepository.instance;

  late TabController _tabController;

  Vehicle? _vehicle;
  List<VehicleDocument> _documents = [];
  List<MaintenanceRecord> _maintenance = [];
  bool _assigningDriver = false;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    if (widget.initialVehicle != null) {
      _vehicle = widget.initialVehicle;
      _documents = widget.initialDocuments ?? [];
      _maintenance = widget.initialMaintenance ?? [];
      _isLoading = false;
    } else {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final v = await _vehicleRepo.fetchVehicleById(widget.vehicleId);
      final docs = await _docClient.getDocumentsForVehicle(widget.vehicleId);
      final maint = await _maintClient.getMaintenanceHistory(widget.vehicleId);

      if (mounted) {
        setState(() {
          _vehicle = v;
          _documents = docs;
          _maintenance = maint;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStatusChange(VehicleStatus newStatus) async {
    if (_vehicle == null) return;
    try {
      final updated = await _vehicleRepo.updateStatus(_vehicle!.id, newStatus);
      if (mounted) {
        setState(() => _vehicle = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle status updated to ${newStatus.label}'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _showAssignDriverDialog() async {
    final vehicle = _vehicle;
    if (vehicle == null || _assigningDriver) return;

    final currentDriver = vehicle.assignedDriver;
    final messenger = ScaffoldMessenger.of(context);
    var selectedDriverId = currentDriver?.id;

    setState(() => _assigningDriver = true);
    try {
      final availableDrivers = await _driverRepo.getAvailableDrivers();
      if (!mounted || ModalRoute.isCurrentOf(context) == false) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Assign Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a driver for ${vehicle.vehicleNumber} (${vehicle.brandModel}):',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: AppTheme.space16),
              DropdownButtonFormField<int?>(
                initialValue: currentDriver?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assigned Driver',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('No Driver (Unassigned)'),
                  ),
                  if (currentDriver != null)
                    DropdownMenuItem<int?>(
                      value: currentDriver.id,
                      child: Text(
                        '${currentDriver.name} (${currentDriver.licenseNumber}) - Current',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  for (final driver in availableDrivers)
                    if (driver.id != currentDriver?.id)
                      DropdownMenuItem<int?>(
                        value: driver.id,
                        child: Text(
                          '${driver.name} (${driver.licenseNumber})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: (value) => selectedDriverId = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save Assignment'),
            ),
          ],
        ),
      );

      if (!mounted ||
          confirmed != true ||
          selectedDriverId == currentDriver?.id) {
        return;
      }

      final driverId = selectedDriverId;
      final updated = driverId == null
          ? await _vehicleRepo.unassignDriver(vehicle.id)
          : await _vehicleRepo.assignDriver(vehicle.id, driverId);
      if (!mounted) return;

      setState(() => _vehicle = updated);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Driver assignment updated successfully'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error assigning driver: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _assigningDriver = false);
    }
  }

  Future<void> _showUploadDocumentDialog({
    VehicleDocument? documentToEdit,
  }) async {
    if (_vehicle == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = documentToEdit != null;

    DocumentType docType =
        documentToEdit?.documentType ?? DocumentType.registration;
    final docNumberCtrl = TextEditingController(
      text: documentToEdit?.documentNumber ?? '',
    );
    DateTime? issueDate =
        documentToEdit?.issueDate ??
        DateTime.now().subtract(const Duration(days: 30));
    DateTime expiryDate =
        documentToEdit?.expiryDate ?? DateTime.now().plusYearsSafe(1);
    final notesCtrl = TextEditingController(text: documentToEdit?.notes ?? '');
    String? selectedFileName = documentToEdit?.fileName;
    String? base64Data;
    String? fileType = documentToEdit?.fileType;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Vehicle Document' : 'Upload Vehicle Document',
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<DocumentType>(
                      initialValue: docType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: DocumentType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() => docType = val!),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: docNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Document / Policy Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: issueDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2050),
                              );
                              if (picked != null) {
                                setDialogState(() => issueDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Issue Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                issueDate != null
                                    ? issueDate!.toIso8601String().substring(
                                        0,
                                        10,
                                      )
                                    : 'Select date',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: expiryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2050),
                              );
                              if (picked != null) {
                                setDialogState(() => expiryDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                expiryDate.toIso8601String().substring(0, 10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: Text(
                              selectedFileName ?? 'No document file chosen',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              final file = await FilePicker.pickFile(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'pdf',
                                  'png',
                                  'jpg',
                                  'jpeg',
                                ],
                              );
                              if (file != null) {
                                final bytes = await file.readAsBytes();
                                setDialogState(() {
                                  selectedFileName = file.name;
                                  fileType = file.extension;
                                  base64Data = base64Encode(bytes);
                                });
                              }
                            },
                            child: const Text('Browse...'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final payload = {
                      'documentType': docType.toBackendString(),
                      'documentNumber': docNumberCtrl.text.trim().isNotEmpty
                          ? docNumberCtrl.text.trim()
                          : null,
                      'issueDate': issueDate?.toIso8601String().substring(
                        0,
                        10,
                      ),
                      'expiryDate': expiryDate.toIso8601String().substring(
                        0,
                        10,
                      ),
                      'fileName': selectedFileName,
                      'fileType': fileType,
                      'fileData': base64Data,
                      'notes': notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null,
                    };
                    if (isEditing) {
                      await _docClient.updateDocument(
                        _vehicle!.id,
                        documentToEdit.id,
                        payload,
                      );
                    } else {
                      await _docClient.uploadDocument(_vehicle!.id, payload);
                    }
                    final updatedDocs = await _docClient.getDocumentsForVehicle(
                      _vehicle!.id,
                    );
                    if (mounted) {
                      setState(() => _documents = updatedDocs);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Document updated successfully'
                                : 'Document uploaded successfully',
                          ),
                          backgroundColor: const Color(0xFF15803D),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to ${isEditing ? 'update' : 'upload'} document: $e',
                          ),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Upload Document'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDocumentFilePreview(VehicleDocument doc) async {
    VehicleDocument fullDoc = doc;
    if (fullDoc.fileData == null && fullDoc.hasFileData && _vehicle != null) {
      try {
        fullDoc = await _docClient.getDocument(_vehicle!.id, doc.id);
      } catch (_) {
        // Fallback to existing doc
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: fullDoc.statusBadgeBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.description,
                color: fullDoc.statusBadgeTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullDoc.fileName ??
                        '${fullDoc.documentType.label} Attachment',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${fullDoc.documentType.label} • Expiry: ${fullDoc.expiryDate.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fullDoc.fileData != null &&
                    (fullDoc.fileType == 'png' ||
                        fullDoc.fileType == 'jpg' ||
                        fullDoc.fileType == 'jpeg'))
                  Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.space16),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderNeutral),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      base64Decode(fullDoc.fileData!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Unable to render image preview'),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    margin: const EdgeInsets.only(bottom: AppTheme.space16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderNeutral),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          fullDoc.fileType == 'pdf'
                              ? Icons.picture_as_pdf
                              : Icons.insert_drive_file,
                          size: 48,
                          color: fullDoc.fileType == 'pdf'
                              ? const Color(0xFFDC2626)
                              : AppTheme.primaryBlue,
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          fullDoc.fileName ?? 'Official Document Attachment',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format: ${(fullDoc.fileType ?? 'document').toUpperCase()} • Status: ${fullDoc.expiryStatusLabel}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fullDoc.documentNumber != null &&
                          fullDoc.documentNumber!.isNotEmpty)
                        Text(
                          'Document Number: ${fullDoc.documentNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (fullDoc.issueDate != null)
                        Text(
                          'Issued: ${fullDoc.issueDate!.toIso8601String().substring(0, 10)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      Text(
                        'Expiry: ${fullDoc.expiryDate.toIso8601String().substring(0, 10)} (${fullDoc.expiryStatusLabel})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (fullDoc.notes != null &&
                          fullDoc.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Notes: ${fullDoc.notes}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (fullDoc.fileData != null)
            FilledButton.icon(
              onPressed: () {
                triggerBrowserDownload(
                  fullDoc.fileData!,
                  fullDoc.fileName ??
                      '${fullDoc.documentType.label}.${fullDoc.fileType ?? "pdf"}',
                  fullDoc.fileType,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Downloading ${fullDoc.fileName ?? "document"}...',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download File'),
            ),
        ],
      ),
    );
  }

  Future<void> _showRecordMaintenanceDialog({
    MaintenanceRecord? recordToEdit,
  }) async {
    if (_vehicle == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = recordToEdit != null;

    DateTime maintDate = recordToEdit?.maintenanceDate ?? DateTime.now();
    MaintenanceType maintType =
        recordToEdit?.maintenanceType ?? MaintenanceType.routineService;
    final costCtrl = TextEditingController(
      text: isEditing ? recordToEdit.cost.toStringAsFixed(2) : '0.00',
    );
    final vendorCtrl = TextEditingController(
      text: recordToEdit?.workshopVendor ?? '',
    );
    final odoCtrl = TextEditingController(
      text: recordToEdit?.odometerReading?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: recordToEdit?.notes ?? '');
    VehicleStatus? statusTransition;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEditing
                  ? 'Edit Maintenance Record'
                  : 'Record Vehicle Maintenance',
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: maintDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2050),
                              );
                              if (picked != null) {
                                setDialogState(() => maintDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Service Date *',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                maintDate.toIso8601String().substring(0, 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: DropdownButtonFormField<MaintenanceType>(
                            initialValue: maintType,
                            decoration: const InputDecoration(
                              labelText: 'Service Type *',
                              border: OutlineInputBorder(),
                            ),
                            items: MaintenanceType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => maintType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cost (\$) *',
                              border: OutlineInputBorder(),
                              prefixText: '\$ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: TextFormField(
                            controller: odoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Odometer (km)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: vendorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Workshop / Vendor Name *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Stark Precision Garage',
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Service Notes & Work Done',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppTheme.space12),
                    DropdownButtonFormField<VehicleStatus?>(
                      initialValue: statusTransition,
                      decoration: const InputDecoration(
                        labelText: 'Update Vehicle Status (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Keep current status'),
                        ),
                        ...VehicleStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('Change to ${s.label}'),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setDialogState(() => statusTransition = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (vendorCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workshop/Vendor is required'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }
                  final costVal = double.tryParse(costCtrl.text.trim());
                  if (costVal == null || !costVal.isFinite || costVal < 0) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid, nonnegative cost.'),
                      ),
                    );
                    return;
                  }

                  final odometer = odoCtrl.text.trim();
                  final odoVal = int.tryParse(odometer);
                  if (odometer.isNotEmpty && (odoVal == null || odoVal < 0)) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter a nonnegative whole number for the odometer.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();
                  try {
                    final payload = {
                      'maintenanceDate': maintDate.toIso8601String().substring(
                        0,
                        10,
                      ),
                      'maintenanceType': maintType.toBackendString(),
                      'cost': costVal,
                      'workshopVendor': vendorCtrl.text.trim(),
                      'odometerReading': odoVal,
                      'notes': notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null,
                      if (statusTransition != null)
                        'updateVehicleStatus': statusTransition!
                            .toBackendString(),
                    };
                    if (isEditing) {
                      await _maintClient.updateMaintenance(
                        _vehicle!.id,
                        recordToEdit.id,
                        payload,
                      );
                    } else {
                      await _maintClient.recordMaintenance(
                        _vehicle!.id,
                        payload,
                      );
                    }
                    if (!mounted) return;
                    await _loadAllData();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Maintenance record updated successfully'
                                : 'Maintenance record saved successfully',
                          ),
                          backgroundColor: const Color(0xFF15803D),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to save maintenance: $e'),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Update Record' : 'Save Record'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRouter.vehiclesRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppShell(
        title: 'Vehicle Details',
        showBackButton: true,
        onBack: _goBack,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _vehicle == null) {
      return AppShell(
        title: 'Vehicle Details',
        showBackButton: true,
        onBack: _goBack,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  _errorMessage ?? 'Vehicle not found',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: AppTheme.space16),
                FilledButton(
                  onPressed: _loadAllData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final v = _vehicle!;

    return AppShell(
      title: '${v.vehicleNumber} Details',
      showBackButton: true,
      onBack: _goBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _buildVehicleHeaderCard(v),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlueHover,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryBlue,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(
                  icon: const Icon(Icons.folder_shared_outlined, size: 20),
                  text: 'Documents (${_documents.length})',
                ),
                Tab(
                  icon: const Icon(Icons.build_circle_outlined, size: 20),
                  text: 'Maintenance History (${_maintenance.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDocumentsTab(), _buildMaintenanceTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeaderCard(Vehicle vehicle) {
    final onNavyButton = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.onNavyLabel),
    );
    return WorkspaceSectionHeader(
      label: 'VEHICLE PROFILE',
      title: vehicle.vehicleNumber,
      description:
          '${vehicle.brandModel} · ${vehicle.type} · ${vehicle.company}',
      badge: StatusBadge(status: vehicle.status),
      actions: Wrap(
        spacing: AppTheme.space8,
        runSpacing: AppTheme.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PopupMenuButton<VehicleStatus>(
            tooltip: 'Change Status',
            onSelected: _handleStatusChange,
            itemBuilder: (context) => VehicleStatus.values.map((status) {
              return PopupMenuItem(
                value: status,
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 12, color: status.dotColor),
                    const SizedBox(width: AppTheme.space8),
                    Text(status.label),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.onNavyLabel),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    'Status: ${vehicle.status.label}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            style: onNavyButton,
            onPressed: _assigningDriver ? null : _showAssignDriverDialog,
            icon: const Icon(Icons.person_outline, size: 16),
            label: Text(
              vehicle.assignedDriver != null
                  ? 'Driver: ${vehicle.assignedDriver!.name}'
                  : 'Assign Driver',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton.icon(
            style: onNavyButton,
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(AppRouter.vehicleEditRoute, arguments: vehicle)
                  .then((_) {
                    if (mounted) _loadAllData();
                  });
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Vehicle'),
          ),
          IconButton(
            color: Colors.white,
            onPressed: _loadAllData,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTheme.space16,
            runSpacing: AppTheme.space8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compliance & Registration Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track expiry dates and legal credentials for ${_vehicle!.vehicleNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _showUploadDocumentDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Document'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          if (_documents.isEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_open,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      const Text(
                        'No documents uploaded yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload Registration, Tax Token, Fitness or Insurance documents to track renewal deadlines.',
                        style: TextStyle(color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space16),
                      FilledButton(
                        onPressed: _showUploadDocumentDialog,
                        child: const Text('Upload First Document'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _documents.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTheme.space12),
                itemBuilder: (context, i) {
                  final doc = _documents[i];
                  return WorkspaceRecordCard(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: doc.statusBadgeBgColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.description,
                        color: doc.statusBadgeTextColor,
                        size: 24,
                      ),
                    ),
                    details: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppTheme.space8,
                          runSpacing: AppTheme.space4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              doc.documentType.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: doc.statusBadgeBgColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                              ),
                              child: Text(
                                doc.expiryStatusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: doc.statusBadgeTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expiry: ${doc.expiryDate.toIso8601String().substring(0, 10)}${doc.documentNumber != null ? ' • Document #${doc.documentNumber}' : ''}${doc.fileName != null ? ' • File: ${doc.fileName}' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            doc.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      if (doc.hasFileData || doc.fileName != null)
                        IconButton(
                          tooltip: 'Preview & Download File',
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: AppTheme.primaryBlueHover,
                            size: 20,
                          ),
                          onPressed: () => _showDocumentFilePreview(doc),
                        ),
                      IconButton(
                        tooltip: 'Edit Document',
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        onPressed: () =>
                            _showUploadDocumentDialog(documentToEdit: doc),
                      ),
                      IconButton(
                        tooltip: 'Delete Document',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await ConfirmationDialog.show(
                            context: context,
                            title: 'Delete Document',
                            message:
                                'Are you sure you want to delete this ${doc.documentType.label}?',
                            confirmLabel: 'Delete',
                            isDestructive: true,
                          );
                          if (confirmed == true) {
                            try {
                              await _docClient.deleteDocument(
                                _vehicle!.id,
                                doc.id,
                              );
                              final updated = await _docClient
                                  .getDocumentsForVehicle(_vehicle!.id);
                              if (mounted) {
                                setState(() => _documents = updated);
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    final totalSpent = _maintenance.fold<double>(
      0.0,
      (acc, item) => acc + item.cost,
    );

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppTheme.space16,
            runSpacing: AppTheme.space8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maintenance History & Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lifetime Spend: \$${totalSpent.toStringAsFixed(2)} across ${_maintenance.length} records',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _showRecordMaintenanceDialog,
                icon: const Icon(Icons.build, size: 18),
                label: const Text('Record Maintenance'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          if (_maintenance.isEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.build_circle_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      const Text(
                        'No maintenance records found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep complete records of oil changes, repairs, brake checks, and safety inspections.',
                        style: TextStyle(color: AppTheme.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space16),
                      FilledButton(
                        onPressed: _showRecordMaintenanceDialog,
                        child: const Text('Log First Service'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _maintenance.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTheme.space12),
                itemBuilder: (context, i) {
                  final m = _maintenance[i];
                  return WorkspaceRecordCard(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    details: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppTheme.space8,
                          runSpacing: AppTheme.space4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              m.maintenanceType.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '\$${m.cost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${m.workshopVendor} • ${m.maintenanceDate.toIso8601String().substring(0, 10)}${m.odometerReading != null ? ' • ${m.odometerReading} km' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        if (m.notes != null && m.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            m.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Edit Record',
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        onPressed: () =>
                            _showRecordMaintenanceDialog(recordToEdit: m),
                      ),
                      IconButton(
                        tooltip: 'Delete Record',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirmed = await ConfirmationDialog.show(
                            context: context,
                            title: 'Delete Maintenance Record',
                            message: 'Are you sure you want to delete this maintenance entry?',
                            confirmLabel: 'Delete',
                            isDestructive: true,
                          );
                          if (confirmed == true) {
                            try {
                              await _maintClient.deleteMaintenance(
                                _vehicle!.id,
                                m.id,
                              );
                              await _loadAllData();
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime plusYearsSafe(int years) {
    return DateTime(year + years, month, day);
  }
}

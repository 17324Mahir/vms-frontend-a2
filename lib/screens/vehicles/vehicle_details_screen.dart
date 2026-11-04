import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/api/document_api_client.dart';
import '../../data/api/maintenance_api_client.dart';
import '../../data/driver_repository.dart';
import '../../data/vehicle_repository.dart';
import '../../models/driver.dart';
import '../../models/maintenance_record.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../router/app_router.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/status_badge.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final int vehicleId;
  final Vehicle? initialVehicle;
  final List<VehicleDocument>? initialDocuments;
  final List<MaintenanceRecord>? initialMaintenance;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
    this.initialDocuments,
    this.initialMaintenance,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> with SingleTickerProviderStateMixin {
  final VehicleRepository _vehicleRepo = VehicleRepository.instance;
  final DocumentApiClient _docClient = DocumentApiClient();
  final MaintenanceApiClient _maintClient = MaintenanceApiClient();
  final DriverRepository _driverRepo = DriverRepository.instance;

  late TabController _tabController;

  Vehicle? _vehicle;
  List<VehicleDocument> _documents = [];
  List<MaintenanceRecord> _maintenance = [];
  List<Driver> _availableDrivers = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final drivers = await _driverRepo.getAvailableDrivers();

      if (mounted) {
        setState(() {
          _vehicle = v;
          _documents = docs;
          _maintenance = maint;
          _availableDrivers = drivers;
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
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _showAssignDriverDialog() async {
    if (_vehicle == null) return;
    final messenger = ScaffoldMessenger.of(context);

    int? selectedDriverId = _vehicle!.assignedDriver?.id;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Driver'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a driver for ${_vehicle!.vehicleNumber} (${_vehicle!.brandModel}):',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: AppTheme.space16),
                DropdownButtonFormField<int?>(
                  initialValue: selectedDriverId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Driver',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Driver (Unassigned)', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                    ..._availableDrivers.map((d) {
                      return DropdownMenuItem<int?>(
                        value: d.id,
                        child: Text('${d.name} (${d.licenseNumber}) - ${d.status.label}'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedDriverId = val);
                  },
                ),
              ],
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
                    final Vehicle updated;
                    if (selectedDriverId == null) {
                      updated = await _vehicleRepo.unassignDriver(_vehicle!.id);
                    } else {
                      updated = await _vehicleRepo.assignDriver(_vehicle!.id, selectedDriverId!);
                    }
                    if (mounted) {
                      setState(() => _vehicle = updated);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Driver assignment updated successfully'),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error assigning driver: $e'), backgroundColor: const Color(0xFFDC2626)),
                      );
                    }
                  }
                },
                child: const Text('Save Assignment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showUploadDocumentDialog() async {
    if (_vehicle == null) return;
    final messenger = ScaffoldMessenger.of(context);

    DocumentType docType = DocumentType.registration;
    final docNumberCtrl = TextEditingController();
    DateTime? issueDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime expiryDate = DateTime.now().plusYearsSafe(1);
    final notesCtrl = TextEditingController();
    String? selectedFileName;
    String? base64Data;
    String? fileType;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Upload Vehicle Document'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<DocumentType>(
                      initialValue: docType,
                      decoration: const InputDecoration(labelText: 'Document Type *', border: OutlineInputBorder()),
                      items: DocumentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                      onChanged: (val) => setDialogState(() => docType = val!),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: docNumberCtrl,
                      decoration: const InputDecoration(labelText: 'Document / Policy Number', border: OutlineInputBorder()),
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
                              decoration: const InputDecoration(labelText: 'Issue Date', border: OutlineInputBorder()),
                              child: Text(issueDate != null ? issueDate!.toIso8601String().substring(0, 10) : 'Select date'),
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
                              decoration: const InputDecoration(labelText: 'Expiry Date *', border: OutlineInputBorder()),
                              child: Text(expiryDate.toIso8601String().substring(0, 10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
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
                          const Icon(Icons.attach_file, color: Color(0xFF64748B)),
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
                                allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final payload = {
                      'documentType': docType.toBackendString(),
                      'documentNumber': docNumberCtrl.text.trim().isNotEmpty ? docNumberCtrl.text.trim() : null,
                      'issueDate': issueDate?.toIso8601String().substring(0, 10),
                      'expiryDate': expiryDate.toIso8601String().substring(0, 10),
                      'fileName': selectedFileName,
                      'fileType': fileType,
                      'fileData': base64Data,
                      'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    };
                    await _docClient.uploadDocument(_vehicle!.id, payload);
                    final updatedDocs = await _docClient.getDocumentsForVehicle(_vehicle!.id);
                    if (mounted) {
                      setState(() => _documents = updatedDocs);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Document uploaded successfully'), backgroundColor: Color(0xFF15803D)),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to upload document: $e'), backgroundColor: const Color(0xFFDC2626)),
                      );
                    }
                  }
                },
                child: const Text('Upload Document'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRecordMaintenanceDialog() async {
    if (_vehicle == null) return;
    final messenger = ScaffoldMessenger.of(context);

    DateTime maintDate = DateTime.now();
    MaintenanceType maintType = MaintenanceType.routineService;
    final costCtrl = TextEditingController(text: '0.00');
    final vendorCtrl = TextEditingController();
    final odoCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    VehicleStatus? statusTransition;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Record Vehicle Maintenance'),
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
                              decoration: const InputDecoration(labelText: 'Service Date *', border: OutlineInputBorder()),
                              child: Text(maintDate.toIso8601String().substring(0, 10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: DropdownButtonFormField<MaintenanceType>(
                            initialValue: maintType,
                            decoration: const InputDecoration(labelText: 'Service Type *', border: OutlineInputBorder()),
                            items: MaintenanceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                            onChanged: (val) => setDialogState(() => maintType = val!),
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        const DropdownMenuItem(value: null, child: Text('Keep current status')),
                        ...VehicleStatus.values.map((s) => DropdownMenuItem(value: s, child: Text('Change to ${s.label}'))),
                      ],
                      onChanged: (val) => setDialogState(() => statusTransition = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (vendorCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workshop/Vendor is required'), backgroundColor: Color(0xFFDC2626)),
                    );
                    return;
                  }
                  final costVal = double.tryParse(costCtrl.text.trim()) ?? 0.0;
                  final odoVal = int.tryParse(odoCtrl.text.trim());

                  Navigator.of(ctx).pop();
                  try {
                    final payload = {
                      'maintenanceDate': maintDate.toIso8601String().substring(0, 10),
                      'maintenanceType': maintType.toBackendString(),
                      'cost': costVal,
                      'workshopVendor': vendorCtrl.text.trim(),
                      'odometerReading': odoVal,
                      'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                      if (statusTransition != null) 'updateVehicleStatus': statusTransition!.toBackendString(),
                    };
                    await _maintClient.recordMaintenance(_vehicle!.id, payload);
                    await _loadAllData();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Maintenance record saved successfully'), backgroundColor: Color(0xFF15803D)),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to record maintenance: $e'), backgroundColor: const Color(0xFFDC2626)),
                      );
                    }
                  }
                },
                child: const Text('Save Record'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppShell(
        title: 'Vehicle Details',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _vehicle == null) {
      return AppShell(
        title: 'Vehicle Details',
        showBackButton: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: AppTheme.space16),
                Text(_errorMessage ?? 'Vehicle not found', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: AppTheme.space16),
                FilledButton(onPressed: _loadAllData, child: const Text('Retry')),
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
      onBack: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.vehiclesRoute, (_) => false),
      primaryAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.vehicleEditRoute, arguments: v).then((_) => _loadAllData());
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Vehicle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          FilledButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.navy800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVehicleHeaderCard(v),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.navy900,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: AppTheme.navy900,
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
              children: [
                _buildDocumentsTab(),
                _buildMaintenanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeaderCard(Vehicle v) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Wrap(
        spacing: AppTheme.space24,
        runSpacing: AppTheme.space16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.navy900,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppTheme.space16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        v.vehicleNumber,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      StatusBadge(status: v.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${v.brandModel} • ${v.type} • ${v.company}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Operational Status Quick Action
              PopupMenuButton<VehicleStatus>(
                tooltip: 'Change Status',
                onSelected: _handleStatusChange,
                itemBuilder: (context) => VehicleStatus.values.map((s) {
                  return PopupMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: s.dotColor),
                        const SizedBox(width: 8),
                        Text(s.label),
                      ],
                    ),
                  );
                }).toList(),
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text('Status: ${v.status.label}'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textDark),
                ),
              ),
              // Driver Assignment Button
              OutlinedButton.icon(
                onPressed: _showAssignDriverDialog,
                icon: const Icon(Icons.person, size: 16),
                label: Text(
                  v.assignedDriver != null ? 'Driver: ${v.assignedDriver!.name}' : 'Assign Driver',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: v.assignedDriver != null ? const Color(0xFF1D4ED8) : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compliance & Registration Documents',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track expiry dates and legal credentials for ${_vehicle!.vehicleNumber}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              FilledButton.icon(
                onPressed: _showUploadDocumentDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Document'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.navy900),
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
                      const Icon(Icons.folder_open, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: AppTheme.space12),
                      const Text('No documents uploaded yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Upload Registration, Tax Token, Fitness or Insurance documents to track renewal deadlines.', style: TextStyle(color: Color(0xFF64748B)), textAlign: TextAlign.center),
                      const SizedBox(height: AppTheme.space16),
                      FilledButton(onPressed: _showUploadDocumentDialog, child: const Text('Upload First Document')),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _documents.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space12),
                itemBuilder: (context, i) {
                  final doc = _documents[i];
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: doc.statusBadgeBgColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Icon(Icons.description, color: doc.statusBadgeTextColor, size: 24),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    doc.documentType.label,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                  const SizedBox(width: AppTheme.space8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: doc.statusBadgeBgColor,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      doc.expiryStatusLabel,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: doc.statusBadgeTextColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expiry: ${doc.expiryDate.toIso8601String().substring(0, 10)}${doc.documentNumber != null ? ' • Document #${doc.documentNumber}' : ''}${doc.fileName != null ? ' • File: ${doc.fileName}' : ''}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(doc.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete Document',
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final confirmed = await ConfirmationDialog.show(
                              context: context,
                              title: 'Delete Document',
                              message: 'Are you sure you want to delete this ${doc.documentType.label}?',
                              confirmLabel: 'Delete',
                              isDestructive: true,
                            );
                            if (confirmed == true) {
                              try {
                                await _docClient.deleteDocument(_vehicle!.id, doc.id);
                                final updated = await _docClient.getDocumentsForVehicle(_vehicle!.id);
                                if (mounted) {
                                  setState(() => _documents = updated);
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: const Color(0xFFDC2626)),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    final totalSpent = _maintenance.fold<double>(0.0, (acc, item) => acc + item.cost);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maintenance History & Services',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lifetime Spend: \$${totalSpent.toStringAsFixed(2)} across ${_maintenance.length} records',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              FilledButton.icon(
                onPressed: _showRecordMaintenanceDialog,
                icon: const Icon(Icons.build, size: 18),
                label: const Text('Record Maintenance'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.navy900),
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
                      const Icon(Icons.build_circle_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: AppTheme.space12),
                      const Text('No maintenance records found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Keep complete records of oil changes, repairs, brake checks, and safety inspections.', style: TextStyle(color: Color(0xFF64748B)), textAlign: TextAlign.center),
                      const SizedBox(height: AppTheme.space16),
                      FilledButton(onPressed: _showRecordMaintenanceDialog, child: const Text('Log First Service')),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _maintenance.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space12),
                itemBuilder: (context, i) {
                  final m = _maintenance[i];
                  return Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Icon(Icons.build_rounded, color: Color(0xFFD97706), size: 24),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.maintenanceType.label,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${m.cost.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${m.workshopVendor} • ${m.maintenanceDate.toIso8601String().substring(0, 10)}${m.odometerReading != null ? ' • ${m.odometerReading} km' : ''}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              if (m.notes != null && m.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(m.notes!, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        IconButton(
                          tooltip: 'Delete Record',
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
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
                                await _maintClient.deleteMaintenance(_vehicle!.id, m.id);
                                await _loadAllData();
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: const Color(0xFFDC2626)),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
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

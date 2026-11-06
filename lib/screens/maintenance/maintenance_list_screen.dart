import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/api/maintenance_api_client.dart';
import '../../data/vehicle_repository.dart';
import '../../models/maintenance_record.dart';
import '../../models/vehicle.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/animated_counter.dart';
import '../../widgets/animated/spotlight_hover_card.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/workspace_section_header.dart';
import '../../widgets/workspace_record_card.dart';
import '../../widgets/confirmation_dialog.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  final MaintenanceApiClient _apiClient = MaintenanceApiClient();
  final VehicleRepository _vehicleRepo = VehicleRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  List<MaintenanceRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  MaintenanceType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiClient.getAllMaintenance();
      await _vehicleRepo.fetchVehicles(silent: true);
      if (mounted) {
        setState(() {
          _records = list;
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

  List<MaintenanceRecord> get _filteredRecords {
    return _records.where((m) {
      if (_typeFilter != null && m.maintenanceType != _typeFilter) {
        return false;
      }
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final vNum = m.vehicleNumber?.toLowerCase() ?? '';
        final vendor = m.workshopVendor.toLowerCase();
        final notes = m.notes?.toLowerCase() ?? '';
        final typeLabel = m.maintenanceType.label.toLowerCase();
        return vNum.contains(q) ||
            vendor.contains(q) ||
            notes.contains(q) ||
            typeLabel.contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _showRecordMaintenanceDialog({
    MaintenanceRecord? recordToEdit,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = recordToEdit != null;

    final vehicles = _vehicleRepo.allVehicles;
    if (vehicles.isEmpty && !isEditing) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No vehicles available in fleet'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    int selectedVehicleId = recordToEdit?.vehicleId ?? vehicles.first.id;
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
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Text(
              isEditing
                  ? 'Edit Maintenance Record'
                  : 'Record Vehicle Maintenance',
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isEditing) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedVehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Target Vehicle *',
                          border: OutlineInputBorder(),
                        ),
                        items: vehicles.map((v) {
                          return DropdownMenuItem<int>(
                            value: v.id,
                            child: Text('${v.vehicleNumber} (${v.brandModel})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedVehicleId = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppTheme.space12),
                    ],
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
                              if (picked != null && dialogCtx.mounted) {
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
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Workshop/Vendor is required'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }
                  final costVal = double.tryParse(costCtrl.text.trim()) ?? 0.0;
                  final odoVal = int.tryParse(odoCtrl.text.trim());

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
                      await _apiClient.updateMaintenance(
                        recordToEdit.vehicleId,
                        recordToEdit.id,
                        payload,
                      );
                    } else {
                      await _apiClient.recordMaintenance(
                        selectedVehicleId,
                        payload,
                      );
                    }
                    await _loadData();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Maintenance record updated successfully'
                                : 'Maintenance record logged successfully',
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
                child: Text(isEditing ? 'Save Changes' : 'Log Maintenance'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteMaintenance(MaintenanceRecord m) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Maintenance Record',
      message:
          'Are you sure you want to delete this ${m.maintenanceType.label} entry (\$${m.cost.toStringAsFixed(2)})?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _apiClient.deleteMaintenance(m.vehicleId, m.id);
        await _loadData();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Maintenance record deleted successfully'),
              backgroundColor: Color(0xFF15803D),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Failed to delete maintenance: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return AppShell(
      title: 'Fleet Maintenance',
      primaryAction: FilledButton.icon(
        onPressed: () => _showRecordMaintenanceDialog(),
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text('Record Maintenance'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      child: _buildBody(isDesktop),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'Failed to load maintenance records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space20),
              FilledButton(
                onPressed: _loadData,
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    final totalSpent = _records.fold<double>(
      0.0,
      (acc, item) => acc + item.cost,
    );
    final avgCost = _records.isNotEmpty ? totalSpent / _records.length : 0.0;
    final filtered = _filteredRecords;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? AppTheme.space24 : AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroHeader(totalSpent),
          const SizedBox(height: AppTheme.space20),
          _buildKpiMetrics(totalSpent, _records.length, avgCost),
          const SizedBox(height: AppTheme.space20),
          _buildFiltersCard(),
          const SizedBox(height: AppTheme.space20),
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, i) => _buildMaintenanceRow(filtered[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(double totalSpent) {
    return WorkspaceSectionHeader(
      label: 'SERVICE OPERATIONS',
      title: 'Fleet Maintenance Hub',
      description: 'Record scheduled service and repairs, track workshop costs and review maintenance history.',
      actions: Text(
        'Lifetime spend: \$${totalSpent.toStringAsFixed(2)}',
        style: const TextStyle(
          color: AppTheme.onNavyMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildKpiMetrics(double totalSpent, int totalCount, double avgCost) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTheme.space16,
          mainAxisSpacing: AppTheme.space16,
          childAspectRatio: constraints.maxWidth > 800 ? 2.4 : 3.2,
          children: [
            SpotlightHoverCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              borderRadius: AppTheme.radiusMd,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: Color(0xFF16A34A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Total Maintenance Spend',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        AnimatedCounter(
                          value: totalSpent,
                          prefix: '\$',
                          decimalDigits: 2,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SpotlightHoverCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              borderRadius: AppTheme.radiusMd,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: const Icon(
                      Icons.build_circle_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Total Service Logs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        AnimatedCounter(
                          value: totalCount,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SpotlightHoverCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              borderRadius: AppTheme.radiusMd,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Icon(
                      Icons.query_stats_rounded,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Average Cost Per Service',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        AnimatedCounter(
                          value: avgCost,
                          prefix: '\$',
                          decimalDigits: 2,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFiltersCard() {
    final search = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search service records…',
        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(_searchController.clear),
              ),
      ),
      onChanged: (_) => setState(() {}),
    );
    final type = DropdownButtonFormField<MaintenanceType?>(
      key: ValueKey(_typeFilter),
      initialValue: _typeFilter,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Service Type'),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Service Types')),
        for (final type in MaintenanceType.values)
          DropdownMenuItem(value: type, child: Text(type.label)),
      ],
      onChanged: (value) => setState(() => _typeFilter = value),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (constraints.maxWidth >= 590)
                Row(
                  children: [
                    Expanded(flex: 3, child: search),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(flex: 2, child: type),
                  ],
                )
              else ...[
                search,
                const SizedBox(height: AppTheme.space12),
                type,
              ],
              if (_searchController.text.isNotEmpty || _typeFilter != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _typeFilter = null);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reset'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceRow(MaintenanceRecord m) {
    return WorkspaceRecordCard(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: const Icon(
          Icons.build_rounded,
          color: Color(0xFF92400E),
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
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(
                        AppRouter.vehicleDetailsPath(
                          m.vehicleId,
                          initialTab: 1,
                        ),
                      )
                      .then((_) => _loadData());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    m.vehicleNumber ?? 'Vehicle #${m.vehicleId}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ),
              Text(
                m.maintenanceType.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '\$${m.cost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF116749),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${m.workshopVendor} • ${m.maintenanceDate.toIso8601String().substring(0, 10)}${m.odometerReading != null ? ' • ${m.odometerReading} km' : ''}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          if (m.notes != null && m.notes!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              m.notes!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
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
          onPressed: () => _showRecordMaintenanceDialog(recordToEdit: m),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context)
                .pushNamed(
                  AppRouter.vehicleDetailsPath(m.vehicleId, initialTab: 1),
                )
                .then((_) => _loadData());
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
          label: const Text('View Vehicle', style: TextStyle(fontSize: 12)),
        ),
        IconButton(
          tooltip: 'Delete Record',
          icon: const Icon(
            Icons.delete_outline,
            color: AppTheme.errorRed,
            size: 20,
          ),
          onPressed: () => _handleDeleteMaintenance(m),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: AppTheme.space12),
            const Text(
              'No maintenance records found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Record your first service log or adjust search filters above.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: AppTheme.space16),
            FilledButton.icon(
              onPressed: () => _showRecordMaintenanceDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Record First Service'),
            ),
          ],
        ),
      ),
    );
  }
}

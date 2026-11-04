import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/mock_data.dart';
import '../../data/vehicle_repository.dart';
import '../../models/vehicle.dart';
import '../../router/app_router.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/status_badge.dart';

/// Primary Fleet Management screen displaying all registered vehicles with
/// local search, multi-attribute filtering, sorting, pagination, and deletion.
class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();

  VehicleStatus? _statusFilter;
  String? _companyFilter = 'All Companies';

  VehicleSortField _sortField = VehicleSortField.vehicleNumber;
  bool _sortAscending = true;

  int _currentPage = 1;
  static const int _pageSize = 10;

  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    // Fetch live vehicles from the backend API on initial mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles({bool silent = false}) async {
    try {
      await VehicleRepository.instance.fetchVehicles(silent: silent);
    } catch (_) {
      // Error is captured in VehicleRepository.errorMessage
    }
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _statusFilter != null ||
      (_companyFilter != null && _companyFilter != 'All Companies');

  bool _matchesActiveFilters(Vehicle v) {
    if (_statusFilter != null && v.status != _statusFilter) return false;
    if (_companyFilter != null &&
        _companyFilter != 'All Companies' &&
        v.company != _companyFilter) {
      return false;
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      return v.vehicleNumber.toLowerCase().contains(q) ||
          v.company.toLowerCase().contains(q) ||
          v.brand.toLowerCase().contains(q) ||
          v.model.toLowerCase().contains(q);
    }
    return true;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _statusFilter = null;
      _companyFilter = 'All Companies';
      _currentPage = 1;
    });
  }

  void _toggleSort(VehicleSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
      _currentPage = 1;
    });
  }

  Future<void> _handleDelete(Vehicle vehicle) async {
    if (_deletingIds.contains(vehicle.id)) return;

    final confirmed = await ConfirmationDialog.showDelete(
      context,
      vehicleNumber: vehicle.vehicleNumber,
      company: vehicle.company,
    );

    if (confirmed && mounted) {
      setState(() => _deletingIds.add(vehicle.id));
      try {
        await VehicleRepository.instance.delete(vehicle.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Vehicle ${vehicle.vehicleNumber} was removed from the fleet.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        if (e.isNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Vehicle ${vehicle.vehicleNumber} was already removed or is unavailable.'),
              backgroundColor: AppTheme.statusMaintenanceText,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } on NetworkException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete vehicle: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _deletingIds.remove(vehicle.id));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = VehicleRepository.instance;
    final isDesktop = Responsive.isDesktop(context);

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final queryResults = repo.query(
          searchQuery: _searchController.text,
          statusFilter: _statusFilter,
          companyFilter: _companyFilter,
          sortField: _sortField,
          sortAscending: _sortAscending,
        );

        final totalMatches = queryResults.length;
        final totalPages = max(1, (totalMatches / _pageSize).ceil());

        // Auto-adjust page if current page exceeds total pages
        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }

        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = min(startIndex + _pageSize, totalMatches);
        final paginatedVehicles = totalMatches > 0
            ? queryResults.sublist(startIndex, endIndex)
            : <Vehicle>[];

        return AppShell(
          title: 'Vehicles',
          primaryAction: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .pushNamed(AppRouter.vehicleNewRoute);
              if (result is Vehicle && mounted) {
                if (!_matchesActiveFilters(result)) {
                  _clearFilters();
                }
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(isDesktop ? 'Register vehicle' : 'Register'),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(repo.totalCount, repo.isLoading),
                if (repo.hasError && repo.totalCount > 0) ...[
                  const SizedBox(height: AppTheme.space12),
                  _buildRefreshErrorBanner(repo.errorMessage!),
                ],
                const SizedBox(height: AppTheme.space20),
                _buildToolbar(repo.allVehicles),
                const SizedBox(height: AppTheme.space16),
                if (repo.isLoading && repo.totalCount == 0)
                  _buildLoadingState()
                else if (repo.hasError && repo.totalCount == 0)
                  _buildErrorState(repo.errorMessage!)
                else if (repo.totalCount == 0)
                  _buildNoVehiclesRegistered()
                else if (totalMatches == 0)
                  _buildNoMatchingResults()
                else ...[
                  if (MediaQuery.sizeOf(context).width >= 850)
                    _buildDesktopTable(paginatedVehicles)
                  else
                    _buildMobileCards(paginatedVehicles),
                  const SizedBox(height: AppTheme.space16),
                  _buildPaginationControls(
                    startIndex: startIndex + 1,
                    endIndex: endIndex,
                    totalMatches: totalMatches,
                    totalPages: totalPages,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int totalCount, bool isLoading) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppTheme.space16,
      runSpacing: AppTheme.space12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Registry',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Manage and monitor registered fleet vehicles.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.borderNeutral),
              ),
              child: Text(
                'Total: $totalCount vehicles',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              tooltip: 'Refresh',
              onPressed: isLoading ? null : () => _loadVehicles(silent: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefreshErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.errorRedBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.errorRedBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: AppTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not refresh fleet data: $message',
              style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
            ),
          ),
          TextButton(
            onPressed: () => _loadVehicles(silent: true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(List<Vehicle> allVehicles) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildSearchInput(),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    flex: 2,
                    child: _buildCompanyDropdown(allVehicles),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    flex: 2,
                    child: _buildStatusDropdown(),
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(width: AppTheme.space12),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Clear filters'),
                    ),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchInput(),
                  const SizedBox(height: AppTheme.space12),
                  Row(
                    children: [
                      Expanded(child: _buildCompanyDropdown(allVehicles)),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(child: _buildStatusDropdown()),
                    ],
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: AppTheme.space8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Clear filters'),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by vehicle number, company, brand, or model...',
        prefixIcon:
            const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                tooltip: 'Clear search query',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _currentPage = 1);
                },
              )
            : null,
      ),
      onChanged: (_) => setState(() => _currentPage = 1),
    );
  }

  Widget _buildCompanyDropdown(List<Vehicle> allVehicles) {
    final companies = {
      'All Companies',
      ...kDefaultCompanies,
      for (final v in allVehicles) v.company,
    }.toList();

    final currentValue = companies.contains(_companyFilter)
        ? _companyFilter
        : 'All Companies';

    return DropdownButtonFormField<String>(
      key: ValueKey(currentValue),
      initialValue: currentValue,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: companies.map(
        (c) => DropdownMenuItem(
          value: c,
          child: Text(c, style: const TextStyle(fontSize: 13)),
        ),
      ).toList(),
      onChanged: (val) {
        setState(() {
          _companyFilter = val;
          _currentPage = 1;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<VehicleStatus?>(
      key: ValueKey(_statusFilter),
      initialValue: _statusFilter,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('All Statuses', style: TextStyle(fontSize: 13)),
        ),
        ...VehicleStatus.values.map(
          (s) => DropdownMenuItem(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: s.dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(s.label, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
      onChanged: (val) {
        setState(() {
          _statusFilter = val;
          _currentPage = 1;
        });
      },
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.space16),
            Text(
              'Loading fleet registry...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: AppTheme.space4),
            Text(
              'Please wait a moment.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMsg) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppTheme.errorRed),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'Unable to load fleet data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              errorMsg,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space20),
            ElevatedButton.icon(
              onPressed: () => _loadVehicles(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<Vehicle> vehicles) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 950),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(130), // Vehicle Number
              1: FlexColumnWidth(1.8), // Company
              2: FixedColumnWidth(85), // Type
              3: FlexColumnWidth(1.2), // Brand
              4: FlexColumnWidth(1.4), // Model
              5: FlexColumnWidth(1.4), // Driver
              6: FixedColumnWidth(130), // Status
              7: FixedColumnWidth(140), // Actions
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildTableHeaderRow(),
              ...vehicles.map((v) => _buildTableRow(v)),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(
        color: AppTheme.canvasLight,
        border:
            Border(bottom: BorderSide(color: AppTheme.borderNeutral, width: 1)),
      ),
      children: [
        _buildSortableHeaderCell(
            'VEHICLE NUMBER', VehicleSortField.vehicleNumber),
        _buildSortableHeaderCell('COMPANY', VehicleSortField.company),
        _buildStaticHeaderCell('TYPE'),
        _buildStaticHeaderCell('BRAND'),
        _buildStaticHeaderCell('MODEL'),
        _buildStaticHeaderCell('DRIVER'),
        _buildStaticHeaderCell('STATUS'),
        _buildStaticHeaderCell('ACTIONS', alignRight: true),
      ],
    );
  }

  Widget _buildSortableHeaderCell(String label, VehicleSortField field) {
    final isSorted = _sortField == field;

    return InkWell(
      onTap: () => _toggleSort(field),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSorted ? AppTheme.primaryBlue : AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSorted
                  ? (_sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 14,
              color: isSorted ? AppTheme.primaryBlue : AppTheme.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticHeaderCell(String label, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _buildTableRow(Vehicle vehicle) {
    return TableRow(
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 1)),
      ),
      children: [
        // Vehicle Number
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.borderNeutral),
              ),
              child: Text(
                vehicle.vehicleNumber,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),
        ),
        // Company
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            vehicle.company,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        // Type
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            vehicle.type,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ),
        // Brand
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            vehicle.brand,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
        ),
        // Model
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            vehicle.model,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
        ),
        // Driver
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.vehicleDetailsRoute, arguments: vehicle.id);
            },
            child: Text(
              vehicle.assignedDriver?.name ?? 'Unassigned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: vehicle.assignedDriver != null ? FontWeight.w600 : FontWeight.normal,
                color: vehicle.assignedDriver != null ? const Color(0xFF1D4ED8) : AppTheme.textMuted,
              ),
            ),
          ),
        ),
        // Status Badge (Interactive quick-change menu)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<VehicleStatus>(
              tooltip: 'Change Status',
              onSelected: (newStatus) async {
                try {
                  await VehicleRepository.instance.updateStatus(vehicle.id, newStatus);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppTheme.errorRed),
                    );
                  }
                }
              },
              itemBuilder: (context) => VehicleStatus.values.map((s) {
                return PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: s.dotColor),
                      const SizedBox(width: 8),
                      Text(s.label),
                    ],
                  ),
                );
              }).toList(),
              child: StatusBadge(status: vehicle.status),
            ),
          ),
        ),
        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                tooltip: 'View details & documents for ${vehicle.vehicleNumber}',
                color: AppTheme.primaryBlue,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.vehicleDetailsRoute,
                    arguments: vehicle.id,
                  ).then((_) => _loadVehicles(silent: true));
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit vehicle ${vehicle.vehicleNumber}',
                color: AppTheme.textMuted,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                splashRadius: 18,
                onPressed: _deletingIds.contains(vehicle.id)
                    ? null
                    : () async {
                        final result = await Navigator.of(context).pushNamed(
                          AppRouter.vehicleEditRoute,
                          arguments: vehicle,
                        );
                        if (result is Vehicle && mounted) {
                          if (!_matchesActiveFilters(result)) {
                            _clearFilters();
                          }
                        }
                      },
              ),
              _deletingIds.contains(vehicle.id)
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete vehicle ${vehicle.vehicleNumber}',
                      color: AppTheme.errorRed,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      splashRadius: 18,
                      onPressed: () => _handleDelete(vehicle),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCards(List<Vehicle> vehicles) {
    return Column(
      children: vehicles.map((vehicle) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.space12),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.borderSubtle,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.borderNeutral),
                      ),
                      child: Text(
                        vehicle.vehicleNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    PopupMenuButton<VehicleStatus>(
                      tooltip: 'Change Status',
                      onSelected: (newStatus) async {
                        try {
                          await VehicleRepository.instance.updateStatus(vehicle.id, newStatus);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorRed),
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => VehicleStatus.values.map((s) {
                        return PopupMenuItem(value: s, child: Text(s.label));
                      }).toList(),
                      child: StatusBadge(status: vehicle.status, compact: true),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  vehicle.brandModel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.company} · ${vehicle.type} · Driver: ${vehicle.assignedDriver?.name ?? "Unassigned"}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: AppTheme.space12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.vehicleDetailsRoute,
                          arguments: vehicle.id,
                        ).then((_) => _loadVehicles(silent: true));
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Details'),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    TextButton.icon(
                      onPressed: _deletingIds.contains(vehicle.id)
                          ? null
                          : () async {
                              final result = await Navigator.of(context).pushNamed(
                                AppRouter.vehicleEditRoute,
                                arguments: vehicle,
                              );
                              if (result is Vehicle && mounted) {
                                if (!_matchesActiveFilters(result)) {
                                  _clearFilters();
                                }
                              }
                            },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    _deletingIds.contains(vehicle.id)
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : TextButton.icon(
                            onPressed: () => _handleDelete(vehicle),
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: AppTheme.errorRed),
                            label: const Text('Delete',
                                style: TextStyle(color: AppTheme.errorRed)),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaginationControls({
    required int startIndex,
    required int endIndex,
    required int totalMatches,
    required int totalPages,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $startIndex–$endIndex of $totalMatches vehicles',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Previous'),
                ),
                const SizedBox(width: AppTheme.space8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.borderNeutral),
                  ),
                  child: Text(
                    'Page $_currentPage of $totalPages',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                OutlinedButton(
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoVehiclesRegistered() {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.directions_car_outlined,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'No vehicles registered',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            const Text(
              'The fleet registry is currently empty. Add your first vehicle to get started.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context)
                    .pushNamed(AppRouter.vehicleNewRoute);
                if (result is Vehicle && mounted) {
                  if (!_matchesActiveFilters(result)) {
                    _clearFilters();
                  }
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Register vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchingResults() {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'No matching vehicles found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            const Text(
              'Try adjusting your search query, company filter, or status filter.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space20),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Clear all filters'),
            ),
          ],
        ),
      ),
    );
  }
}

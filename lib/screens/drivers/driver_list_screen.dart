import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/driver_repository.dart';
import '../../models/driver.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/spotlight_hover_card.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/confirmation_dialog.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  final DriverRepository _driverRepo = DriverRepository.instance;

  final TextEditingController _searchCtrl = TextEditingController();
  DriverStatus? _selectedStatus;

  int _currentPage = 0;
  final int _pageSize = 10;
  int _totalPages = 1;
  int _totalElements = 0;

  List<Driver> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pageRes = await _driverRepo.searchDrivers(
        page: _currentPage,
        size: _pageSize,
        search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _drivers = pageRes.content;
          _totalPages = pageRes.totalPages > 0 ? pageRes.totalPages : 1;
          _totalElements = pageRes.totalElements;
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

  void _handleSearch(String _) {
    _currentPage = 0;
    _loadDrivers();
  }

  void _handleStatusFilter(DriverStatus? status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 0;
    });
    _loadDrivers();
  }

  Future<void> _handleDeleteDriver(Driver driver) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Driver',
      message: 'Are you sure you want to remove driver ${driver.name} (${driver.licenseNumber})?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _driverRepo.deleteDriver(driver.id);
        _loadDrivers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Driver ${driver.name} removed successfully'),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete driver: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Drivers',
      primaryAction: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRouter.driverNewRoute).then((_) => _loadDrivers());
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Driver'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFiltersCard(),
            const SizedBox(height: AppTheme.space16),
            Expanded(child: _buildDriverList()),
            const SizedBox(height: AppTheme.space12),
            _buildPaginationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Wrap(
        spacing: AppTheme.space16,
        runSpacing: AppTheme.space12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Search by driver name, license, email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<DriverStatus?>(
              initialValue: _selectedStatus,
              isExpanded: true,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ...DriverStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                ),
              ],
              onChanged: _handleStatusFilter,
            ),
          ),
          FilledButton.icon(
            onPressed: () => _handleSearch(''),
            icon: const Icon(Icons.filter_list, size: 16),
            label: const Text('Apply'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.navy800),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadDrivers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: AppTheme.space12),
            const Text(
              'No drivers found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search criteria or register a new fleet driver.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: AppTheme.space16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.driverNewRoute).then((_) => _loadDrivers());
              },
              child: const Text('Add Driver'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _drivers.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.space8),
      itemBuilder: (context, i) {
        final d = _drivers[i];
        return SpotlightHoverCard(
          padding: const EdgeInsets.all(AppTheme.space16),
          borderRadius: AppTheme.radiusMd,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: d.status.backgroundColor,
                child: Text(
                  d.name.isNotEmpty ? d.name[0].toUpperCase() : 'D',
                  style: TextStyle(color: d.status.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: d.status.backgroundColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            d.status.label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: d.status.textColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'License: ${d.licenseNumber} • ${d.phone ?? 'No phone'}${d.email != null ? ' • ${d.email}' : ''}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (d.assignedVehicleNumber != null) ...[
                          const Icon(Icons.directions_car, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned: ${d.assignedVehicleNumber}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: AppTheme.space12),
                        ],
                        if (d.licenseExpiryDate != null)
                          Text(
                            'Expiry: ${d.licenseExpiryDate!.toIso8601String().substring(0, 10)} (${d.expiryStatus})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: d.expiryStatus == 'EXPIRED'
                                  ? const Color(0xFFDC2626)
                                  : (d.expiryStatus == 'EXPIRING_SOON' ? const Color(0xFFB45309) : const Color(0xFF15803D)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit Driver',
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.navy800),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.driverEditRoute, arguments: d).then((_) => _loadDrivers());
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete Driver',
                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                    onPressed: () => _handleDeleteDriver(d),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_drivers.length} of $_totalElements drivers',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        _loadDrivers();
                      }
                    : null,
              ),
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        setState(() => _currentPage++);
                        _loadDrivers();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

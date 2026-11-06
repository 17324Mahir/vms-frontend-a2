import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api/dashboard_api_client.dart';
import '../../models/dashboard_stats.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/ambient_grid_pattern.dart';
import '../../widgets/animated/animated_counter.dart';
import '../../widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  final DashboardApiClient? apiClient;

  const DashboardScreen({super.key, this.apiClient});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final _apiClient = widget.apiClient ?? DashboardApiClient();
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    if (widget.apiClient == null) _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _apiClient.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fleet Dashboard',
      primaryAction: FilledButton.icon(
        onPressed: _isLoading ? null : _loadStats,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Refresh dashboard'),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Loading fleet dashboard…',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.errorRedBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.errorRedBorder),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'Failed to load dashboard metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              FilledButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        return SingleChildScrollView(
          padding: EdgeInsets.all(wide ? AppTheme.space32 : AppTheme.space16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroHeader(stats, wide),
                  const SizedBox(height: AppTheme.space32),
                  const Text(
                    'Fleet at a glance',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  _buildKpiGrid(stats),
                  const SizedBox(height: AppTheme.space24),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDocumentAlertsCard(stats)),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(child: _buildRecentMaintenanceCard(stats)),
                      ],
                    )
                  else ...[
                    _buildDocumentAlertsCard(stats),
                    const SizedBox(height: AppTheme.space16),
                    _buildRecentMaintenanceCard(stats),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(DashboardStats stats, bool wide) {
    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STARK FLEET / OPERATIONS',
          style: TextStyle(
            color: AppTheme.onNavyLabel,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Text(
          'Fleet operations overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 34 : 27,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        const Text(
          'Review vehicle availability, upcoming renewals and maintenance activity in one place.',
          style: TextStyle(
            color: AppTheme.onNavyMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.space16),
        Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space8,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.vehiclesRoute),
              icon: const Icon(Icons.directions_car_outlined, size: 17),
              label: const Text('View Fleet Directory'),
            ),
            _heroLink('Driver Roster', AppRouter.driversRoute),
            _heroLink('Documents Vault', AppRouter.documentsRoute),
            _heroLink('Maintenance Hub', AppRouter.maintenanceRoute),
          ],
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.workspaceHeroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Stack(
          children: [
            const Positioned.fill(
              child: AmbientGridPattern(
                spacing: 26,
                dotRadius: 0.8,
                dotColor: Color(0x44698BC9),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(
                wide ? AppTheme.space32 : AppTheme.space20,
              ),
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: overview),
                        const SizedBox(width: AppTheme.space24),
                        SizedBox(width: 234, child: _buildStatusSummary(stats)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        overview,
                        const SizedBox(height: AppTheme.space24),
                        _buildStatusSummary(stats),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroLink(String label, String route) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0x244A6DB3),
        side: const BorderSide(color: Color(0x668BADFF)),
        minimumSize: const Size(48, 42),
      ),
      onPressed: () => Navigator.of(context).pushNamed(route),
      child: Text(label),
    );
  }

  Widget _buildStatusSummary(DashboardStats stats) {
    final statuses = [
      (
        label: 'Active',
        count: stats.activeVehicles,
        color: AppTheme.accentBlue,
      ),
      (
        label: 'Maintenance',
        count: stats.maintenanceVehicles,
        color: const Color(0xFFFBBF74),
      ),
      (
        label: 'Inactive',
        count: stats.inactiveVehicles,
        color: const Color(0xFF7E92B6),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: const Color(0xA60B1732),
        border: Border.all(color: const Color(0x667995C8)),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vehicle status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ColoredBox(
              color: AppTheme.navy800,
              child: SizedBox(
                height: 7,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final status in statuses)
                      if (status.count > 0)
                        Expanded(
                          flex: status.count,
                          child: ColoredBox(color: status.color),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          for (final status in statuses)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.space8),
              child: Row(
                children: [
                  Icon(Icons.circle, color: status.color, size: 8),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      status.label,
                      style: const TextStyle(
                        color: AppTheme.onNavyMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${status.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DashboardStats stats) {
    final activePercent = stats.totalVehicles == 0
        ? 0
        : (stats.activeVehicles * 100 / stats.totalVehicles).round();
    final cards = [
      _KpiData(
        title: 'Total Fleet',
        value: stats.totalVehicles,
        subtitle: '${stats.activeVehicles} active in service',
        icon: Icons.directions_car_outlined,
        route: AppRouter.vehiclesRoute,
      ),
      _KpiData(
        title: 'Active Vehicles',
        value: stats.activeVehicles,
        subtitle: '$activePercent% of registered vehicles',
        icon: Icons.check_circle_outline,
        route: AppRouter.vehiclesRoute,
      ),
      _KpiData(
        title: 'Under Maintenance',
        value: stats.maintenanceVehicles,
        subtitle: stats.maintenanceVehicles > 0
            ? 'Requires attention'
            : 'All clear',
        icon: Icons.build_outlined,
        route: AppRouter.vehiclesRoute,
      ),
      _KpiData(
        title: 'Registered Drivers',
        value: stats.totalDrivers,
        subtitle:
            '${stats.availableDrivers} available / ${stats.assignedDrivers} assigned',
        icon: Icons.badge_outlined,
        route: AppRouter.driversRoute,
      ),
      _KpiData(
        title: 'Expiring Documents',
        value: stats.expiredDocuments + stats.expiringSoonDocuments,
        subtitle:
            '${stats.expiredDocuments} expired, ${stats.expiringSoonDocuments} within 30 days',
        icon: Icons.warning_amber_rounded,
        route: AppRouter.documentsRoute,
      ),
      _KpiData(
        title: 'Maintenance Cost',
        value: stats.totalMaintenanceCost,
        subtitle: '${stats.totalMaintenanceRecords} lifetime service records',
        icon: Icons.receipt_long_outlined,
        route: AppRouter.maintenanceRoute,
        isCurrency: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.space12;
        final width = constraints.maxWidth;
        final columns = width >= 760 ? 3 : (width >= 500 ? 2 : 1);
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: _buildKpiCard(card)),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData card) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(card.route),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _sectionIcon(card.icon),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      card.title,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_outward,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedCounter(
                  value: card.value,
                  prefix: card.isCurrency ? r'$' : '',
                  decimalDigits: card.isCurrency ? 2 : 0,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                card.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
    );
  }

  Widget _buildActivityPanel({
    required String title,
    required String summary,
    required String action,
    required String route,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionIcon(icon),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        summary,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          content,
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(route),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              iconAlignment: IconAlignment.end,
              label: Text(action),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textMuted, height: 1.5),
      ),
    );
  }

  Widget _buildDocumentAlertsCard(DashboardStats stats) {
    final documents = stats.upcomingExpiries;

    return _buildActivityPanel(
      title: 'Upcoming document expiries',
      summary: '${documents.length} shown in this overview',
      action: 'Open documents',
      route: AppRouter.documentsRoute,
      icon: Icons.description_outlined,
      content: documents.isEmpty
          ? _buildActivityEmpty('No upcoming document expiries to review.')
          : Column(
              children: [
                for (final doc in documents)
                  ListTile(
                    dense: true,
                    title: Text(
                      '${doc.documentType.label} · ${doc.vehicleNumber ?? 'Vehicle #${doc.vehicleId}'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Expiry: ${doc.expiryDate.toIso8601String().substring(0, 10)}'
                      '${doc.documentNumber != null ? ' (#${doc.documentNumber})' : ''}',
                    ),
                    trailing: Text(
                      doc.expiryStatusLabel,
                      style: TextStyle(
                        color: doc.statusBadgeTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.vehicleDetailsPath(doc.vehicleId)),
                  ),
              ],
            ),
    );
  }

  Widget _buildRecentMaintenanceCard(DashboardStats stats) {
    final records = stats.recentMaintenance;

    return _buildActivityPanel(
      title: 'Recent maintenance activity',
      summary: '${records.length} shown in this overview',
      action: 'Open maintenance',
      route: AppRouter.maintenanceRoute,
      icon: Icons.build_outlined,
      content: records.isEmpty
          ? _buildActivityEmpty('No maintenance records logged yet.')
          : Column(
              children: [
                for (final record in records)
                  ListTile(
                    dense: true,
                    title: Text(
                      '${record.maintenanceType.label} · ${record.vehicleNumber ?? 'Vehicle #${record.vehicleId}'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${record.workshopVendor} · ${record.maintenanceDate.toIso8601String().substring(0, 10)}'
                      '${record.odometerReading != null ? ' · ${record.odometerReading} km' : ''}',
                    ),
                    trailing: Text(
                      '\$${record.cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRouter.vehicleDetailsPath(
                        record.vehicleId,
                        initialTab: 1,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _KpiData {
  final String title;
  final num value;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool isCurrency;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.isCurrency = false,
  });
}

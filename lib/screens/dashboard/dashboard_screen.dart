import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/api/dashboard_api_client.dart';
import '../../models/dashboard_stats.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/ambient_grid_pattern.dart';
import '../../widgets/animated/animated_counter.dart';
import '../../widgets/animated/pulsing_beacon.dart';
import '../../widgets/animated/spotlight_hover_card.dart';
import '../../widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiClient _apiClient = DashboardApiClient();
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
        onPressed: _loadStats,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Refresh Telemetry'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
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
              'Connecting to Stark Telematics Network...',
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
                child: const Icon(Icons.error_outline_rounded, size: 32, color: AppTheme.errorRed),
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'Failed to load dashboard metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)),
              ),
              const SizedBox(height: AppTheme.space20),
              FilledButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? AppTheme.space24 : AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroHeader(stats, isDesktop),
          const SizedBox(height: AppTheme.space24),
          _buildKpiGrid(stats),
          const SizedBox(height: AppTheme.space24),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDocumentAlertsCard(stats)),
                const SizedBox(width: AppTheme.space24),
                Expanded(child: _buildRecentMaintenanceCard(stats)),
              ],
            )
          else ...[
            _buildDocumentAlertsCard(stats),
            const SizedBox(height: AppTheme.space24),
            _buildRecentMaintenanceCard(stats),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroHeader(DashboardStats stats, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderNeutral),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle architectural grid background
          const Positioned.fill(
            child: AmbientGridPattern(
              spacing: 24,
              dotRadius: 1.0,
              dotColor: Color(0xFFE2E8F0),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? AppTheme.space24 : AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.statusActiveBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.statusActiveBorder),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulsingBeacon(color: AppTheme.statusActiveText, size: 5),
                          SizedBox(width: 6),
                          Text(
                            'All Systems Operational • Live Telemetry Stream',
                            style: TextStyle(
                              color: AppTheme.statusActiveText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Last updated just now',
                      style: TextStyle(
                        color: AppTheme.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  'Fleet Operations Command',
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const Text(
                    'Real-time fleet telematics, maintenance expenditure analytics, and statutory compliance status for Stark Group assets.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Wrap(
                  spacing: AppTheme.space8,
                  runSpacing: AppTheme.space8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.directions_car_rounded, size: 16, color: AppTheme.primaryBlue),
                      label: const Text('View Fleet Directory'),
                      onPressed: () => Navigator.of(context).pushNamed(AppRouter.vehiclesRoute),
                      backgroundColor: AppTheme.primaryBlueSubtle,
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.badge_rounded, size: 16, color: Color(0xFF7C3AED)),
                      label: const Text('Driver Roster'),
                      onPressed: () => Navigator.of(context).pushNamed(AppRouter.driversRoute),
                      backgroundColor: const Color(0xFFF5F3FF),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.folder_shared_rounded, size: 16, color: Color(0xFF0D9488)),
                      label: const Text('Documents Vault'),
                      onPressed: () => Navigator.of(context).pushNamed(AppRouter.documentsRoute),
                      backgroundColor: const Color(0xFFF0FDFA),
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.build_circle_rounded, size: 16, color: Color(0xFFD97706)),
                      label: const Text('Maintenance Hub'),
                      onPressed: () => Navigator.of(context).pushNamed(AppRouter.maintenanceRoute),
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DashboardStats stats) {
    final cards = [
      _KpiData(
        title: 'Total Fleet',
        numericValue: stats.totalVehicles,
        valueText: stats.totalVehicles.toString(),
        subtitle: '${stats.activeVehicles} active in service',
        icon: Icons.directions_car_rounded,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
        hasBeam: true,
        route: AppRouter.vehiclesRoute,
      ),
      _KpiData(
        title: 'Active Vehicles',
        numericValue: stats.activeVehicles,
        valueText: stats.activeVehicles.toString(),
        subtitle: '${((stats.totalVehicles > 0 ? stats.activeVehicles / stats.totalVehicles : 0) * 100).toStringAsFixed(0)}% utilization',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
        route: AppRouter.vehiclesRoute,
      ),
      _KpiData(
        title: 'Under Maintenance',
        numericValue: stats.maintenanceVehicles,
        valueText: stats.maintenanceVehicles.toString(),
        subtitle: stats.maintenanceVehicles > 0 ? 'Requires attention' : 'All clear',
        icon: Icons.build_circle_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFFFBEB),
        route: AppRouter.vehiclesRoute,
      ),
      _KpiData(
        title: 'Registered Drivers',
        numericValue: stats.totalDrivers,
        valueText: stats.totalDrivers.toString(),
        subtitle: '${stats.availableDrivers} available / ${stats.assignedDrivers} assigned',
        icon: Icons.badge_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        route: AppRouter.driversRoute,
      ),
      _KpiData(
        title: 'Expiring Documents',
        numericValue: stats.expiredDocuments + stats.expiringSoonDocuments,
        valueText: (stats.expiredDocuments + stats.expiringSoonDocuments).toString(),
        subtitle: '${stats.expiredDocuments} expired, ${stats.expiringSoonDocuments} within 30 days',
        icon: Icons.warning_rounded,
        iconColor: stats.expiredDocuments > 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
        bgColor: stats.expiredDocuments > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
        route: AppRouter.documentsRoute,
      ),
      _KpiData(
        title: 'Maintenance Cost',
        numericValue: stats.totalMaintenanceCost,
        isCurrency: true,
        valueText: '\$${stats.totalMaintenanceCost.toStringAsFixed(2)}',
        subtitle: '${stats.totalMaintenanceRecords} lifetime service records',
        icon: Icons.attach_money_rounded,
        iconColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFFF0FDFA),
        route: AppRouter.maintenanceRoute,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100
            ? 3
            : (constraints.maxWidth > 650 ? 2 : 1);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.space16,
            mainAxisSpacing: AppTheme.space16,
            mainAxisExtent: 116,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) {
            final card = cards[i];

            return SpotlightHoverCard(
              borderRadius: AppTheme.radiusLg,
              hasBorderBeam: card.hasBeam,
              beamColor: const Color(0xFF38BDF8),
              beamAccentColor: AppTheme.primaryBlue,
              onTap: card.route != null ? () => Navigator.of(context).pushNamed(card.route!) : null,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: card.bgColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: card.iconColor.withValues(alpha: 0.15)),
                    ),
                    child: Icon(card.icon, color: card.iconColor, size: 24),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedCounter(
                          value: card.numericValue,
                          prefix: card.isCurrency ? '\$' : '',
                          decimalDigits: card.isCurrency ? 2 : 0,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: card.iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentAlertsCard(DashboardStats stats) {
    return SpotlightHoverCard(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, size: 18, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: AppTheme.space12),
                const Text(
                  'Upcoming Document Expiries',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.documentsRoute),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Explore All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stats.upcomingExpiries.isEmpty ? AppTheme.statusActiveBg : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: stats.upcomingExpiries.isEmpty ? AppTheme.statusActiveBorder : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    '${stats.upcomingExpiries.length} Critical',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: stats.upcomingExpiries.isEmpty ? AppTheme.statusActiveText : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderNeutral),
          if (stats.upcomingExpiries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 36, color: Color(0xFF10B981)),
                    SizedBox(height: 8),
                    Text(
                      'All documents are currently valid.',
                      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'No expired or expiring documents in the next 30 days.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.upcomingExpiries.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.borderSubtle),
              itemBuilder: (context, i) {
                final doc = stats.upcomingExpiries[i];
                return ListTile(
                  dense: true,
                  hoverColor: AppTheme.primaryBlueSubtle.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: 4),
                  title: Text(
                    '${doc.documentType.label} • ${doc.vehicleNumber ?? 'Vehicle #${doc.vehicleId}'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Expiry: ${doc.expiryDate.toIso8601String().substring(0, 10)}${doc.documentNumber != null ? ' (#${doc.documentNumber})' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: doc.statusBadgeBgColor,
                      borderRadius: BorderRadius.circular(12),
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
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.vehicleDetailsRoute,
                      arguments: {'id': doc.vehicleId, 'initialTab': 0},
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentMaintenanceCard(DashboardStats stats) {
    return SpotlightHoverCard(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, size: 18, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: AppTheme.space12),
                const Text(
                  'Recent Maintenance Activity',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.maintenanceRoute),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Explore All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderNeutral),
                  ),
                  child: Text(
                    '${stats.recentMaintenance.length} Records',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderNeutral),
          if (stats.recentMaintenance.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.build_circle_outlined, size: 36, color: Color(0xFF94A3B8)),
                    SizedBox(height: 8),
                    Text(
                      'No maintenance records logged yet.',
                      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Service logs and workshop receipts will appear here.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.recentMaintenance.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.borderSubtle),
              itemBuilder: (context, i) {
                final m = stats.recentMaintenance[i];
                return ListTile(
                  dense: true,
                  hoverColor: AppTheme.primaryBlueSubtle.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: 4),
                  title: Text(
                    '${m.maintenanceType.label} • ${m.vehicleNumber ?? 'Vehicle #${m.vehicleId}'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${m.workshopVendor} • ${m.maintenanceDate.toIso8601String().substring(0, 10)}${m.odometerReading != null ? ' • ${m.odometerReading} km' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      '\$${m.cost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.vehicleDetailsRoute,
                      arguments: {'id': m.vehicleId, 'initialTab': 1},
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final num numericValue;
  final String valueText;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool hasBeam;
  final bool isCurrency;
  final String? route;

  _KpiData({
    required this.title,
    required this.numericValue,
    required this.valueText,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.hasBeam = false,
    this.isCurrency = false,
    this.route,
  });
}

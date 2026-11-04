import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/api/dashboard_api_client.dart';
import '../../models/dashboard_stats.dart';
import '../../router/app_router.dart';
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
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Refresh'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.navy800,
          foregroundColor: Colors.white,
        ),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Failed to load dashboard metrics',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.space16),
              FilledButton(
                onPressed: _loadStats,
                child: const Text('Try Again'),
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

  Widget _buildKpiGrid(DashboardStats stats) {
    final cards = [
      _KpiData(
        title: 'Total Fleet',
        value: stats.totalVehicles.toString(),
        subtitle: '${stats.activeVehicles} active in service',
        icon: Icons.directions_car_rounded,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _KpiData(
        title: 'Active Vehicles',
        value: stats.activeVehicles.toString(),
        subtitle: '${((stats.totalVehicles > 0 ? stats.activeVehicles / stats.totalVehicles : 0) * 100).toStringAsFixed(0)}% utilization',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF16A34A),
        bgColor: const Color(0xFFF0FDF4),
      ),
      _KpiData(
        title: 'Under Maintenance',
        value: stats.maintenanceVehicles.toString(),
        subtitle: stats.maintenanceVehicles > 0 ? 'Requires attention' : 'All clear',
        icon: Icons.build_circle_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _KpiData(
        title: 'Registered Drivers',
        value: stats.totalDrivers.toString(),
        subtitle: '${stats.availableDrivers} available / ${stats.assignedDrivers} assigned',
        icon: Icons.badge_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _KpiData(
        title: 'Expiring Documents',
        value: (stats.expiredDocuments + stats.expiringSoonDocuments).toString(),
        subtitle: '${stats.expiredDocuments} expired, ${stats.expiringSoonDocuments} within 30 days',
        icon: Icons.warning_rounded,
        iconColor: stats.expiredDocuments > 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
        bgColor: stats.expiredDocuments > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
      ),
      _KpiData(
        title: 'Maintenance Cost',
        value: '\$${stats.totalMaintenanceCost.toStringAsFixed(2)}',
        subtitle: '${stats.totalMaintenanceRecords} lifetime service records',
        icon: Icons.attach_money_rounded,
        iconColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFFF0FDFA),
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
            mainAxisExtent: 110,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) {
            final card = cards[i];
            return Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: card.bgColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: card.iconColor,
                            fontWeight: FontWeight.w500,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 20, color: AppTheme.navy900),
                const SizedBox(width: AppTheme.space8),
                const Text(
                  'Upcoming Document Expiries',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '${stats.upcomingExpiries.length} Critical',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          if (stats.upcomingExpiries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: Center(
                child: Text(
                  'No expired or expiring documents in the next 30 days.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.upcomingExpiries.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, i) {
                final doc = stats.upcomingExpiries[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${doc.documentType.label} • ${doc.vehicleNumber ?? 'Vehicle #${doc.vehicleId}'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Expiry: ${doc.expiryDate.toIso8601String().substring(0, 10)}${doc.documentNumber != null ? ' (#${doc.documentNumber})' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: doc.statusBadgeBgColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                      arguments: doc.vehicleId,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: AppTheme.navy900),
                const SizedBox(width: AppTheme.space8),
                const Text(
                  'Recent Maintenance Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const Spacer(),
                Text(
                  '${stats.recentMaintenance.length} Records',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          if (stats.recentMaintenance.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: Center(
                child: Text(
                  'No maintenance records logged yet.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.recentMaintenance.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, i) {
                final m = stats.recentMaintenance[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${m.maintenanceType.label} • ${m.vehicleNumber ?? 'Vehicle #${m.vehicleId}'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${m.workshopVendor} • ${m.maintenanceDate.toIso8601String().substring(0, 10)}${m.odometerReading != null ? ' • ${m.odometerReading} km' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Text(
                    '\$${m.cost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.vehicleDetailsRoute,
                      arguments: m.vehicleId,
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
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

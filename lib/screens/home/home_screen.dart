import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_service.dart';
import '../../router/app_router.dart';
import '../../widgets/animated/ambient_grid_pattern.dart';
import '../../widgets/animated/border_beam.dart';
import '../../widgets/animated/pulsing_beacon.dart';

/// Simplified, professional public landing page for Stark Group VMS.
///
/// Follows minimal content structure:
/// - Single clear headline and supporting sentence.
/// - Primary and secondary authentication actions.
/// - Concise code-built visual preview.
/// - 3 essential feature highlights (Registry, Duplicate Prevention, Status Tracking).
/// - Simple, clean navigation and footer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  late final Animation<double> _heroFadeAnimation;
  late final Animation<Offset> _heroSlideAnimation;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _heroFadeAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    ));

    _heroController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      _heroController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openMobileMenu(bool isAuthenticated) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STARK GROUP VMS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.borderNeutral),
                const SizedBox(height: 8),
                if (isAuthenticated) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushNamed(AppRouter.dashboardRoute);
                    },
                    icon: const Icon(Icons.dashboard_rounded, size: 18),
                    label: const Text('Open Fleet Registry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      AuthService.instance.signOut();
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderNeutral),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushNamed(AppRouter.registerRoute);
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Create Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushNamed(AppRouter.loginRoute);
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Sign in'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderNeutral),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasLight,
      body: ValueListenableBuilder(
        valueListenable: AuthService.instance.sessionNotifier,
        builder: (context, session, _) {
          final isAuthenticated = AuthService.instance.isAuthenticated;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky Navigation Header (Deep Navy)
              SliverToBoxAdapter(
                child: _buildNavigationBar(context, isAuthenticated),
              ),

              // Hero Section (Headline, CTA & Code-built Visual)
              SliverToBoxAdapter(
                child: _buildHeroSection(context, isAuthenticated),
              ),

              // 3-Item Feature Overview Section
              SliverToBoxAdapter(
                child: _buildFeaturesSection(context),
              ),

              // Simple Footer
              SliverToBoxAdapter(
                child: _buildFooter(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, bool isAuthenticated) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppTheme.space24 : AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.brandNavy,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Treatment
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'STARK GROUP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Vehicle Management System',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Action Buttons
              if (isDesktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAuthenticated) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.dashboardRoute);
                        },
                        icon: const Icon(Icons.dashboard_rounded, size: 16),
                        label: const Text('Open App'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      OutlinedButton.icon(
                        onPressed: () {
                          AuthService.instance.signOut();
                        },
                        icon: const Icon(Icons.logout, size: 14),
                        label: const Text('Sign out', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFCBD5E1),
                          side: const BorderSide(color: Color(0xFF334155)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.loginRoute);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE2E8F0),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.registerRoute);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _openMobileMenu(isAuthenticated),
                  tooltip: 'Open navigation menu',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isAuthenticated) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Container(
      color: AppTheme.canvasLight,
      child: Stack(
        children: [
          const Positioned.fill(
            child: AmbientGridPattern(
              spacing: 28,
              dotRadius: 1.0,
              dotColor: Color(0xFFE2E8F0),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? AppTheme.space32 : AppTheme.space20,
              vertical: isDesktop ? 48 : 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: FadeTransition(
                  opacity: _heroFadeAnimation,
                  child: SlideTransition(
                    position: _heroSlideAnimation,
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Headline, Subtitle, Actions
                              Expanded(
                                flex: 6,
                                child: _buildHeroLeftContent(context, isAuthenticated),
                              ),
                              const SizedBox(width: 48),
                              // Right: Mock Fleet Dashboard Preview Card
                              Expanded(
                                flex: 5,
                                child: _buildHeroMockPreviewCard(),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildHeroLeftContent(context, isAuthenticated),
                              const SizedBox(height: 32),
                              _buildHeroMockPreviewCard(),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLeftContent(BuildContext context, bool isAuthenticated) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 600;

    return Column(
      crossAxisAlignment: isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppTheme.space16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.statusActiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.statusActiveBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PulsingBeacon(color: AppTheme.statusActiveText, size: 5),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isSmall ? 'Fleet Architecture v2' : 'Assignment 2 • Advanced Fleet Architecture',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.statusActiveText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Headline
        Text(
          'Fleet Operations &\nVehicle Management',
          textAlign: isSmall ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isSmall ? 28 : 38,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.7,
            height: 1.18,
          ),
        ),
        const SizedBox(height: AppTheme.space16),

        // Short supporting sentence
        Text(
          'Register company vehicles, manage fleet records, and track asset status in one place.',
          textAlign: isSmall ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 24),

        // Actions
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: isSmall ? WrapAlignment.center : WrapAlignment.start,
          children: [
            if (isAuthenticated)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.dashboardRoute);
                },
                icon: const Icon(Icons.dashboard_rounded, size: 18),
                label: const Text('Open Fleet Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.registerRoute);
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Create Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.loginRoute);
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textDark,
                  side: const BorderSide(color: AppTheme.borderNeutral, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Visual code-built preview of fleet registry using purely fictional data.
  /// Strictly does NOT fetch real production data.
  Widget _buildHeroMockPreviewCard() {
    return BorderBeam(
      borderRadius: 14,
      beamColor: const Color(0xFF38BDF8),
      accentColor: AppTheme.primaryBlue,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderNeutral),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Fleet Registry Preview',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderNeutral),
                  ),
                  child: const Text(
                    'Fictional Mock Data',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),

            // KPI Mini Cards Row
            Row(
              children: [
                _buildMockKpiChip('Total Fleet', '24', AppTheme.primaryBlue),
                const SizedBox(width: 8),
                _buildMockKpiChip('Active', '21', AppTheme.statusActiveText),
                const SizedBox(width: 8),
                _buildMockKpiChip('Maintenance', '3', AppTheme.statusMaintenanceText),
              ],
            ),
            const SizedBox(height: AppTheme.space16),

            // Sample Vehicle Rows
            _buildMockVehicleRow(
              vin: 'STK-0042',
              model: 'Audi R8 V10 Plus',
              company: 'Stark Industries',
              status: 'ACTIVE',
              statusBg: AppTheme.statusActiveBg,
              statusColor: AppTheme.statusActiveText,
              statusBorder: AppTheme.statusActiveBorder,
            ),
            const SizedBox(height: 8),
            _buildMockVehicleRow(
              vin: 'STK-0108',
              model: 'Tesla Model S Plaid',
              company: 'Stark Logistics',
              status: 'ACTIVE',
              statusBg: AppTheme.statusActiveBg,
              statusColor: AppTheme.statusActiveText,
              statusBorder: AppTheme.statusActiveBorder,
            ),
            const SizedBox(height: 8),
            _buildMockVehicleRow(
              vin: 'STK-0720',
              model: 'Oshkosh M-ATV',
              company: 'Stark Defense',
              status: 'MAINTENANCE',
              statusBg: AppTheme.statusMaintenanceBg,
              statusColor: AppTheme.statusMaintenanceText,
              statusBorder: AppTheme.statusMaintenanceBorder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockKpiChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.canvasLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderNeutral),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockVehicleRow({
    required String vin,
    required String model,
    required String company,
    required String status,
    required Color statusBg,
    required Color statusColor,
    required Color statusBorder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.canvasLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderNeutral),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderNeutral),
                  ),
                  child: Text(
                    vin,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        model,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      Text(
                        company,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusBorder),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    const features = [
      _FeatureItem(
        icon: Icons.directions_car_filled_outlined,
        title: 'Vehicle Registry',
        description: 'Complete directory of all company vehicles.',
      ),
      _FeatureItem(
        icon: Icons.security_outlined,
        title: 'Duplicate Prevention',
        description: 'Automatic validation prevents duplicate registration numbers.',
      ),
      _FeatureItem(
        icon: Icons.traffic_rounded,
        title: 'Status Tracking',
        description: 'Monitor active, maintenance, and decommissioned assets.',
      ),
    ];

    return Container(
      color: AppTheme.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32, vertical: 48),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 768;
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: features.map((f) {
                return SizedBox(
                  width: isWide ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    decoration: BoxDecoration(
                      color: AppTheme.canvasLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderNeutral),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(f.icon, color: AppTheme.primaryBlue, size: 22),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        Text(
                          f.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space20),
      decoration: const BoxDecoration(
        color: AppTheme.brandNavy,
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        '© Stark Group. Vehicle Management System.',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

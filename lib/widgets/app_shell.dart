import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../data/auth/auth_service.dart';
import '../router/app_router.dart';

/// Top-level application shell providing persistent sidebar on desktop,
/// collapsible drawer on mobile/tablet, user account menu, and working sign-out.
class AppShell extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? primaryAction;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppShell({
    super.key,
    required this.child,
    this.title = 'Vehicles',
    this.primaryAction,
    this.showBackButton = false,
    this.onBack,
  });

  void _handleSignOut(BuildContext context) {
    AuthService.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.loginRoute,
      (route) => false,
    );
  }

  static String _getUserInitials(String email) {
    if (email.isEmpty) return 'AD';
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String _getUserDisplayName(String email) {
    if (email.isEmpty) return 'Administrator';
    final namePart = email.split('@')[0];
    return namePart
        .split('.')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.neutralBg,
      drawer: isDesktop ? null : _buildDrawer(context),
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                tooltip: 'Back to Vehicles',
                onPressed: onBack ?? () => Navigator.of(context).pop(),
              )
            : (isDesktop
                ? null
                : Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Open navigation menu',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  )),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          if (primaryAction != null) ...[
            primaryAction!,
            const SizedBox(width: AppTheme.space12),
          ],
          _buildUserAccountMenu(context),
          const SizedBox(width: AppTheme.space16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) _buildDesktopSidebar(context),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppTheme.navy900,
        border: Border(
          right: BorderSide(color: AppTheme.navy800, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebarBrand(),
          const Divider(color: AppTheme.navy800, height: 1),
          const SizedBox(height: AppTheme.space16),
          _buildSidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: title == 'Fleet Dashboard',
            onTap: () {
              if (title != 'Fleet Dashboard') {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.dashboardRoute,
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 4),
          _buildSidebarItem(
            icon: Icons.directions_car_filled_rounded,
            label: 'Vehicles',
            isActive: title == 'Vehicles' || title.contains('Vehicle'),
            onTap: () {
              if (title != 'Vehicles') {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.vehiclesRoute,
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 4),
          _buildSidebarItem(
            icon: Icons.badge_rounded,
            label: 'Drivers',
            isActive: title == 'Drivers' || title.contains('Driver'),
            onTap: () {
              if (title != 'Drivers') {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.driversRoute,
                  (route) => false,
                );
              }
            },
          ),
          const Spacer(),
          const Divider(color: AppTheme.navy800, height: 1),
          _buildSidebarFooter(context),
        ],
      ),
    );
  }

  Widget _buildSidebarBrand() {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STARK GROUP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Vehicle Management System',
            style: TextStyle(
              color: Color(0xFF94A3B8), // Slate 400
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      child: Material(
        color: isActive ? AppTheme.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    final email = AuthService.instance.currentEmail ?? 'operator@starkgroup.com';
    final initials = _getUserInitials(email);
    final displayName = _getUserDisplayName(email);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            color: const Color(0xFF94A3B8),
            tooltip: 'Sign out',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.navy900,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebarBrand(),
            const Divider(color: AppTheme.navy800, height: 1),
            const SizedBox(height: AppTheme.space16),
            _buildSidebarItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isActive: title == 'Fleet Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                if (title != 'Fleet Dashboard') {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.dashboardRoute,
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 4),
            _buildSidebarItem(
              icon: Icons.directions_car_filled_rounded,
              label: 'Vehicles',
              isActive: title == 'Vehicles' || title.contains('Vehicle'),
              onTap: () {
                Navigator.of(context).pop();
                if (title != 'Vehicles') {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.vehiclesRoute,
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 4),
            _buildSidebarItem(
              icon: Icons.badge_rounded,
              label: 'Drivers',
              isActive: title == 'Drivers' || title.contains('Driver'),
              onTap: () {
                Navigator.of(context).pop();
                if (title != 'Drivers') {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.driversRoute,
                    (route) => false,
                  );
                }
              },
            ),
            const Spacer(),
            const Divider(color: AppTheme.navy800, height: 1),
            _buildSidebarFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAccountMenu(BuildContext context) {
    final email = AuthService.instance.currentEmail ?? 'operator@starkgroup.com';
    final initials = _getUserInitials(email);
    final displayName = _getUserDisplayName(email);

    return PopupMenuButton<String>(
      tooltip: 'User account options',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderNeutral),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textMuted),
        ],
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Text(
                email,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'signout',
          child: const Row(
            children: [
              Icon(Icons.logout, size: 16, color: AppTheme.textDark),
              SizedBox(width: 8),
              Text('Sign out', style: TextStyle(fontSize: 13)),
            ],
          ),
          onTap: () => _handleSignOut(context),
        ),
      ],
    );
  }
}

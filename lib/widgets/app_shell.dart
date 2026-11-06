import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../data/auth/auth_service.dart';
import '../router/app_router.dart';
import 'brand/stark_logo.dart';

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
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRouter.loginRoute, (route) => false);
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
        .map(
          (part) =>
              part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : '',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final compactActions =
        MediaQuery.sizeOf(context).width < 600 && primaryAction != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) SizedBox(width: 256, child: _buildNavigation(context)),
        Expanded(
          child: Scaffold(
            backgroundColor: AppTheme.canvasLight,
            drawer: isDesktop
                ? null
                : Drawer(
                    backgroundColor: AppTheme.brandNavy,
                    child: _buildNavigation(context, isDrawer: true),
                  ),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: isDesktop ? 76 : 64,
              titleSpacing: isDesktop && !showBackButton
                  ? AppTheme.space24
                  : null,
              leading: showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                    )
                  : (isDesktop
                        ? null
                        : Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu_rounded),
                              tooltip: 'Open navigation menu',
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                          )),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                if (!compactActions && primaryAction != null) ...[
                  primaryAction!,
                  const SizedBox(width: AppTheme.space16),
                ],
                _buildUserAccountMenu(context, showName: isDesktop),
                const SizedBox(width: AppTheme.space16),
              ],
              bottom: compactActions
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(52),
                      child: SizedBox(
                        height: 52,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: primaryAction,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            body: child,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context, {bool isDrawer = false}) {
    final currentPath = Uri.tryParse(
      ModalRoute.of(context)?.settings.name ?? '',
    )?.path;
    const destinations = [
      (
        label: 'Dashboard',
        pageTitle: 'Fleet Dashboard',
        icon: Icons.dashboard_outlined,
        route: AppRouter.dashboardRoute,
      ),
      (
        label: 'Vehicles',
        pageTitle: 'Vehicles',
        icon: Icons.directions_car_outlined,
        route: AppRouter.vehiclesRoute,
      ),
      (
        label: 'Drivers',
        pageTitle: 'Drivers',
        icon: Icons.badge_outlined,
        route: AppRouter.driversRoute,
      ),
      (
        label: 'Documents',
        pageTitle: 'Fleet Documents',
        icon: Icons.folder_outlined,
        route: AppRouter.documentsRoute,
      ),
      (
        label: 'Maintenance',
        pageTitle: 'Fleet Maintenance',
        icon: Icons.build_outlined,
        route: AppRouter.maintenanceRoute,
      ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkSidebarGradient,
        border: Border(right: BorderSide(color: AppTheme.navy800)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSidebarBrand(),
            const Divider(color: AppTheme.navy800, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 16, 12),
                    child: Text(
                      'FLEET WORKSPACE',
                      style: TextStyle(
                        color: AppTheme.onNavyLabel,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  for (final destination in destinations)
                    _buildSidebarItem(
                      icon: destination.icon,
                      label: destination.label,
                      isActive:
                          title == destination.pageTitle ||
                          currentPath == destination.route ||
                          (currentPath?.startsWith('${destination.route}/') ??
                              false),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        if (isDrawer) navigator.pop();
                        if (title != destination.pageTitle) {
                          navigator.pushNamedAndRemoveUntil(
                            destination.route,
                            (route) => false,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const Divider(color: AppTheme.navy800, height: 1),
            _buildSidebarFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarBrand() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space20,
      ),
      child: StarkLogo.dark(
        size: StarkLogoSize.medium,
        title: 'STARK GROUP',
        subtitle: 'Vehicle Management System',
        badge: 'VMS',
        showBadge: true,
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final foreground = isActive ? Colors.white : AppTheme.onNavyMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Semantics(
        selected: isActive,
        child: Material(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            hoverColor: Colors.white.withValues(alpha: 0.09),
            focusColor: Colors.white.withValues(alpha: 0.16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space12,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isActive)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context) {
    final email =
        AuthService.instance.currentEmail ?? 'operator@starkgroup.com';
    final initials = _getUserInitials(email);
    final displayName = _getUserDisplayName(email);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Row(
        children: [
          _buildAvatar(initials),
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
                    color: AppTheme.onNavyMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            color: AppTheme.onNavyMuted,
            tooltip: 'Sign out',
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.primaryBlue,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildUserAccountMenu(BuildContext context, {required bool showName}) {
    final email =
        AuthService.instance.currentEmail ?? 'operator@starkgroup.com';
    final initials = _getUserInitials(email);
    final displayName = _getUserDisplayName(email);

    return PopupMenuButton<String>(
      tooltip: 'User account options',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.borderNeutral),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlueSubtle,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(initials),
            if (showName) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 136),
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.expand_more,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
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

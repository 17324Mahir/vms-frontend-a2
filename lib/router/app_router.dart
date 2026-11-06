import 'package:flutter/material.dart';
import '../core/navigation/public_landing_stub.dart'
    if (dart.library.js_interop) '../core/navigation/public_landing_web.dart'
    as landing;
import '../core/theme/app_theme.dart';
import '../data/auth/auth_service.dart';
import '../models/driver.dart';
import '../models/vehicle.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/documents/document_list_screen.dart';
import '../screens/drivers/driver_form_screen.dart';
import '../screens/drivers/driver_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/maintenance/maintenance_list_screen.dart';
import '../screens/vehicles/vehicle_details_screen.dart';
import '../screens/vehicles/vehicle_form_screen.dart';
import '../screens/vehicles/vehicle_list_screen.dart';
import '../widgets/app_shell.dart';

/// Centralized route definitions and page generator for Stark Group VMS.
class AppRouter {
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String resetPasswordRoute = '/reset-password';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String dashboardRoute = '/dashboard';
  static const String vehiclesRoute = '/vehicles';
  static const String vehicleNewRoute = '/vehicles/new';
  static const String vehicleEditRoute = '/vehicles/edit';
  static const String vehicleDetailsRoute = '/vehicles/details';
  static const String documentsRoute = '/documents';
  static const String maintenanceRoute = '/maintenance';
  static const String driversRoute = '/drivers';
  static const String driverNewRoute = '/drivers/new';
  static const String driverEditRoute = '/drivers/edit';

  static bool get isWebWorkspace => landing.isWebWorkspace;

  static void returnToHome(BuildContext context) {
    if (isWebWorkspace) {
      landing.openPublicLanding();
      return;
    }
    Navigator.of(context).pushReplacementNamed(homeRoute);
  }

  static Route<dynamic> _workspaceStart() => generateRoute(
    RouteSettings(
      name: AuthService.instance.isAuthenticated ? dashboardRoute : loginRoute,
    ),
  );

  /// A refreshable details route for the selected vehicle and its initial tab.
  static String vehicleDetailsPath(int vehicleId, {int initialTab = 0}) {
    return Uri(
      path: vehicleDetailsRoute,
      queryParameters: {
        'id': vehicleId.toString(),
        if (initialTab != 0) 'tab': initialTab.toString(),
      },
    ).toString();
  }

  static Route<dynamic> _vehicleNotFound(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const _VehicleNotFoundScreen(),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    // Public routes accessible without authentication
    final isPublic = settings.name == homeRoute ||
        settings.name == loginRoute ||
        settings.name == registerRoute ||
        settings.name == resetPasswordRoute ||
        settings.name == forgotPasswordRoute;

    // Route guard: require active in-memory session for all protected routes
    if (!isPublic && !AuthService.instance.isAuthenticated) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: loginRoute),
        builder: (_) => const LoginScreen(),
      );
    }

    switch (uri?.path) {
      case homeRoute:
        if (isWebWorkspace) return _workspaceStart();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );

      case loginRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case registerRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case resetPasswordRoute:
      case forgotPasswordRoute:
        final initialEmail = settings.arguments is String ? settings.arguments as String : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ResetPasswordScreen(initialEmail: initialEmail),
        );

      case dashboardRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );

      case vehiclesRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VehicleListScreen(),
        );

      case vehicleNewRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VehicleFormScreen(),
        );

      case vehicleDetailsRoute:
        final args = settings.arguments;
        final Map<String, String> parameters;
        try {
          parameters = uri?.queryParameters ?? const {};
        } on FormatException {
          return _vehicleNotFound(settings);
        }
        final urlId = parameters['id'];
        final id = urlId != null
            ? int.tryParse(urlId)
            : switch (args) {
                int() => args,
                Vehicle() => args.id,
                String() => int.tryParse(args),
                Map() => int.tryParse(args['id'].toString()),
                _ => null,
              };
        if (id == null || id < 1) {
          return _vehicleNotFound(settings);
        }

        final legacyTab = args is Map ? args['initialTab']?.toString() : null;
        final tab = parameters['tab'] ?? legacyTab;
        final initialTab = (int.tryParse(tab ?? '') ?? 0).clamp(0, 1);
        return MaterialPageRoute(
          settings: RouteSettings(
            name: vehicleDetailsPath(id, initialTab: initialTab),
            arguments: args,
          ),
          builder: (_) =>
              VehicleDetailsScreen(vehicleId: id, initialTab: initialTab),
        );

      case documentsRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DocumentListScreen(),
        );

      case maintenanceRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MaintenanceListScreen(),
        );

      case vehicleEditRoute:
        final args = settings.arguments;
        if (args is Vehicle) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => VehicleFormScreen(vehicleToEdit: args),
          );
        } else if (args is int) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => VehicleFormScreen(vehicleId: args),
          );
        } else if (args is Map && args['id'] != null) {
          final id = int.tryParse(args['id'].toString());
          if (id != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => VehicleFormScreen(vehicleId: id),
            );
          }
        } else if (args is String) {
          final id = int.tryParse(args);
          if (id != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => VehicleFormScreen(vehicleId: id),
            );
          }
        }
        return _vehicleNotFound(settings);

      case driversRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DriverListScreen(),
        );

      case driverNewRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DriverFormScreen(),
        );

      case driverEditRoute:
        final args = settings.arguments;
        if (args is Driver) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DriverFormScreen(driverToEdit: args),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DriverListScreen(),
        );

      default:
        if (isWebWorkspace) return _workspaceStart();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomeScreen(),
        );
    }
  }
}

/// Recovery screen when attempting to navigate to an edit route without a valid vehicle.
class _VehicleNotFoundScreen extends StatelessWidget {
  const _VehicleNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Vehicle Not Found',
      showBackButton: true,
      onBack: () => Navigator.of(context).pushReplacementNamed(AppRouter.vehiclesRoute),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(height: AppTheme.space16),
                  const Text(
                    'Vehicle Not Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  const Text(
                    'The vehicle could not be loaded or may have been deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRouter.vehiclesRoute);
                    },
                    child: const Text('Back to Vehicles'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

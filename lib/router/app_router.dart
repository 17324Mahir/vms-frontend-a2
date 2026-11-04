import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../data/auth/auth_service.dart';
import '../models/vehicle.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/vehicles/vehicle_form_screen.dart';
import '../screens/vehicles/vehicle_list_screen.dart';
import '../widgets/app_shell.dart';

/// Centralized route definitions and page generator for Stark Group VMS.
class AppRouter {
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String vehiclesRoute = '/vehicles';
  static const String vehicleNewRoute = '/vehicles/new';
  static const String vehicleEditRoute = '/vehicles/edit';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Public routes accessible without authentication
    final isPublic = settings.name == homeRoute ||
        settings.name == loginRoute ||
        settings.name == registerRoute;

    // Route guard: require active in-memory session for all protected routes
    if (!isPublic && !AuthService.instance.isAuthenticated) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: loginRoute),
        builder: (_) => const LoginScreen(),
      );
    }

    switch (settings.name) {
      case homeRoute:
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
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _VehicleNotFoundScreen(),
        );

      default:
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.errorRed),
                const SizedBox(height: AppTheme.space16),
                const Text(
                  'Vehicle Record Not Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                const Text(
                  'The requested vehicle record could not be loaded or was removed from the registry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: AppTheme.space24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRouter.vehiclesRoute);
                  },
                  child: const Text('Return to Vehicles'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

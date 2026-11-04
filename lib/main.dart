import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/auth/auth_service.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start background keep-alive heartbeat to wake up backend and keep it warm
  AuthService.instance.startKeepAlive();
  runApp(const StarkVmsApp());
}

/// Root application widget for Stark Group Vehicle Management System (VMS).
class StarkVmsApp extends StatelessWidget {
  final String initialRoute;

  const StarkVmsApp({
    super.key,
    this.initialRoute = AppRouter.homeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stark Group - Vehicle Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shared presentation for account screens. Forms own validation and actions.
class AuthLayout extends StatelessWidget {
  static const _truckImage = 'landing/public/fleet-truck-hero.jpg';

  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showFleetPanel = screenWidth >= 920;

    return Scaffold(
      backgroundColor: AppTheme.brandObsidian,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.authBackdrop),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth < 420 ? 16 : 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: showFleetPanel ? 1110 : 480,
                ),
                child: Material(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showFleetPanel)
                          const Expanded(child: _FleetPanel()),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(
                              screenWidth < 420 ? 22 : 36,
                            ),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FleetPanel extends StatelessWidget {
  const _FleetPanel();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 610),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AuthLayout._truckImage,
            fit: BoxFit.cover,
            alignment: const Alignment(0.62, 0),
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x18091226), Color(0xF5091226)],
                stops: [0.30, 1],
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STARK FLEET  /  WORKSPACE',
                    style: TextStyle(
                      color: Color(0xFFAAC4FF),
                      fontSize: 11,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Keep your fleet moving.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.1,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Vehicles, drivers and service history in one workspace.',
                    style: TextStyle(color: Color(0xFFCAD8EE), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

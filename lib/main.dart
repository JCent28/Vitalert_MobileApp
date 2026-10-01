import 'package:flutter/material.dart';
import 'screens/main_navigation_scaffold.dart';
import 'screens/signin_screen.dart';
import 'services/alert_notification_service.dart';
import 'services/foreground_service_manager.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertNotificationService.initialize();
  await ForegroundServiceManager.init();
  await ForegroundServiceManager.startService();
  runApp(const VitalertApp());
}

class VitalertApp extends StatefulWidget {
  const VitalertApp({super.key});

  @override
  State<VitalertApp> createState() => _VitalertAppState();
}

class _VitalertAppState extends State<VitalertApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VITALERT Patient Monitoring System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.20,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: ResponsiveMobileContainer(
        child: AnimatedBuilder(
          animation: _appState,
          builder: (context, _) {
            // While reading saved session from disk, show a brief splash
            if (_appState.isRestoringSession) {
              return const _SplashScreen();
            }

            if (!_appState.isLoggedIn) {
              return SignInScreen(
                state: _appState,
                onLoginSuccess: () {},
              );
            }
            return MainNavigationScaffold(
              state: _appState,
              onSignOut: () {
                _appState.signOut();
              },
            );
          },
        ),
      ),
    );
  }
}

/// A responsive wrapper that centers and frames the mobile app on wider desktop/web screens
/// while remaining edge-to-edge on mobile devices.
class ResponsiveMobileContainer extends StatelessWidget {
  final Widget child;

  const ResponsiveMobileContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If running on a desktop or wide browser window, display in a refined phone frame
        if (constraints.maxWidth > 520) {
          return Scaffold(
            backgroundColor: const Color(0xFFE2E8F0),
            body: Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                  maxHeight: 920,
                ),
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          );
        }

        // On mobile, render edge-to-edge
        return child;
      },
    );
  }
}

/// Shown briefly while the app reads the saved session from local storage.
/// Typically visible for under 300ms on most devices.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo mark
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4014B8A6),
                    blurRadius: 28,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'VITALERT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Patient Monitoring System',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

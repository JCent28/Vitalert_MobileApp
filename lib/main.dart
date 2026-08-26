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

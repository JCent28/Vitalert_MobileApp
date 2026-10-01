import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_top_bar.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'patient_log_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  final AppState state;
  final VoidCallback onSignOut;

  const MainNavigationScaffold({
    super.key,
    required this.state,
    required this.onSignOut,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  /// Shows a confirmation dialog before signing out to prevent accidental logouts.
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 8),
            Text(
              'Sign Out?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'You will need to sign in again to access patient monitoring.\n\nMake sure all active alerts have been acknowledged before leaving.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sign Out'),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSignOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, child) {
        final currentIndex = widget.state.currentTabIndex;
        final activeAlertCount = widget.state.activeAlerts.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppTopBar(
            showBack: currentIndex != 0,
            onBack: () => widget.state.setTabIndex(0),
            onLiveTap: () => widget.state.setTabIndex(1),
            onAlertsTap: () => widget.state.setTabIndex(1),
            onSignOutTap: () => _confirmSignOut(context),
          ),
          body: IndexedStack(
            index: currentIndex,
            children: [
              // Tab 0: Dashboard (Floor Overview)
              DashboardScreen(
                state: widget.state,
                onPatientSelected: (patientId) {
                  widget.state.selectPatient(patientId);
                  widget.state.setTabIndex(2);
                },
                onSignOut: () => _confirmSignOut(context),
                onAlertsTap: () => widget.state.setTabIndex(1),
              ),

              // Tab 1: Alerts (Active & Acknowledged)
              AlertsScreen(
                state: widget.state,
                onPatientSelected: (patientId) {
                  widget.state.selectPatient(patientId);
                  widget.state.setTabIndex(2);
                },
              ),

              // Tab 2: Patient Log (Vitals Telemetry & Trend Charts)
              PatientLogScreen(
                state: widget.state,
                onPatientSelected: (id) => widget.state.selectPatient(id),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomBar(
            currentIndex: currentIndex,
            onTabSelected: (index) => widget.state.setTabIndex(index),
            onSignOut: () => _confirmSignOut(context),
            activeAlertCount: activeAlertCount,
          ),
        );
      },
    );
  }
}

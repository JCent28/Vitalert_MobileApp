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
            onSignOutTap: widget.onSignOut,
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
                onSignOut: widget.onSignOut,
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
            onSignOut: widget.onSignOut,
            activeAlertCount: activeAlertCount,
          ),
        );
      },
    );
  }
}

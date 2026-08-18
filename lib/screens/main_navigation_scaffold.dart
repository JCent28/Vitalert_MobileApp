import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_top_bar.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'patient_log_screen.dart';
import 'patient_vitals_screen.dart';

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
  void _openPatientVitals(String patientId) {
    widget.state.selectPatient(patientId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnimatedBuilder(
          animation: widget.state,
          builder: (context, _) => PatientVitalsScreen(
            state: widget.state,
            patientId: patientId,
            onBack: () => Navigator.of(context).pop(),
            onViewFullLog: () {
              Navigator.of(context).pop();
              widget.state.setTabIndex(2);
            },
          ),
        ),
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

        final isLogTab = currentIndex == 2;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppTopBar(
            showBack: currentIndex != 0,
            onBack: () => widget.state.setTabIndex(0),
            subtitle: isLogTab ? 'PATIENT LOG - JUN 16, 2026' : null,
          ),
          body: IndexedStack(
            index: currentIndex,
            children: [
              // Tab 0: Dashboard
              DashboardScreen(
                state: widget.state,
                onPatientSelected: _openPatientVitals,
                onSignOut: widget.onSignOut,
              ),

              // Tab 1: Alerts
              AlertsScreen(
                state: widget.state,
                onPatientSelected: _openPatientVitals,
              ),

              // Tab 2: Patient Log
              PatientLogScreen(
                state: widget.state,
                onPatientSelected: (id) => widget.state.selectPatient(id),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomBar(
            currentIndex: currentIndex,
            onTabSelected: (index) => widget.state.setTabIndex(index),
            activeAlertCount: activeAlertCount,
          ),
        );
      },
    );
  }
}

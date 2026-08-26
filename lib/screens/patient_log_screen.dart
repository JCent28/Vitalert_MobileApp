import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../models/patient.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class PatientLogScreen extends StatefulWidget {
  final AppState state;
  final Function(String patientId) onPatientSelected;

  const PatientLogScreen({
    super.key,
    required this.state,
    required this.onPatientSelected,
  });

  @override
  State<PatientLogScreen> createState() => _PatientLogScreenState();
}

class _PatientLogScreenState extends State<PatientLogScreen> {
  String _selectedTimeRange = 'Last 18 minutes';
  String? _selectedSessionNumber;

  static const List<String> _timeRangeOptions = [
    'Last 6 minutes',
    'Last 12 minutes',
    'Last 18 minutes',
    'Last 30 minutes',
    'Last 1 hour',
    'Last 2 hours',
    'Full Session',
  ];

  @override
  Widget build(BuildContext context) {
    final patient = widget.state.selectedPatient;
    final criticalAlertsCount = patient.alertEvents.where((e) => e.severity == AlertSeverity.critical).length;
    final warningAlertsCount = patient.alertEvents.where((e) => e.severity == AlertSeverity.warning).length;
    final infoAlertsCount = patient.alertEvents.where((e) => e.severity == AlertSeverity.info).length;
    final totalAlerts = patient.alertEvents.length;

    final isVerySmall = context.isVerySmallPhone;
    final isSmall = context.isSmallPhone;

    final currentSessionNumber = _cleanSession(patient.session);

    final availableSessions = patient.sessionHistories.isNotEmpty
        ? patient.sessionHistories
        : [
            PatientSessionHistory(
              sessionNumber: currentSessionNumber,
              sessionTitle: 'Session $currentSessionNumber',
              startTime: patient.startTime,
              duration: patient.duration,
              highestHr: patient.highestHr,
              lowestHr: patient.lowestHr,
              avgHr: patient.avgHr,
              highestSpO2: patient.highestSpO2,
              lowestSpO2: patient.lowestSpO2,
              avgSpO2: patient.avgSpO2,
              hrHistory: patient.hrHistory,
              spO2History: patient.spO2History,
              readings: patient.recentReadings,
            ),
          ];

    final activeSessionNumber = _selectedSessionNumber ?? currentSessionNumber;
    final selectedSessionHistory = availableSessions.firstWhere(
      (s) => s.sessionNumber == activeSessionNumber,
      orElse: () => availableSessions.first,
    );

    final isSelectedSessionCurrent = selectedSessionHistory.sessionNumber == currentSessionNumber;
    final isSelectedSessionActive = isSelectedSessionCurrent && patient.sessionStatus == 'Ongoing';
    final hasSelectedSessionReadings = selectedSessionHistory.readings.isNotEmpty;

    final bpmPoints = _getBpmPointsForRange(_selectedTimeRange, selectedSessionHistory.readings);
    final spO2Points = _getSpO2PointsForRange(_selectedTimeRange, selectedSessionHistory.readings);
    final timeRangeSubheader = _getSubheaderForRange(_selectedTimeRange, selectedSessionHistory.readings);

    return SingleChildScrollView(
      padding: context.responsivePagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title (No remarks or comments at top left)
          Text(
            'Patient Log',
            style: AppTypography.headlineLg(color: AppColors.textMain).copyWith(
              fontSize: isVerySmall ? 20 : (isSmall ? 22 : 24),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clinical note recorder opened'),
                        backgroundColor: AppColors.primary,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Record Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exporting session PDF/CSV report...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Export Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMain,
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Patient Information Card (Exact Match to Design Reference)
          Container(
            padding: EdgeInsets.all(isVerySmall ? 14 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Content: Avatar + Name + Pill + Metadata
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deep Dark Teal Circular Avatar (JD)
                    Container(
                      width: isVerySmall ? 44 : 50,
                      height: isVerySmall ? 44 : 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF004D40),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          patient.initials.isNotEmpty ? patient.initials : 'JD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isVerySmall ? 15 : 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Right Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and Status Pill Row
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                patient.name,
                                style: TextStyle(
                                  color: const Color(0xFF0F172A),
                                  fontSize: isVerySmall ? 16.5 : 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              // Dynamic Session Status Pill (Ongoing / Completed / Waiting)
                              Builder(
                                builder: (context) {
                                  final sStatus = patient.sessionStatus.toUpperCase();
                                  Color bg = const Color(0xFFEEF2FF);
                                  Color border = const Color(0xFFC7D2FE);
                                  Color dot = const Color(0xFF4F46E5);
                                  Color text = const Color(0xFF4338CA);

                                  if (sStatus == 'ONGOING') {
                                    bg = const Color(0xFFECFDF5);
                                    border = const Color(0xFFA7F3D0);
                                    dot = const Color(0xFF059669);
                                    text = const Color(0xFF047857);
                                  } else if (sStatus == 'WAITING') {
                                    bg = const Color(0xFFFFFBEB);
                                    border = const Color(0xFFFDE68A);
                                    dot = const Color(0xFFD97706);
                                    text = const Color(0xFFB45309);
                                  }

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: dot,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          sStatus,
                                          style: TextStyle(
                                            color: text,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Metadata Chips Row (Chair | Session | Device | Started)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              // Chair (Building outline icon)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.domain_outlined, size: 15, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chair ${patient.chair}',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w300)),

                              // Session Badge Box with Calendar Icon (Interactive dropdown)
                              PopupMenuButton<String>(
                                tooltip: 'Select Session',
                                offset: const Offset(0, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                color: Colors.white,
                                elevation: 6,
                                onSelected: (val) {
                                  setState(() {
                                    _selectedSessionNumber = val;
                                  });
                                },
                                itemBuilder: (context) {
                                  return availableSessions.map((s) {
                                    final isSelected = s.sessionNumber == selectedSessionHistory.sessionNumber;
                                    return PopupMenuItem<String>(
                                      value: s.sessionNumber,
                                      height: 36,
                                      child: Text(
                                        s.sessionTitle,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 12.5, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        selectedSessionHistory.sessionTitle,
                                        style: const TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),

                              const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w300)),

                              // Device
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Device: ${patient.deviceId.isEmpty ? "N/A" : patient.deviceId}',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w300)),

                              // Started Time
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedSessionHistory.startTime == '--' || (isSelectedSessionCurrent && patient.sessionStatus == 'Waiting')
                                        ? 'Started: Session not started yet'
                                        : 'Started: Aug 21, 2026 ${selectedSessionHistory.startTime}',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Change Patient & Session Historical Dropdown Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 1. Change Patient Dropdown Pill Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSessionNumber = null;
                        });
                        _showChangePatientModal(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Change Patient',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Session Dropdown Button (Historical Sessions from Database)
                    PopupMenuButton<String>(
                      tooltip: 'Select Session History',
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      elevation: 8,
                      onSelected: (val) {
                        setState(() {
                          _selectedSessionNumber = val;
                        });
                      },
                      itemBuilder: (context) {
                        return availableSessions.map((s) {
                          final isSelected = s.sessionNumber == selectedSessionHistory.sessionNumber;
                          final isLiveCurrent = s.sessionNumber == currentSessionNumber;
                          return PopupMenuItem<String>(
                            value: s.sessionNumber,
                            padding: EdgeInsets.zero,
                            height: 42,
                            child: Container(
                              width: double.infinity,
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              color: isSelected ? const Color(0xFFF0FDFA) : Colors.transparent,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 16,
                                        color: isSelected ? const Color(0xFF005953) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        s.sessionTitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF005953) : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isLiveCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: const Text(
                                        'Current',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    )
                                  else if (s.readings.isNotEmpty)
                                    Text(
                                      '${s.readings.length} readings',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF005953), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x04000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: Color(0xFF005953),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              selectedSessionHistory.sessionTitle,
                              style: const TextStyle(
                                color: Color(0xFF005953),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF005953),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. BPM Card (Matching Screenshot 1: Highest / Lowest / Average)
          _buildTelemetryMetricCard(
            title: 'BPM (Pulse Rate)',
            icon: Icons.favorite_border_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEF2F2),
            currentLabel: 'CURRENT',
            currentVal: isSelectedSessionActive && patient.currentHr > 0
                ? '${patient.currentHr}'
                : (hasSelectedSessionReadings
                    ? '${selectedSessionHistory.readings.first.hrBpm}'
                    : (patient.currentHr > 0 ? '${patient.currentHr}' : '--')),
            currentUnit: 'bpm',
            highestVal: hasSelectedSessionReadings
                ? '${selectedSessionHistory.highestHr}'
                : (patient.highestHr > 0 ? '${patient.highestHr}' : '--'),
            lowestVal: hasSelectedSessionReadings
                ? '${selectedSessionHistory.lowestHr}'
                : (patient.lowestHr > 0 ? '${patient.lowestHr}' : '--'),
            averageVal: hasSelectedSessionReadings
                ? selectedSessionHistory.avgHr.toStringAsFixed(1)
                : (patient.avgHr > 0 ? patient.avgHr.toStringAsFixed(1) : '--'),
            footerText: hasSelectedSessionReadings
                ? 'Recorded at ${selectedSessionHistory.startTime} (${selectedSessionHistory.duration} elapsed)'
                : (patient.startTime != '--' && patient.startTime.isNotEmpty
                    ? 'Recorded at ${patient.startTime} (${patient.duration} elapsed)'
                    : 'Session not started yet'),
          ),
          const SizedBox(height: 12),

          // 2. SpO2 Card (Matching Screenshot 1: Highest / Lowest / Average)
          _buildTelemetryMetricCard(
            title: 'SpO₂ (Oxygen Saturation)',
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFFE0F2FE),
            currentLabel: 'CURRENT',
            currentVal: isSelectedSessionActive && patient.currentSpO2 > 0
                ? '${patient.currentSpO2}%'
                : (hasSelectedSessionReadings
                    ? '${selectedSessionHistory.readings.first.spO2}%'
                    : (patient.currentSpO2 > 0 ? '${patient.currentSpO2}%' : '--')),
            currentUnit: '%',
            highestVal: hasSelectedSessionReadings
                ? '${selectedSessionHistory.highestSpO2}%'
                : (patient.highestSpO2 > 0 ? '${patient.highestSpO2}%' : '--'),
            lowestVal: hasSelectedSessionReadings
                ? '${selectedSessionHistory.lowestSpO2}%'
                : (patient.lowestSpO2 > 0 ? '${patient.lowestSpO2}%' : '--'),
            averageVal: hasSelectedSessionReadings
                ? '${selectedSessionHistory.avgSpO2.toStringAsFixed(1)}%'
                : (patient.avgSpO2 > 0 ? '${patient.avgSpO2.toStringAsFixed(1)}%' : '--'),
            footerText: hasSelectedSessionReadings
                ? 'Recorded at ${selectedSessionHistory.startTime} (${selectedSessionHistory.duration} elapsed)'
                : (patient.startTime != '--' && patient.startTime.isNotEmpty
                    ? 'Recorded at ${patient.startTime} (${patient.duration} elapsed)'
                    : 'Session not started yet'),
          ),
          const SizedBox(height: 12),

          // 3. Alerts Card (Matching Screenshot 2: TOTAL ALERTS, Critical, Warning, Info, Last Alert)
          _buildAlertsSummaryCard(
            totalAlerts: totalAlerts,
            criticalCount: criticalAlertsCount,
            warningCount: warningAlertsCount,
            infoCount: infoAlertsCount,
            lastAlertText: patient.alertEvents.isNotEmpty
                ? 'Triggered at ${patient.alertEvents.first.time}'
                : 'None',
            onTap: () => widget.state.setTabIndex(1),
          ),
          const SizedBox(height: 24),

          // Vital Trends Header (Title + Dropdown matching Screenshot 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Vital Trends',
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontSize: isVerySmall ? 19 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              // Dropdown Menu Button (Pill with green border)
              PopupMenuButton<String>(
                tooltip: 'Select Time Range',
                offset: const Offset(0, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                elevation: 8,
                onSelected: (val) {
                  setState(() {
                    _selectedTimeRange = val;
                  });
                },
                itemBuilder: (context) {
                  return _timeRangeOptions.map((opt) {
                    final isSelected = opt == _selectedTimeRange;
                    return PopupMenuItem<String>(
                      value: opt,
                      padding: EdgeInsets.zero,
                      height: 38,
                      child: Container(
                        width: double.infinity,
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedTimeRange,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Subheader line: e.g. "23:44 – 00:01 (17m duration) • Captured every 1m"
          Text(
            timeRangeSubheader,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Interactive BPM Graph Card
          InteractiveVitalGraphCard(
            title: 'BPM (Pulse Rate)',
            unit: 'bpm',
            dataPoints: bpmPoints,
            yMin: 0.0,
            yMax: 160.0,
            yLabels: const ['160', '120', '80', '40', '0'],
            yUnit: 'bpm',
            lineColor: const Color(0xFFF43F5E),
          ),
          const SizedBox(height: 14),

          // Interactive SpO2 Graph Card
          InteractiveVitalGraphCard(
            title: 'SpO₂ (Oxygen Saturation)',
            unit: '%',
            dataPoints: spO2Points,
            yMin: 80.0,
            yMax: 100.0,
            yLabels: const ['100', '95', '90', '85', '80'],
            yUnit: '%',
            lineColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 22),

          // Captured Readings Table (Scrollable container for multiple records)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Captured Readings Table', style: AppTypography.headlineMd(color: AppColors.textMain).copyWith(fontSize: 16)),
              Text('${selectedSessionHistory.readings.length} readings', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  color: AppColors.background,
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('TIMESTAMP', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10))),
                      Expanded(child: Center(child: Text('BPM', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)))),
                      Expanded(child: Center(child: Text('SpO₂', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)))),
                      Expanded(child: Align(alignment: Alignment.centerRight, child: Text('STATUS', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)))),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderLight, height: 1),
                // Scrollable Readings List if many
                if (selectedSessionHistory.readings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      'No readings recorded for this session yet.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: selectedSessionHistory.readings.map((reading) {
                        final isCrit = reading.severity == AlertSeverity.critical;
                        final isWarn = reading.severity == AlertSeverity.warning;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.8)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${reading.time} (${reading.duration})',
                                  style: AppTypography.bodyLg(color: AppColors.textMain, weight: FontWeight.bold).copyWith(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${reading.hrBpm}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isCrit ? AppColors.criticalRed : isWarn ? AppColors.warningAmber : AppColors.textMain,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${reading.spO2}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: reading.spO2 < 95 ? AppColors.warningAmber : AppColors.textMain,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCrit
                                          ? AppColors.errorBg
                                          : isWarn
                                              ? AppColors.warningAmberBg
                                              : AppColors.normalGreenBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      reading.status,
                                      style: TextStyle(
                                        color: isCrit
                                            ? AppColors.criticalRed
                                            : isWarn
                                                ? AppColors.warningAmber
                                                : AppColors.normalGreen,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alert Events Section (Scrollable list if multiple)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alert Events', style: AppTypography.headlineMd(color: AppColors.textMain).copyWith(fontSize: 16)),
              Text('${patient.alertEvents.length} events', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          if (patient.alertEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text(
                  'No alert events recorded during this session.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: patient.alertEvents.map((event) {
                    final isCrit = event.severity == AlertSeverity.critical;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCrit ? AppColors.errorBg : AppColors.warningAmberBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCrit ? AppColors.errorBorder : AppColors.warningAmberBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 16,
                                    color: isCrit ? AppColors.criticalRed : AppColors.warningAmber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    event.time,
                                    style: AppTypography.bodyLg(color: AppColors.textMain, weight: FontWeight.bold).copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCrit ? AppColors.criticalRed : AppColors.warningAmber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCrit ? 'CRITICAL' : 'WARNING',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(event.description, style: AppTypography.bodyMd(color: AppColors.textMain, fontSize: 12)),
                          if (event.acknowledgementNote != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: AppColors.normalGreen),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.acknowledgementNote!,
                                    style: const TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Metric Card matching Screenshot 1 (Highest, Lowest, Average)
  Widget _buildTelemetryMetricCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String currentLabel,
    required String currentVal,
    required String currentUnit,
    required String highestVal,
    required String lowestVal,
    required String averageVal,
    required String footerText,
  }) {
    return Builder(
      builder: (context) {
        final isVerySmall = context.isVerySmallPhone;
        return Container(
          padding: EdgeInsets.all(isVerySmall ? 12 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Two-column Current vs (Highest / Lowest / Average)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Current Reading
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLabel,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currentVal,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                currentUnit,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    width: 1,
                    height: 65,
                    color: const Color(0xFFF1F5F9),
                    margin: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 14),
                  ),

                  // Right Column: Highest, Lowest, Average
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow('Highest', highestVal, valueColor: const Color(0xFFEF4444)),
                        const SizedBox(height: 6),
                        _buildStatRow('Lowest', lowestVal),
                        const SizedBox(height: 6),
                        _buildStatRow('Average', averageVal),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF8FAFC), height: 1),
              const SizedBox(height: 10),

              // Footer Text
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      footerText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF0F172A),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Alerts Summary Card matching Screenshot 2 (TOTAL ALERTS, Critical, Warning, Info)
  Widget _buildAlertsSummaryCard({
    required int totalAlerts,
    required int criticalCount,
    required int warningCount,
    required int infoCount,
    required String lastAlertText,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final isVerySmall = context.isVerySmallPhone;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(isVerySmall ? 12 : 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Icon & Title
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFBEB),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.notifications_none_rounded, size: 18, color: Color(0xFFD97706)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Alerts',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Two Column Layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Total Alerts
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL ALERTS',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$totalAlerts',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'in this session',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      width: 1,
                      height: 70,
                      color: const Color(0xFFF1F5F9),
                      margin: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 14),
                    ),

                    // Right Column: Critical, Warning, Info
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow('Critical', '$criticalCount', valueColor: const Color(0xFFEF4444)),
                          const SizedBox(height: 6),
                          _buildStatRow('Warning', '$warningCount', valueColor: const Color(0xFFF59E0B)),
                          const SizedBox(height: 6),
                          _buildStatRow('Info', '$infoCount', valueColor: const Color(0xFF0F172A)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFF8FAFC), height: 1),
                const SizedBox(height: 10),

                // Footer Text
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Last Alert: $lastAlertText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSubheaderForRange(String range, List<PatientReading> readings) {
    if (readings.isEmpty) {
      return 'Session not started yet';
    }
    final firstTime = readings.last.time;
    final lastTime = readings.first.time;
    final duration = readings.first.duration;
    return '$firstTime – $lastTime ($duration duration) • Captured every 1m';
  }

  List<TelemetryDataPoint> _getBpmPointsForRange(String range, List<PatientReading> readings) {
    if (readings.isEmpty) {
      return const [];
    }
    final all = readings.reversed.toList();
    int count = 18;
    if (range == 'Last 6 minutes') count = 6;
    if (range == 'Last 12 minutes') count = 12;
    if (range == 'Last 30 minutes') count = 30;
    if (range == 'Last 1 hour') count = 60;
    if (range == 'Last 2 hours') count = 120;
    if (range == 'Full Session') count = all.length;

    final slice = all.length > count ? all.sublist(all.length - count) : all;
    return slice.map((r) {
      final v = r.hrBpm.toDouble();
      final isCrit = v > 120 || v < 60;
      final isWarn = v > 100 || v < 70;

      final status = isCrit ? 'CRITICAL' : (isWarn ? 'WARNING' : 'NORMAL');
      final dotColor = isCrit ? const Color(0xFFEF4444) : (isWarn ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
      final statusBg = isCrit ? const Color(0xFF450A0A) : (isWarn ? const Color(0xFF78350F) : const Color(0xFF064E3B));
      final statusBorder = isCrit ? const Color(0xFF7F1D1D) : (isWarn ? const Color(0xFF92400E) : const Color(0xFF065F46));
      final statusTextColor = isCrit ? const Color(0xFFF87171) : (isWarn ? const Color(0xFFFBBF24) : const Color(0xFF34D399));

      return TelemetryDataPoint(
        value: v,
        time: r.time,
        duration: r.duration,
        status: status,
        dotColor: dotColor,
        statusBg: statusBg,
        statusBorder: statusBorder,
        statusTextColor: statusTextColor,
      );
    }).toList();
  }

  List<TelemetryDataPoint> _getSpO2PointsForRange(String range, List<PatientReading> readings) {
    if (readings.isEmpty) {
      return const [];
    }
    final all = readings.reversed.toList();
    int count = 18;
    if (range == 'Last 6 minutes') count = 6;
    if (range == 'Last 12 minutes') count = 12;
    if (range == 'Last 30 minutes') count = 30;
    if (range == 'Last 1 hour') count = 60;
    if (range == 'Last 2 hours') count = 120;
    if (range == 'Full Session') count = all.length;

    final slice = all.length > count ? all.sublist(all.length - count) : all;
    return slice.map((r) {
      final v = r.spO2.toDouble();
      final isCrit = v < 90;
      final isWarn = v < 95;

      final status = isCrit ? 'CRITICAL' : (isWarn ? 'WARNING' : 'NORMAL');
      final dotColor = isCrit ? const Color(0xFFEF4444) : (isWarn ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
      final statusBg = isCrit ? const Color(0xFF450A0A) : (isWarn ? const Color(0xFF78350F) : const Color(0xFF064E3B));
      final statusBorder = isCrit ? const Color(0xFF7F1D1D) : (isWarn ? const Color(0xFF92400E) : const Color(0xFF065F46));
      final statusTextColor = isCrit ? const Color(0xFFF87171) : (isWarn ? const Color(0xFFFBBF24) : const Color(0xFF34D399));

      return TelemetryDataPoint(
        value: v,
        time: r.time,
        duration: r.duration,
        status: status,
        dotColor: dotColor,
        statusBg: statusBg,
        statusBorder: statusBorder,
        statusTextColor: statusTextColor,
      );
    }).toList();
  }

  void _showChangePatientModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Patient',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: widget.state.patients.map((p) {
                      final isSelected = p.id == widget.state.selectedPatient.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF004D40),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              p.initials,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF004D40) : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text('Chair ${p.chair} • ${p.session} • ${p.deviceId}'),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF004D40))
                            : null,
                        onTap: () {
                          widget.state.selectPatient(p.id);
                          widget.onPatientSelected(p.id);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _cleanSession(String session) {
    final match = RegExp(r'\d+').firstMatch(session);
    return match != null ? match.group(0)! : '1';
  }
}

class TelemetryDataPoint {
  final double value;
  final String time;
  final String duration;
  final String status;
  final Color dotColor;
  final Color statusBg;
  final Color statusBorder;
  final Color statusTextColor;

  const TelemetryDataPoint({
    required this.value,
    required this.time,
    required this.duration,
    required this.status,
    required this.dotColor,
    required this.statusBg,
    required this.statusBorder,
    required this.statusTextColor,
  });
}

class InteractiveVitalGraphCard extends StatefulWidget {
  final String title;
  final String unit;
  final List<TelemetryDataPoint> dataPoints;
  final double yMin;
  final double yMax;
  final List<String> yLabels;
  final String yUnit;
  final Color lineColor;

  const InteractiveVitalGraphCard({
    super.key,
    required this.title,
    required this.unit,
    required this.dataPoints,
    required this.yMin,
    required this.yMax,
    required this.yLabels,
    required this.yUnit,
    required this.lineColor,
  });

  @override
  State<InteractiveVitalGraphCard> createState() => _InteractiveVitalGraphCardState();
}

class _InteractiveVitalGraphCardState extends State<InteractiveVitalGraphCard> {
  int? _hoveredIndex; // null by default — only shows when clicked or hovered!

  @override
  void didUpdateWidget(covariant InteractiveVitalGraphCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataPoints.length != oldWidget.dataPoints.length) {
      if (_hoveredIndex != null && _hoveredIndex! >= widget.dataPoints.length) {
        _hoveredIndex = null;
      }
    }
  }

  void _onTapGraph(Offset localPos, double chartWidth) {
    if (widget.dataPoints.isEmpty) return;
    const leftMargin = 38.0;
    final usableWidth = chartWidth - leftMargin - 16.0;
    if (usableWidth <= 0) return;
    final relX = (localPos.dx - leftMargin).clamp(0.0, usableWidth);
    final frac = relX / usableWidth;
    final idx = (frac * (widget.dataPoints.length - 1)).round().clamp(0, widget.dataPoints.length - 1);
    setState(() {
      if (_hoveredIndex == idx) {
        _hoveredIndex = null; // Toggle off if clicked again
      } else {
        _hoveredIndex = idx;
      }
    });
  }

  void _onHover(Offset localPos, double chartWidth) {
    if (widget.dataPoints.isEmpty) return;
    const leftMargin = 38.0;
    final usableWidth = chartWidth - leftMargin - 16.0;
    if (usableWidth <= 0) return;
    final relX = (localPos.dx - leftMargin).clamp(0.0, usableWidth);
    final frac = relX / usableWidth;
    final idx = (frac * (widget.dataPoints.length - 1)).round().clamp(0, widget.dataPoints.length - 1);
    setState(() {
      _hoveredIndex = idx;
    });
  }

  void _onExit() {
    setState(() {
      _hoveredIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside Card (Colored dash + Title)
          Row(
            children: [
              Container(
                width: 18,
                height: 3.5,
                decoration: BoxDecoration(
                  color: widget.lineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Graph Area
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              const chartHeight = 210.0;
              const leftMargin = 38.0;
              const rightMargin = 16.0;
              const topMargin = 16.0;
              const bottomMargin = 30.0;

              final usableWidth = chartWidth - leftMargin - rightMargin;
              final usableHeight = chartHeight - topMargin - bottomMargin;

              TelemetryDataPoint? activePoint;
              double pointX = 0;
              double pointY = 0;

              if (_hoveredIndex != null &&
                  _hoveredIndex! >= 0 &&
                  _hoveredIndex! < widget.dataPoints.length &&
                  usableWidth > 0 &&
                  usableHeight > 0) {
                activePoint = widget.dataPoints[_hoveredIndex!];
                pointX = leftMargin + (_hoveredIndex! / (widget.dataPoints.length - 1)) * usableWidth;
                final normY = (activePoint.value - widget.yMin) / (widget.yMax - widget.yMin);
                pointY = topMargin + usableHeight - (normY.clamp(0.0, 1.0) * usableHeight);
              }

              const tooltipWidth = 175.0;
              const tooltipHeight = 56.0;
              double tooltipLeft = pointX - (tooltipWidth / 2);
              if (tooltipLeft < 6.0) tooltipLeft = 6.0;
              if (tooltipLeft + tooltipWidth > chartWidth - 6.0) {
                tooltipLeft = chartWidth - tooltipWidth - 6.0;
              }
              double tooltipTop = pointY - tooltipHeight - 8.0;
              if (tooltipTop < 2.0) {
                tooltipTop = pointY + 14.0;
              }

              return MouseRegion(
                onHover: (event) => _onHover(event.localPosition, chartWidth),
                onExit: (_) => _onExit(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) => _onTapGraph(details.localPosition, chartWidth),
                  onPanUpdate: (details) => _onHover(details.localPosition, chartWidth),
                  child: SizedBox(
                    width: chartWidth,
                    height: chartHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Custom Painted Chart
                        CustomPaint(
                          size: Size(chartWidth, chartHeight),
                          painter: _InteractiveChartPainter(
                            dataPoints: widget.dataPoints,
                            yMin: widget.yMin,
                            yMax: widget.yMax,
                            yLabels: widget.yLabels,
                            yUnit: widget.yUnit,
                            lineColor: widget.lineColor,
                            hoveredIndex: _hoveredIndex,
                          ),
                        ),

                        // If no data recorded yet for session
                        if (widget.dataPoints.isEmpty)
                          const Positioned.fill(
                            child: Center(
                              child: Text(
                                'No chart data recorded yet',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // Pop-up Floating Tooltip (Shown ONLY when clicked or hovered)
                        if (activePoint != null) ...[
                          // Caret pointer triangle
                          if (tooltipTop < pointY)
                            Positioned(
                              left: (pointX - 5.0).clamp(10.0, chartWidth - 10.0),
                              top: pointY - 8.0,
                              child: CustomPaint(
                                size: const Size(10, 8),
                                painter: _TriangleCaretPainter(color: const Color(0xFF1E293B)),
                              ),
                            ),

                          // Main Tooltip Box (Clickable to dismiss)
                          Positioned(
                            left: tooltipLeft,
                            top: tooltipTop,
                            child: InkWell(
                              onTap: () => setState(() => _hoveredIndex = null),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: tooltipWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x35000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Line 1: Dot + Value + Status Tag
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: activePoint.dotColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${activePoint.value.toInt()} ${widget.unit}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: activePoint.statusBg,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: activePoint.statusBorder),
                                              ),
                                              child: Text(
                                                activePoint.status,
                                                style: TextStyle(
                                                  color: activePoint.statusTextColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.close, size: 12, color: Color(0xFF94A3B8)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),

                                    // Line 2: Time + (Duration)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                            children: [
                                              const TextSpan(text: 'Time: '),
                                              TextSpan(
                                                text: activePoint.time,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '(${activePoint.duration})',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveChartPainter extends CustomPainter {
  final List<TelemetryDataPoint> dataPoints;
  final double yMin;
  final double yMax;
  final List<String> yLabels;
  final String yUnit;
  final Color lineColor;
  final int? hoveredIndex;

  _InteractiveChartPainter({
    required this.dataPoints,
    required this.yMin,
    required this.yMax,
    required this.yLabels,
    required this.yUnit,
    required this.lineColor,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 38.0;
    const rightMargin = 16.0;
    const topMargin = 16.0;
    const bottomMargin = 30.0;

    final usableWidth = size.width - leftMargin - rightMargin;
    final usableHeight = size.height - topMargin - bottomMargin;
    if (usableWidth <= 0 || usableHeight <= 0) return;

    // 1. Draw Y-Unit label at top left ("bpm" or "%")
    final yUnitPainter = TextPainter(
      text: TextSpan(
        text: yUnit,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yUnitPainter.paint(canvas, const Offset(6, 2));

    // 2. Draw Y-Axis labels and dashed grid lines
    final gridLinePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final numSteps = yLabels.length - 1;
    for (int i = 0; i <= numSteps; i++) {
      final y = topMargin + (i / numSteps) * usableHeight;

      // Draw Y label text
      final textPainter = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(leftMargin - textPainter.width - 6, y - (textPainter.height / 2)));

      // Draw dashed horizontal line
      _drawDashedLine(canvas, Offset(leftMargin, y), Offset(leftMargin + usableWidth, y), gridLinePaint);
    }

    if (dataPoints.isEmpty) return;

    // 3. Draw X-Axis Time Labels
    final xStepCount = 4;
    for (int i = 0; i <= xStepCount; i++) {
      final dataIdx = ((i / xStepCount) * (dataPoints.length - 1)).round().clamp(0, dataPoints.length - 1);
      final point = dataPoints[dataIdx];
      final x = leftMargin + (dataIdx / (dataPoints.length - 1)) * usableWidth;

      final xPainter = TextPainter(
        text: TextSpan(
          text: point.time,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      xPainter.paint(canvas, Offset(x - (xPainter.width / 2), size.height - 18));
    }

    // 4. Calculate line coordinates
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = leftMargin + (i / (dataPoints.length - 1)) * usableWidth;
      final normY = (dataPoints[i].value - yMin) / (yMax - yMin);
      final y = topMargin + usableHeight - (normY.clamp(0.0, 1.0) * usableHeight);
      points.add(Offset(x, y));
    }

    // 5. Draw smooth line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // 6. Draw highlighted active point
    if (hoveredIndex != null && hoveredIndex! >= 0 && hoveredIndex! < points.length) {
      final activePoint = points[hoveredIndex!];

      // Vertical guide line
      final guidePaint = Paint()
        ..color = const Color(0xFF94A3B8).withAlpha(80)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(activePoint.dx, topMargin), Offset(activePoint.dx, topMargin + usableHeight), guidePaint);

      // Active point halo and circle
      final haloPaint = Paint()
        ..color = lineColor.withAlpha(50)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 8, haloPaint);

      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 4.5, dotPaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(activePoint, 4.5, borderPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double curX = p1.dx;
    while (curX < p2.dx) {
      final nextX = (curX + dashWidth).clamp(p1.dx, p2.dx);
      canvas.drawLine(Offset(curX, p1.dy), Offset(nextX, p1.dy), paint);
      curX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveChartPainter oldDelegate) => true;
}

class _TriangleCaretPainter extends CustomPainter {
  final Color color;
  _TriangleCaretPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleCaretPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  final AppState state;
  final Function(String patientId) onPatientSelected;

  const AlertsScreen({
    super.key,
    required this.state,
    required this.onPatientSelected,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _showActive = false; // Defaults to Acknowledged tab if 0 active, or active if any
  String _selectedSeverityFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Default to active tab if there are active alerts, otherwise acknowledged
    _showActive = widget.state.activeAlerts.isNotEmpty;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = widget.state.activeAlerts;
    final acknowledgedAlerts = widget.state.acknowledgedAlerts;

    final criticalCount = activeAlerts.where((a) => a.severity == AlertSeverity.critical).length;
    final warningCount = activeAlerts.where((a) => a.severity == AlertSeverity.warning).length;
    final ackCount = acknowledgedAlerts.length;

    final isVerySmall = context.isVerySmallPhone;
    final isSmall = context.isSmallPhone;

    return SingleChildScrollView(
      padding: context.responsivePagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Alerts',
            style: AppTypography.headlineLg(color: AppColors.textMain).copyWith(
              fontSize: isVerySmall ? 20 : (isSmall ? 22 : 24),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Text(
                  'Shift A',
                  style: AppTypography.labelCaps(
                    color: AppColors.primaryDark,
                    fontSize: 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 6),
              Text(
                widget.state.shiftTime.replaceFirst('Shift A · ', ''),
                style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: isVerySmall ? 11 : 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Counter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCountPill(
                  label: 'Critical',
                  count: '$criticalCount',
                  color: AppColors.criticalRed,
                  bg: Colors.white,
                  border: const Color(0xFFFECACA),
                ),
                const SizedBox(width: 8),
                _buildCountPill(
                  label: 'Warning',
                  count: '$warningCount',
                  color: AppColors.warningAmber,
                  bg: Colors.white,
                  border: const Color(0xFFFDE68A),
                ),
                const SizedBox(width: 8),
                _buildCountPill(
                  label: 'Acknowledged',
                  count: '$ackCount',
                  color: AppColors.normalGreen,
                  bg: Colors.white,
                  border: const Color(0xFFA7F3D0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Navigation Tabs (Active vs Acknowledged)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Active Tab
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _showActive = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _showActive ? const Color(0xFF004D40) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _showActive
                            ? const [
                                BoxShadow(
                                  color: Color(0x15000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Active',
                            style: TextStyle(
                              color: _showActive ? Colors.white : const Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _showActive
                                  ? (activeAlertCountColor(activeAlerts.length))
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${activeAlerts.length}',
                              style: TextStyle(
                                color: _showActive ? Colors.white : const Color(0xFF334155),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Acknowledged Tab
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _showActive = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_showActive ? const Color(0xFF004D40) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_showActive
                            ? const [
                                BoxShadow(
                                  color: Color(0x15000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Acknowledged',
                            style: TextStyle(
                              color: !_showActive ? Colors.white : const Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: !_showActive ? const Color(0xFF00382E) : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$ackCount',
                              style: TextStyle(
                                color: !_showActive ? Colors.white : const Color(0xFF334155),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search patient or chair...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Active Severity Filter Pills (only shown if active tab selected and has alerts)
          if (_showActive && activeAlerts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  _buildFilterChip('All (${activeAlerts.length})', 'All'),
                  _buildFilterChip('Critical ($criticalCount)', 'Critical'),
                  _buildFilterChip('Warning ($warningCount)', 'Warning'),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Alerts List Content
          if (_showActive)
            ..._buildActiveAlertCards(activeAlerts)
          else
            ..._buildAcknowledgedAlertCards(acknowledgedAlerts),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color activeAlertCountColor(int count) {
    if (count == 0) return const Color(0xFF00382E);
    return AppColors.criticalRed;
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedSeverityFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSeverityFilter = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelCaps(
                color: isSelected ? AppColors.textMain : AppColors.textMuted,
                fontSize: 11,
                weight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveAlertCards(List<AlertItem> alerts) {
    var filtered = alerts.where((a) {
      if (_selectedSeverityFilter == 'Critical') return a.severity == AlertSeverity.critical;
      if (_selectedSeverityFilter == 'Warning') return a.severity == AlertSeverity.warning;
      return true;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        return a.patientName.toLowerCase().contains(_searchQuery) ||
            a.chairLocation.toLowerCase().contains(_searchQuery) ||
            a.wardArea.toLowerCase().contains(_searchQuery) ||
            a.message.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: AppColors.normalGreen),
                const SizedBox(height: 12),
                Text('All Clear — No Active Alerts', style: AppTypography.headlineMd(color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(
                  'All currently monitored dialysis patients are within safe ranges.',
                  style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filtered.map((alert) => _buildAlertCardItem(alert, isActive: true)).toList();
  }

  List<Widget> _buildAcknowledgedAlertCards(List<AlertItem> alerts) {
    var filtered = alerts;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        return a.patientName.toLowerCase().contains(_searchQuery) ||
            a.chairLocation.toLowerCase().contains(_searchQuery) ||
            a.wardArea.toLowerCase().contains(_searchQuery) ||
            a.message.toLowerCase().contains(_searchQuery) ||
            (a.acknowledgedBy?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.history_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text('No Acknowledged Alerts', style: AppTypography.headlineMd(color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(
                  'No matching alert records in this shift history.',
                  style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filtered.map((alert) => _buildAlertCardItem(alert, isActive: false)).toList();
  }

  Widget _buildAlertCardItem(AlertItem alert, {required bool isActive}) {
    final isCritical = alert.severity == AlertSeverity.critical;
    final initials = alert.patientName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    final chairNumber = alert.chairLocation.replaceAll('Chair ', '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
              width: 4.5,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Patient Avatar, Name, Chair Badge & Severity Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Avatar Circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCritical ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials.isNotEmpty ? initials : 'JD',
                            style: TextStyle(
                              color: isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Patient Name & Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    alert.patientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    chairNumber.isNotEmpty ? chairNumber : '1',
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alert.wardArea,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Severity Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCritical ? 'CRITICAL' : 'WARNING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Alert Message Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                  size: 18,
                  color: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.message,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 3),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Triggered at ${alert.timeString}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Vitals Snapshot Chips (Responsive Wrap)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BPM: ',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${alert.hrBpm ?? 93}',
                        style: TextStyle(
                          color: (alert.hrBpm ?? 93) > 100 || (alert.hrBpm ?? 93) < 60
                              ? (isCritical ? const Color(0xFFEF4444) : const Color(0xFFD97706))
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SpO₂: ',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${alert.spO2 ?? 92}%',
                        style: TextStyle(
                          color: (alert.spO2 ?? 92) < 95
                              ? (isCritical ? const Color(0xFFEF4444) : const Color(0xFFD97706))
                              : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Acknowledged Status Banner Pill (shown if already acknowledged)
            if (!isActive || alert.isAcknowledged) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF065F46),
                          ),
                          children: [
                            const TextSpan(text: 'Acknowledged by '),
                            TextSpan(
                              text: alert.acknowledgedBy ?? widget.state.nurseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF064E3B),
                              ),
                            ),
                            TextSpan(
                              text: ' at ${alert.acknowledgedAt ?? ""}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (!isActive || alert.isAcknowledged) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.state.selectPatient(alert.patientId);
                    widget.state.setTabIndex(2);
                  },
                  icon: const Icon(Icons.description_outlined, size: 14, color: Color(0xFF64748B)),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View Patient Log',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.state.selectPatient(alert.patientId);
                        widget.state.setTabIndex(2);
                      },
                      icon: const Icon(Icons.description_outlined, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'View Patient Log',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMain,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.state.acknowledgeAlert(alert.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Alert acknowledged by ${widget.state.nurseName}'),
                            backgroundColor: const Color(0xFF007D79),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        setState(() {
                          _showActive = false;
                        });
                      },
                      icon: const Icon(Icons.check, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Acknowledge',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007D79),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountPill({
    required String label,
    required String count,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text('$label: ', style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 11)),
          Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

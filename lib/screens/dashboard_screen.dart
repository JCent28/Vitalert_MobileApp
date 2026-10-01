import 'package:flutter/material.dart';
import '../models/alert_item.dart';
import '../models/device_model.dart';
import '../models/patient.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final AppState state;
  final Function(String patientId) onPatientSelected;
  final VoidCallback onSignOut;
  final VoidCallback? onAlertsTap;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onPatientSelected,
    required this.onSignOut,
    this.onAlertsTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'All Statuses';
  String _selectedSessionFilter = 'All Statuses';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // "Add Patient" Modal Dialog matching requested design
  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final chairController = TextEditingController();
    const defaultNoDevice = 'N/A';
    String selectedDevice = defaultNoDevice;
    final availableDevices = widget.state.devices;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Patient',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Assign a patient to a chair and dialysis session.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. PATIENT NAME:
                  const Text(
                    'PATIENT NAME:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Jane Doe',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. CHAIR NUMBER:
                  const Text(
                    'CHAIR NUMBER:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: chairController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 1',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. SESSION:
                  const Text(
                    'SESSION:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCEEAD6)),
                          ),
                          child: const Text(
                            'Session 1',
                            style: TextStyle(
                              color: Color(0xFF0D652D),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '(Initial dialysis session auto-assigned)',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. DEVICE ID: (optional)
                  RichText(
                    text: const TextSpan(
                      text: 'DEVICE ID: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.3,
                      ),
                      children: [
                        TextSpan(
                          text: '(optional)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedDevice,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF64748B)),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: defaultNoDevice,
                            child: Text(
                              '-- Select an Available Device (Optional) --',
                              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                            ),
                          ),
                          ...(availableDevices.isNotEmpty
                                  ? availableDevices
                                  : [
                                      const DeviceModel(deviceId: 'device1', status: 'IN_USE'),
                                      const DeviceModel(deviceId: 'device2', status: 'AVAILABLE'),
                                      const DeviceModel(deviceId: 'device3', status: 'AVAILABLE'),
                                    ])
                              .map((d) => DropdownMenuItem<String>(
                                    value: d.deviceId,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(d.deviceId),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: d.isAvailable
                                                ? const Color(0xFFECFDF5)
                                                : (d.isInUse ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            d.displayStatus,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: d.isAvailable
                                                  ? const Color(0xFF059669)
                                                  : (d.isInUse ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedDevice = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Optional. You can also assign or pair a device when starting the treatment session.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 5. Actions (Cancel & Add Patient)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF005953),
                            side: const BorderSide(color: Color(0xFF005953)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final chair = chairController.text.trim().isNotEmpty ? chairController.text.trim() : '1';
                            if (name.isNotEmpty) {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.of(ctx).pop();
                              await widget.state.addPatient(
                                name: name,
                                chair: chair,
                                session: '1',
                                deviceId: selectedDevice,
                              );
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Added patient $name to Chair $chair (Device: $selectedDevice)'),
                                    backgroundColor: const Color(0xFF005953),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005953),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPatientDialog(Patient patient) {
    final nameController = TextEditingController(text: patient.name);
    String selectedChair = patient.chair;
    final cleanSession = patient.session.replaceAll(RegExp(r'[^0-9]'), '');
    String selectedSession = cleanSession.isNotEmpty ? cleanSession : '1';
    final availableDevices = widget.state.devices;
    String selectedDevice = patient.deviceId;
    if (selectedDevice != 'N/A' && availableDevices.isNotEmpty && !availableDevices.any((d) => d.deviceId == selectedDevice)) {
      selectedDevice = availableDevices.first.deviceId;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Patient Details',
                              style: AppTypography.headlineMd(color: AppColors.textMain).copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update chair assignment or paired sensor.',
                              style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight, height: 1),
                  const SizedBox(height: 16),

                  Text('PATIENT NAME', style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CHAIR', style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedChair,
                                  isExpanded: true,
                                  items: ['1', '2', '3', '4', '5', '6', '7', '8']
                                      .map((c) => DropdownMenuItem(value: c, child: Text('Chair $c')))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedChair = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SESSION', style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedSession,
                                  isExpanded: true,
                                  items: ['1', '2', '3', '4', '5']
                                      .map((s) => DropdownMenuItem(value: s, child: Text('Session $s')))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedSession = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DEVICE', style: AppTypography.labelCaps(color: AppColors.textMain, fontSize: 11)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDevice,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: 'N/A', child: Text('(N/A no device attached)')),
                              ...(availableDevices.isNotEmpty
                                      ? availableDevices
                                      : [
                                          const DeviceModel(deviceId: 'device1', status: 'IN_USE'),
                                          const DeviceModel(deviceId: 'device2', status: 'AVAILABLE'),
                                          const DeviceModel(deviceId: 'device3', status: 'AVAILABLE'),
                                        ])
                                  .map((d) => DropdownMenuItem(
                                        value: d.deviceId,
                                        child: Text('${d.deviceId} (${d.displayStatus})'),
                                      )),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedDevice = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textMain,
                            side: const BorderSide(color: AppColors.borderLight),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.state.updatePatient(
                              patient.id,
                              name: nameController.text.trim(),
                              chair: selectedChair,
                              session: selectedSession,
                              deviceId: selectedDevice,
                            );
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Patient details updated'),
                                backgroundColor: AppColors.primary,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // "Start Next Dialysis Session" Modal Dialog (Matching Image 2)
  void _showStartNextSessionDialog(Patient patient) {
    final rawNum = patient.session.replaceAll(RegExp(r'[^0-9]'), '');
    final currentNum = int.tryParse(rawNum) ?? 1;
    final nextSessionNum = currentNum + 1;

    final availableDevices = widget.state.devices;
    String selectedDevice = patient.deviceId != 'N/A'
        ? patient.deviceId
        : (availableDevices.isNotEmpty ? availableDevices.first.deviceId : 'device1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Icon & Title & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline_rounded,
                                color: Color(0xFF059669),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Start Next Dialysis Session',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2. Subheader: Name • Chair • Next Session Badge
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                      Text(
                        'Chair ${patient.chair}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          'Next Session: Session $nextSessionNum',
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. ASSIGN MONITORING DEVICE Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ASSIGN MONITORING DEVICE:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF475569),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedDevice,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF64748B)),
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                              items: (availableDevices.isNotEmpty
                                      ? availableDevices
                                      : [
                                          const DeviceModel(deviceId: 'device1', status: 'IN_USE'),
                                          const DeviceModel(deviceId: 'device2', status: 'AVAILABLE'),
                                          const DeviceModel(deviceId: 'device3', status: 'AVAILABLE'),
                                        ])
                                  .map((d) {
                                return DropdownMenuItem<String>(
                                  value: d.deviceId,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(d.deviceId),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: d.isAvailable
                                              ? const Color(0xFFECFDF5)
                                              : (d.isInUse ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          d.displayStatus,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: d.isAvailable
                                                ? const Color(0xFF059669)
                                                : (d.isInUse ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedDevice = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select an active pulse oximeter device for this session.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. TELEMETRY DATA SOURCE (Physical Device Only)
                  const Text(
                    'TELEMETRY DATA SOURCE:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0D9488), width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '📟 Physical Device',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Connects to an actual bedside pulse oximeter.',
                                style: TextStyle(
                                  fontSize: 11.5,
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
                  const SizedBox(height: 22),

                  // 5. Actions (Cancel & Launch Session)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.of(ctx).pop();
                            await widget.state.startSession(
                              patientId: patient.id,
                              sessionNum: '$nextSessionNum',
                              deviceId: selectedDevice,
                            );
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Dialysis Session $nextSessionNum launched for ${patient.name}. Status: Waiting (READY)'),
                                  backgroundColor: const Color(0xFF059669),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_circle_outline, size: 16),
                          label: const Text(
                            'Launch Session',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // End Session Confirmation Dialog
  void _showEndSessionDialog(Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Text('End Dialysis Session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to end the current dialysis session for ${patient.name} (Chair ${patient.chair})?\n\nThis will mark the session as Completed and free ${patient.deviceId} for other patients.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              await widget.state.endSession(patientId: patient.id, deviceId: patient.deviceId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Ended dialysis session for ${patient.name}. Status: Completed'),
                    backgroundColor: const Color(0xFF4F46E5),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('End Session', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Deactivate Patient Confirmation Dialog
  void _showDeactivatePatientDialog(Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate Patient', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to discharge and deactivate ${patient.name} from Chair ${patient.chair}?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              await widget.state.deactivatePatient(patient.id, deviceId: patient.deviceId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Deactivated patient ${patient.name}'),
                    backgroundColor: const Color(0xFFDC2626),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Deactivate', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Session status pill badge builder matching Image 1
  Widget _buildSessionStatusBadge(String status) {
    Color bg;
    Color border;
    Color text;

    final lower = status.toLowerCase();
    if (lower == 'ongoing') {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      text = const Color(0xFF047857);
    } else if (lower == 'completed') {
      bg = const Color(0xFFEEF2FF);
      border = const Color(0xFFC7D2FE);
      text = const Color(0xFF4F46E5);
    } else if (lower == 'inactive') {
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFCBD5E1);
      text = const Color(0xFF64748B);
    } else {
      // Waiting
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Health status pill badge builder with Standby & Ready support
  Widget _buildHealthStatusBadge(Patient patient) {
    if (patient.sessionStatus == 'Completed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: const Text(
          'COMPLETED',
          style: TextStyle(
            color: Color(0xFF4F46E5),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    if (patient.deviceId == 'N/A' && patient.currentHr == 0 && patient.currentSpO2 == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Text(
          'STANDBY',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    if (patient.sessionStatus == 'Waiting' && patient.currentHr == 0 && patient.currentSpO2 == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: const Text(
          'READY',
          style: TextStyle(
            color: Color(0xFF15803D),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    final isCritical = patient.status == AlertSeverity.critical;
    final isWarning = patient.status == AlertSeverity.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCritical
            ? AppColors.errorBg
            : isWarning
                ? AppColors.warningAmberBg
                : AppColors.normalGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? AppColors.errorBorder
              : isWarning
                  ? AppColors.warningAmberBorder
                  : AppColors.normalGreenBorder,
        ),
      ),
      child: Text(
        isCritical
            ? 'CRITICAL'
            : isWarning
                ? 'WARNING'
                : 'NORMAL',
        style: TextStyle(
          color: isCritical
              ? AppColors.criticalRed
              : isWarning
                  ? AppColors.warningAmber
                  : AppColors.normalGreen,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Action popup menu items builder based on session status
  List<PopupMenuEntry<String>> _buildActionMenuItems(Patient patient) {
    final isOngoing = patient.sessionStatus == 'Ongoing';

    if (isOngoing) {
      return [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'end_session',
          child: Row(
            children: [
              Icon(Icons.stop_circle_outlined, size: 16, color: Color(0xFFE11D48)),
              SizedBox(width: 10),
              Text('End Session', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE11D48))),
            ],
          ),
        ),
      ];
    } else {
      // Completed or Waiting or Inactive
      return [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'start_session',
          child: Row(
            children: [
              Icon(Icons.play_circle_outline, size: 16, color: Color(0xFF059669)),
              SizedBox(width: 10),
              Text('Start Session', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'deactivate',
          child: Row(
            children: [
              Icon(Icons.block_outlined, size: 16, color: Color(0xFFE11D48)),
              SizedBox(width: 10),
              Text('Deactivate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE11D48))),
            ],
          ),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerySmall = context.isVerySmallPhone;
    final isSmall = context.isSmallPhone;
    final patients = widget.state.patients;
    final totalPatients = widget.state.totalActivePatients;
    final normalCount = widget.state.normalPatientsCount;
    final warningCount = widget.state.warningPatientsCount;
    final criticalCount = widget.state.criticalPatientsCount;

    // Filter patients with dynamic Health Status & Session Status
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredPatients = patients.where((p) {
      final isStandby = p.deviceId == 'N/A';
      final isCompleted = p.sessionStatus.toLowerCase() == 'completed';

      // 1. Health Status Filter: All Statuses, Normal, Warning, Critical, Completed, Standby
      if (_selectedStatusFilter == 'Standby') {
        if (!isStandby) return false;
      } else if (_selectedStatusFilter == 'Completed') {
        if (!isCompleted) return false;
      } else if (_selectedStatusFilter == 'Critical') {
        if (isStandby || p.status != AlertSeverity.critical) return false;
      } else if (_selectedStatusFilter == 'Warning') {
        if (isStandby || p.status != AlertSeverity.warning) return false;
      } else if (_selectedStatusFilter == 'Normal') {
        if (isStandby || isCompleted || p.status != AlertSeverity.info) return false;
      }

      // 2. Session Status Filter: All Statuses, Waiting, Ongoing, Completed, Inactive
      if (_selectedSessionFilter == 'Waiting' && p.sessionStatus.toLowerCase() != 'waiting') return false;
      if (_selectedSessionFilter == 'Ongoing' && p.sessionStatus.toLowerCase() != 'ongoing') return false;
      if (_selectedSessionFilter == 'Completed' && p.sessionStatus.toLowerCase() != 'completed') return false;
      if (_selectedSessionFilter == 'Inactive' && p.sessionStatus.toLowerCase() != 'inactive') return false;

      if (searchQuery.isNotEmpty) {
        return p.name.toLowerCase().contains(searchQuery) ||
            p.chair.toLowerCase().contains(searchQuery) ||
            p.mrn.toLowerCase().contains(searchQuery) ||
            p.deviceId.toLowerCase().contains(searchQuery);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: context.responsivePagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Nurse Station Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: AppTypography.headlineLg(color: AppColors.textMain).copyWith(
                        fontSize: isVerySmall ? 20 : (isSmall ? 22 : 24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.state.shiftTime,
                      style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: isVerySmall ? 11 : 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 13, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      'Station 2',
                      style: AppTypography.labelCaps(
                        color: AppColors.primaryDark,
                        fontSize: 10.5,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2x2 Summary Metric Cards
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ACTIVE PATIENTS',
                      value: '$totalPatients',
                      subvalue: '/ ${widget.state.totalChairs}',
                      subtitle: 'chairs occupied',
                      icon: Icons.people_outline,
                      color: AppColors.infoBlue,
                    ),
                  ),
                  SizedBox(width: isVerySmall ? 8 : 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'NORMAL',
                      value: '$normalCount',
                      subtitle: 'within range',
                      icon: Icons.check_circle_outline,
                      color: AppColors.normalGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isVerySmall ? 8 : 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.state.setTabIndex(1),
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMetricCard(
                        title: 'WARNING',
                        value: '$warningCount',
                        subtitle: 'monitoring alert →',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
                  SizedBox(width: isVerySmall ? 8 : 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.state.setTabIndex(1),
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMetricCard(
                        title: 'CRITICAL',
                        value: '$criticalCount',
                        subtitle: 'respond now →',
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.criticalRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Floor Patients Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floor Patients',
                      style: AppTypography.headlineMd(color: AppColors.textMain).copyWith(
                        fontSize: isVerySmall ? 16 : 18,
                      ),
                    ),
                    Text(
                      'Active dialysis stations (${filteredPatients.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: isVerySmall ? 11 : 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddPatientDialog,
                icon: const Icon(Icons.add, size: 15),
                label: Text(
                  isVerySmall ? 'Add' : 'Add Patient',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005953),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmall ? 8 : 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search & Filter Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  style: AppTypography.bodyMd(color: AppColors.textMain, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search patient, chair, device, or MRN...',
                    hintStyle: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Filters Row: Health Status & Session Status Dropdowns
                Row(
                  children: [
                    // Health Status Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HEALTH STATUS', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatusFilter,
                                isExpanded: true,
                                style: AppTypography.bodyMd(color: AppColors.textMain, fontSize: 12),
                                items: ['All Statuses', 'Normal', 'Warning', 'Critical', 'Completed', 'Standby']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatusFilter = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Session Status Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SESSION STATUS', style: AppTypography.labelCaps(color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSessionFilter,
                                isExpanded: true,
                                style: AppTypography.bodyMd(color: AppColors.textMain, fontSize: 12),
                                items: ['All Statuses', 'Waiting', 'Ongoing', 'Completed', 'Inactive']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSessionFilter = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Scroll Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Swipe horizontally to view all clinical columns',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '10 Columns',
                style: AppTypography.labelCaps(color: AppColors.primary, fontSize: 10, weight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Patients Table Card (Horizontally Scrollable)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1020),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: AppColors.background,
                      child: Row(
                        children: [
                          _buildHeaderCell('NAME', width: 175),
                          _buildHeaderCell('CHAIR', width: 70, center: true),
                          _buildHeaderCell('SESSION', width: 110, center: true),
                          _buildHeaderCell('DEVICE', width: 95, center: true),
                          _buildHeaderCell('BPM', width: 75, center: true),
                          _buildHeaderCell('SPO2', width: 75, center: true),
                          _buildHeaderCell('HEALTH STATUS', width: 115, center: true),
                          _buildHeaderCell('LAST UPDATED', width: 105, center: true),
                          _buildHeaderCell('SESSION STATUS', width: 115, center: true),
                          _buildHeaderCell('ACTIONS', width: 85, center: true),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.borderLight, height: 1),

                    // Table Rows
                    if (filteredPatients.isEmpty)
                      Container(
                        width: 1020,
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No patients found matching the current filters.',
                            style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...filteredPatients.map((patient) {
                        final isStandby = patient.deviceId == 'N/A';
                        final isCritical = !isStandby && patient.status == AlertSeverity.critical;
                        final isWarning = !isStandby && patient.status == AlertSeverity.warning;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.8)),
                          ),
                          child: Row(
                            children: [
                              // 1. NAME
                              SizedBox(
                                width: 175,
                                child: InkWell(
                                  onTap: () {
                                    widget.state.selectPatient(patient.id);
                                    widget.state.setTabIndex(2);
                                  },
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0F172A),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                patient.initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: isStandby
                                                    ? const Color(0xFF94A3B8)
                                                    : (isCritical
                                                        ? AppColors.criticalRed
                                                        : isWarning
                                                            ? AppColors.warningAmber
                                                            : AppColors.normalGreen),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 1.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patient.name,
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              patient.mrn,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 2. CHAIR
                              SizedBox(
                                width: 70,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      patient.chair,
                                      style: AppTypography.labelCaps(
                                        color: AppColors.textMain,
                                        fontSize: 11,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 3. SESSION
                              SizedBox(
                                width: 110,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                                    ),
                                    child: Text(
                                      patient.session,
                                      style: AppTypography.labelCaps(
                                        color: AppColors.primaryDark,
                                        fontSize: 9.5,
                                        weight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),

                              // 4. DEVICE (Shows N/A or Monospace Device ID)
                              SizedBox(
                                width: 95,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isStandby ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: isStandby ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      patient.deviceId,
                                      style: TextStyle(
                                        color: isStandby ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: isStandby ? null : 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 5. BPM
                              SizedBox(
                                width: 75,
                                child: Center(
                                  child: Text(
                                    patient.currentHr == 0 ? '--' : '${patient.currentHr}',
                                    style: AppTypography.metricMono(
                                      color: patient.currentHr == 0
                                          ? const Color(0xFF94A3B8)
                                          : (isCritical
                                              ? AppColors.criticalRed
                                              : isWarning
                                                  ? AppColors.warningAmber
                                                  : AppColors.textMain),
                                      weight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),

                              // 6. SPO2
                              SizedBox(
                                width: 75,
                                child: Center(
                                  child: Text(
                                    patient.currentSpO2 == 0 ? '--' : '${patient.currentSpO2}%',
                                    style: AppTypography.metricMono(
                                      color: patient.currentSpO2 == 0
                                          ? const Color(0xFF94A3B8)
                                          : (patient.currentSpO2 < 90
                                              ? AppColors.criticalRed
                                              : patient.currentSpO2 < 95
                                                  ? AppColors.warningAmber
                                                  : AppColors.textMain),
                                      weight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),

                              // 7. HEALTH STATUS (STANDBY, READY, NORMAL, WARNING, CRITICAL, COMPLETED)
                              SizedBox(
                                width: 115,
                                child: Center(
                                  child: _buildHealthStatusBadge(patient),
                                ),
                              ),

                              // 8. LAST UPDATED
                              SizedBox(
                                width: 105,
                                child: Center(
                                  child: Text(
                                    patient.startTime,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                              // 9. SESSION STATUS (matching Image 1)
                              SizedBox(
                                width: 115,
                                child: Center(
                                  child: _buildSessionStatusBadge(patient.sessionStatus),
                                ),
                              ),

                              // 10. ACTIONS (Popup Menu Button)
                              SizedBox(
                                width: 85,
                                child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF475569)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 150),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      color: Colors.white,
                                      elevation: 4,
                                      onSelected: (action) {
                                        if (action == 'view') {
                                          widget.state.selectPatient(patient.id);
                                          widget.state.setTabIndex(2);
                                        } else if (action == 'edit') {
                                          _showEditPatientDialog(patient);
                                        } else if (action == 'start_session') {
                                          _showStartNextSessionDialog(patient);
                                        } else if (action == 'end_session') {
                                          _showEndSessionDialog(patient);
                                        } else if (action == 'deactivate') {
                                          _showDeactivatePatientDialog(patient);
                                        }
                                      },
                                      itemBuilder: (context) => _buildActionMenuItems(patient),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width, bool center = false}) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          style: AppTypography.labelCaps(
            color: AppColors.textMuted,
            fontSize: 10,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subvalue,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isVerySmall = context.isVerySmallPhone;
    final isSmall = context.isSmallPhone;

    return Container(
      padding: EdgeInsets.all(isVerySmall ? 10 : (isSmall ? 12 : 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelCaps(
                    color: AppColors.textMuted,
                    fontSize: isVerySmall ? 9 : 10,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isVerySmall ? 19 : 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              if (subvalue != null) ...[
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    subvalue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: isVerySmall ? 10 : 11),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd(color: AppColors.textMuted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

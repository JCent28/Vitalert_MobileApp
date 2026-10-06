import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/patient.dart';
import '../state/app_state.dart';

/// Shows the "Start Next Dialysis Session" dialog for assigning a device
/// and launching the session.
void showStartNextSessionDialog({
  required BuildContext context,
  required AppState state,
  required Patient patient,
}) {
  final rawNum = patient.session.replaceAll(RegExp(r'[^0-9]'), '');
  final currentNum = int.tryParse(rawNum) ?? 1;
  final nextSessionNum = patient.sessionStatus.toLowerCase() == 'completed'
      ? currentNum + 1
      : (currentNum > 0 ? currentNum : 1);

  final availableDevices = state.devices;
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
                          await state.startSession(
                            patientId: patient.id,
                            sessionNum: '$nextSessionNum',
                            deviceId: selectedDevice,
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Dialysis Session $nextSessionNum launched for ${patient.name}. Status: Waiting (READY)'),
                              backgroundColor: const Color(0xFF059669),
                              duration: const Duration(seconds: 3),
                            ),
                          );
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

/// Shows the "End Dialysis Session" confirmation dialog.
void showEndSessionDialog({
  required BuildContext context,
  required AppState state,
  required Patient patient,
}) {
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
            await state.endSession(patientId: patient.id, deviceId: patient.deviceId);
            messenger.showSnackBar(
              SnackBar(
                content: Text('Ended dialysis session for ${patient.name}. Status: Completed'),
                backgroundColor: const Color(0xFF4F46E5),
                duration: const Duration(seconds: 2),
              ),
            );
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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/alert_item.dart';
import '../models/patient.dart';

/// Clinical Session Exporter for Vitalert
/// Generates both PDF clinical summaries and CSV telemetry data files.
class ExportService {
  /// Generates and formats a complete CSV export string for a session.
  static String generateSessionCsv({
    required Patient patient,
    required PatientSessionHistory session,
  }) {
    final buffer = StringBuffer();
    final nowFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Header metadata
    buffer.writeln('====================================================');
    buffer.writeln('VITALERT CLINICAL DIALYSIS MONITORING REPORT (CSV)');
    buffer.writeln('Generated: $nowFormatted');
    buffer.writeln('====================================================');
    buffer.writeln('');

    // Patient & Session Demographics
    buffer.writeln('PATIENT & SESSION INFORMATION');
    buffer.writeln('Patient Name,"${_escapeCsv(patient.name)}"');
    buffer.writeln('Medical Record Number (MRN),"${_escapeCsv(patient.mrn)}"');
    buffer.writeln('Station / Chair,"${_escapeCsv(patient.chair)}"');
    buffer.writeln('Department,"${_escapeCsv(patient.department)}"');
    buffer.writeln('Device ID,"${_escapeCsv(patient.deviceId)}"');
    buffer.writeln('Primary Attending Nurse,"${_escapeCsv(patient.primaryNurse)}"');
    final effectiveSessionDate = session.date.isNotEmpty
        ? session.date
        : (patient.date.isNotEmpty && !patient.date.contains('August 21, 2026')
            ? patient.date
            : DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()));

    buffer.writeln('Session Number,"${_escapeCsv(session.sessionTitle.isNotEmpty ? session.sessionTitle : "Session ${session.sessionNumber}")}"');
    buffer.writeln('Session Date,"${_escapeCsv(effectiveSessionDate)}"');
    buffer.writeln('Start Time,"${_escapeCsv(session.startTime)}"');
    buffer.writeln('Total Duration,"${_escapeCsv(session.duration)}"');
    buffer.writeln('');

    // Clinical Summary Metrics
    buffer.writeln('CLINICAL VITALS SUMMARY');
    buffer.writeln('Heart Rate Average (BPM),${session.avgHr.toStringAsFixed(1)}');
    buffer.writeln('Heart Rate Min (BPM),${session.lowestHr}');
    buffer.writeln('Heart Rate Max (BPM),${session.highestHr}');
    buffer.writeln('SpO2 Average (%),${session.avgSpO2.toStringAsFixed(1)}');
    buffer.writeln('SpO2 Min (%),${session.lowestSpO2}');
    buffer.writeln('SpO2 Max (%),${session.highestSpO2}');
    buffer.writeln('Total Telemetry Readings,${session.readings.length}');
    buffer.writeln('');

    // Telemetry Table Header
    buffer.writeln('CAPTURED TELEMETRY READINGS');
    buffer.writeln('Index,Timestamp,Display Time,Elapsed Duration,Heart Rate (BPM),SpO2 (%),Clinical Status,Severity,Clinical Remarks / Notes');

    final readings = session.readings;
    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      final index = i + 1;
      final ts = _escapeCsv(r.timestamp.isNotEmpty ? r.timestamp : '--');
      final time = _escapeCsv(r.time);
      final dur = _escapeCsv(r.duration);
      final hr = r.hrBpm;
      final spo2 = r.spO2;
      final status = _escapeCsv(r.status);
      final sev = _escapeCsv(r.severity.name);
      final remark = _escapeCsv(r.remark);

      buffer.writeln('$index,"$ts","$time","$dur",$hr,$spo2,"$status","$sev","$remark"');
    }

    return buffer.toString();
  }

  /// Exports the session CSV by opening the system share sheet / file saver.
  static Future<void> shareSessionCsv({
    required Patient patient,
    required PatientSessionHistory session,
  }) async {
    final csvContent = generateSessionCsv(patient: patient, session: session);
    final sessionNum = session.sessionNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final patientMrn = patient.mrn.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'vitalert_${patientMrn}_session_$sessionNum.csv';

    if (kIsWeb) {
      final bytes = utf8.encode(csvContent);
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'text/csv',
            name: fileName,
          ),
        ],
        text: 'Vitalert Dialysis Telemetry Report - ${patient.name} (Session $sessionNum)',
        subject: 'Vitalert Session Report ($fileName)',
      );
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvContent, flush: true);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'text/csv',
            name: fileName,
          ),
        ],
        text: 'Vitalert Dialysis Telemetry Report - ${patient.name} (Session $sessionNum)',
        subject: 'Vitalert Session Report ($fileName)',
      );
    } catch (_) {
      // Fallback to text sharing if file writing fails
      await Share.share(
        csvContent,
        subject: 'Vitalert Session Report ($fileName)',
      );
    }
  }

  /// Builds a multi-page PDF document for the session.
  static Future<pw.Document> buildSessionPdf({
    required Patient patient,
    required PatientSessionHistory session,
  }) async {
    final pdf = pw.Document(
      title: 'Vitalert Report - ${patient.name} (Session ${session.sessionNumber})',
      author: 'Vitalert Dialysis Monitoring System',
    );

    final regularFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final nowFormatted = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());

    final readings = session.readings;
    final primaryColor = PdfColor.fromHex('0F766E'); // Teal 700
    final secondaryColor = PdfColor.fromHex('0D9488'); // Teal 600
    final darkText = PdfColor.fromHex('0F172A'); // Slate 900
    final mutedText = PdfColor.fromHex('64748B'); // Slate 500
    final lightBg = PdfColor.fromHex('F8FAFC'); // Slate 50
    final borderColor = PdfColor.fromHex('E2E8F0'); // Slate 200

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'V',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VITALERT CLINICAL MONITOR',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.Text(
                          'Hemodialysis Telemetry & Nursing Session Record',
                          style: pw.TextStyle(fontSize: 8.5, color: mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('F0FDF4'),
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColor.fromHex('86EFAC'), width: 0.8),
                      ),
                      child: pw.Text(
                        'CONFIDENTIAL MEDICAL RECORD',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('166534'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Report Date: $nowFormatted',
                      style: pw.TextStyle(fontSize: 8, color: mutedText),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Patient: ${patient.name} (${patient.mrn}) | Session ${session.sessionNumber}',
                  style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Patient & Session Demographics Grid
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PATIENT & SESSION INFORMATION',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildPdfInfoItem('Patient Name', patient.name, darkText, mutedText),
                      ),
                      pw.Expanded(
                        child: _buildPdfInfoItem('Medical Record #', patient.mrn, darkText, mutedText),
                      ),
                      pw.Expanded(
                        child: _buildPdfInfoItem('Chair / Station', patient.chair, darkText, mutedText),
                      ),
                      pw.Expanded(
                        child: _buildPdfInfoItem('Department', patient.department, darkText, mutedText),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildPdfInfoItem(
                          'Session Title',
                          session.sessionTitle.isNotEmpty ? session.sessionTitle : 'Session ${session.sessionNumber}',
                          darkText,
                          mutedText,
                        ),
                      ),
                      pw.Expanded(
                        child: _buildPdfInfoItem(
                          'Date & Start Time',
                          '${session.date.isNotEmpty ? session.date : (patient.date.isNotEmpty && !patient.date.contains("August 21, 2026") ? patient.date : DateFormat("EEEE, MMMM d, yyyy").format(DateTime.now()))} ${session.startTime}',
                          darkText,
                          mutedText,
                        ),
                      ),
                      pw.Expanded(
                        child: _buildPdfInfoItem('Duration', session.duration, darkText, mutedText),
                      ),
                      pw.Expanded(
                        child: _buildPdfInfoItem('Attending Nurse', patient.primaryNurse, darkText, mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Clinical Summary Statistics Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildPdfMetricBox(
                    label: 'HEART RATE (BPM)',
                    value: '${session.avgHr.toStringAsFixed(0)} bpm',
                    subtext: 'Min: ${session.lowestHr} | Max: ${session.highestHr}',
                    badgeColor: PdfColor.fromHex('FEE2E2'),
                    textColor: PdfColor.fromHex('991B1B'),
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildPdfMetricBox(
                    label: 'BLOOD OXYGEN (SpO2)',
                    value: '${session.avgSpO2.toStringAsFixed(0)}%',
                    subtext: 'Min: ${session.lowestSpO2}% | Max: ${session.highestSpO2}%',
                    badgeColor: PdfColor.fromHex('E0F2FE'),
                    textColor: PdfColor.fromHex('075985'),
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildPdfMetricBox(
                    label: 'RECORDINGS CAPTURED',
                    value: '${readings.length} Samples',
                    subtext: 'Device: ${patient.deviceId}',
                    badgeColor: PdfColor.fromHex('F3E8FF'),
                    textColor: PdfColor.fromHex('6B21A8'),
                    primaryColor: primaryColor,
                    borderColor: borderColor,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Captured Readings Table Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CAPTURED TELEMETRY LOG & REMARKS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: darkText,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  '${readings.length} total entries',
                  style: pw.TextStyle(fontSize: 8.5, color: mutedText),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Telemetry Readings Table
            if (readings.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Text(
                  'No recorded readings found for this dialysis session.',
                  style: pw.TextStyle(fontSize: 9, color: mutedText, fontStyle: pw.FontStyle.italic),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.7),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30), // #
                  1: const pw.FixedColumnWidth(60), // Time
                  2: const pw.FixedColumnWidth(55), // Duration
                  3: const pw.FixedColumnWidth(55), // HR (bpm)
                  4: const pw.FixedColumnWidth(55), // SpO2 (%)
                  5: const pw.FixedColumnWidth(65), // Status
                  6: const pw.FlexColumnWidth(2), // Clinical Remarks
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
                    children: [
                      _buildPdfTableCell('#', isHeader: true, align: pw.TextAlign.center),
                      _buildPdfTableCell('Time', isHeader: true),
                      _buildPdfTableCell('Duration', isHeader: true),
                      _buildPdfTableCell('HR (bpm)', isHeader: true, align: pw.TextAlign.right),
                      _buildPdfTableCell('SpO2 (%)', isHeader: true, align: pw.TextAlign.right),
                      _buildPdfTableCell('Status', isHeader: true, align: pw.TextAlign.center),
                      _buildPdfTableCell('Clinical Remarks / Notes', isHeader: true),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(readings.length, (idx) {
                    final r = readings[idx];
                    final isEven = idx % 2 == 0;
                    final rowBg = isEven ? PdfColors.white : PdfColor.fromHex('F8FAFC');

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildPdfTableCell('${idx + 1}', align: pw.TextAlign.center),
                        _buildPdfTableCell(r.time),
                        _buildPdfTableCell(r.duration),
                        _buildPdfTableCell('${r.hrBpm}', align: pw.TextAlign.right, isBold: true),
                        _buildPdfTableCell('${r.spO2}%', align: pw.TextAlign.right, isBold: true),
                        _buildPdfStatusCell(r.status, r.severity),
                        _buildPdfTableCell(
                          r.remark.isNotEmpty ? r.remark : '--',
                          textColor: r.remark.isNotEmpty ? darkText : mutedText,
                          isItalic: r.remark.isEmpty,
                        ),
                      ],
                    );
                  }),
                ],
              ),

            pw.SizedBox(height: 24),

            // Nurse Sign-off & Verification Section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor),
                borderRadius: pw.BorderRadius.circular(6),
                color: lightBg,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CLINICAL VERIFICATION & SIGN-OFF',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Attending Nurse: ${patient.primaryNurse}',
                        style: pw.TextStyle(fontSize: 8, color: darkText),
                      ),
                      pw.Text(
                        'Verification Date: $nowFormatted',
                        style: pw.TextStyle(fontSize: 8, color: mutedText),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140,
                        height: 28,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(color: darkText, width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signature',
                        style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Opens the print or save dialog directly for the PDF.
  static Future<void> printOrSavePdf({
    required Patient patient,
    required PatientSessionHistory session,
  }) async {
    final pdf = await buildSessionPdf(patient: patient, session: session);
    final sessionNum = session.sessionNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final patientMrn = patient.mrn.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'vitalert_${patientMrn}_session_$sessionNum.pdf';

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Shares the PDF file via the OS share sheet.
  static Future<void> shareSessionPdf({
    required Patient patient,
    required PatientSessionHistory session,
  }) async {
    final pdf = await buildSessionPdf(patient: patient, session: session);
    final bytes = await pdf.save();
    final sessionNum = session.sessionNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final patientMrn = patient.mrn.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = 'vitalert_${patientMrn}_session_$sessionNum.pdf';

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
      subject: 'Vitalert Dialysis Clinical Report - ${patient.name} (Session $sessionNum)',
    );
  }

  // --- Helper Widgets for PDF Building ---

  static pw.Widget _buildPdfInfoItem(
    String label,
    String value,
    PdfColor textDark,
    PdfColor textMuted,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: textMuted),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value.isNotEmpty ? value : '--',
          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textDark),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfMetricBox({
    required String label,
    required String value,
    required String subtext,
    required PdfColor badgeColor,
    required PdfColor textColor,
    required PdfColor primaryColor,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textColor),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtext,
            style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('64748B')),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool isItalic = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? textColor,
  }) {
    final color = textColor ?? (isHeader ? PdfColor.fromHex('334155') : PdfColor.fromHex('0F172A'));
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 7.5,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfStatusCell(String status, AlertSeverity severity) {
    PdfColor bg;
    PdfColor fg;

    switch (severity) {
      case AlertSeverity.critical:
        bg = PdfColor.fromHex('FEE2E2');
        fg = PdfColor.fromHex('991B1B');
        break;
      case AlertSeverity.warning:
        bg = PdfColor.fromHex('FEF3C7');
        fg = PdfColor.fromHex('92400E');
        break;
      case AlertSeverity.info:
        bg = PdfColor.fromHex('DCFCE7');
        fg = PdfColor.fromHex('166534');
        break;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            status.toUpperCase(),
            style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: fg),
          ),
        ),
      ),
    );
  }

  static String _escapeCsv(String val) {
    return val.replaceAll('"', '""');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalert/models/alert_item.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';

void main() {
  group('AlertItem.compareNewestFirst', () {
    test('sorts by timestamp descending when timestamps are present', () {
      final oldAlert = AlertItem(
        id: 'alert_patientZ_1',
        patientId: 'patientZ',
        patientName: 'Patient Z',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'Warning',
        message: 'Old alert',
        timeString: '10:00',
        timestamp: 1000,
      );

      final newAlert = AlertItem(
        id: 'alert_patientA_1',
        patientId: 'patientA',
        patientName: 'Patient A',
        chairLocation: 'Chair 2',
        wardArea: 'Station 2',
        severity: AlertSeverity.critical,
        title: 'Critical',
        message: 'New alert',
        timeString: '10:05',
        timestamp: 2000,
      );

      final list = [oldAlert, newAlert]..sort(AlertItem.compareNewestFirst);

      // Newest alert (timestamp 2000) should be first, even though 'alert_patientZ' > 'alert_patientA'
      expect(list.first.id, equals('alert_patientA_1'));
      expect(list.last.id, equals('alert_patientZ_1'));
    });

    test('device route alert with newer timestamp precedes older web alert', () {
      final olderWebAlert = AlertItem(
        id: '-P9999999999',
        patientId: 'patient1',
        patientName: 'Patient 1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'Warning',
        message: 'Web alert',
        timeString: '09:00',
        timestamp: 1789000000,
      );

      final newerDeviceAlert = AlertItem(
        id: 'alert_patient1_slot1',
        patientId: 'patient1',
        patientName: 'Patient 1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.critical,
        title: 'Critical',
        message: 'Device alert',
        timeString: '10:00',
        timestamp: 1790000000,
      );

      final list = [olderWebAlert, newerDeviceAlert]..sort(AlertItem.compareNewestFirst);

      expect(list.first.id, equals('alert_patient1_slot1'));
      expect(list.last.id, equals('-P9999999999'));
    });

    test('newer web alert precedes older device alert', () {
      final olderDeviceAlert = AlertItem(
        id: 'alert_patient1_slot1',
        patientId: 'patient1',
        patientName: 'Patient 1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.warning,
        title: 'Warning',
        message: 'Device alert',
        timeString: '09:00',
        timestamp: 1789000000,
      );

      final newerWebAlert = AlertItem(
        id: '-P1111111111',
        patientId: 'patient2',
        patientName: 'Patient 2',
        chairLocation: 'Chair 2',
        wardArea: 'Station 2',
        severity: AlertSeverity.critical,
        title: 'Critical',
        message: 'Web alert',
        timeString: '10:00',
        timestamp: 1790000000,
      );

      // In old key sort, 'alert_...' > '-P...' so older device alert would have been first!
      final list = [olderDeviceAlert, newerWebAlert]..sort(AlertItem.compareNewestFirst);

      expect(list.first.id, equals('-P1111111111'));
      expect(list.last.id, equals('alert_patient1_slot1'));
    });

    test('falls back to key descending if timestamps are equal', () {
      final alert1 = AlertItem(
        id: 'alert_aaa',
        patientId: 'p1',
        patientName: 'P1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: 1500,
      );

      final alert2 = AlertItem(
        id: 'alert_zzz',
        patientId: 'p2',
        patientName: 'P2',
        chairLocation: 'Chair 2',
        wardArea: 'Station 2',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: 1500,
      );

      final list = [alert1, alert2]..sort(AlertItem.compareNewestFirst);

      // When timestamps are equal, falls back to key descending ('alert_zzz' > 'alert_aaa')
      expect(list.first.id, equals('alert_zzz'));
      expect(list.last.id, equals('alert_aaa'));
    });

    test('falls back to key descending if timestamps are missing', () {
      final alert1 = AlertItem(
        id: 'alert_aaa',
        patientId: 'p1',
        patientName: 'P1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: null,
      );

      final alert2 = AlertItem(
        id: 'alert_zzz',
        patientId: 'p2',
        patientName: 'P2',
        chairLocation: 'Chair 2',
        wardArea: 'Station 2',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: null,
      );

      final list = [alert1, alert2]..sort(AlertItem.compareNewestFirst);

      // Missing timestamps fall back to key descending
      expect(list.first.id, equals('alert_zzz'));
      expect(list.last.id, equals('alert_aaa'));
    });

    test('alert with timestamp precedes alert missing timestamp', () {
      final noTs = AlertItem(
        id: 'alert_zzz',
        patientId: 'p1',
        patientName: 'P1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: null,
      );

      final hasTs = AlertItem(
        id: 'alert_aaa',
        patientId: 'p2',
        patientName: 'P2',
        chairLocation: 'Chair 2',
        wardArea: 'Station 2',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: 100,
      );

      final list = [noTs, hasTs]..sort(AlertItem.compareNewestFirst);

      expect(list.first.id, equals('alert_aaa'));
      expect(list.last.id, equals('alert_zzz'));
    });

    test('normalizes seconds and milliseconds seamlessly', () {
      final alertSeconds = AlertItem(
        id: 'alert_sec',
        patientId: 'p1',
        patientName: 'P1',
        chairLocation: 'Chair 1',
        wardArea: 'Station 1',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: 1790000000, // 10 digits: seconds
      );

      final alertMillis = AlertItem(
        id: 'alert_ms',
        patientId: 'p2',
        patientName: 'P2',
        chairLocation: 'Chair 2',
        wardArea: 'Station 2',
        severity: AlertSeverity.info,
        title: 'Info',
        message: 'Msg',
        timeString: '10:00',
        timestamp: 1790000001000, // 13 digits: milliseconds (1 second later)
      );

      final list = [alertSeconds, alertMillis]..sort(AlertItem.compareNewestFirst);

      expect(list.first.id, equals('alert_ms'));
      expect(list.last.id, equals('alert_sec'));
    });
  });

  group('FirebaseRealtimeService._parseAlerts', () {
    test('parses and sorts alert map correctly by timestamp', () {
      final service = FirebaseRealtimeService();
      final alertsRaw = <String, dynamic>{
        'alert_patientZ_1': {
          'patient_id': 'patientZ',
          'patient_name': 'Patient Z',
          'severity': 'Warning',
          'status': 'Active',
          'timestamp': 1789900000,
          'message': 'Older alert',
        },
        'alert_patientA_1': {
          'patient_id': 'patientA',
          'patient_name': 'Patient A',
          'severity': 'Critical',
          'status': 'Active',
          'timestamp': 1790000000,
          'message': 'Newer alert',
        },
        '-P12345678': {
          'patient_id': 'patientB',
          'patient_name': 'Patient B',
          'severity': 'Info',
          'status': 'Active',
          // Timestamp missing in this one
          'message': 'Legacy alert without timestamp',
        },
      };

      final parsed = service.parseAlertsForTesting(alertsRaw);

      expect(parsed.length, equals(3));
      // First must be the newer alert (timestamp 1790000000)
      expect(parsed[0].id, equals('alert_patientA_1'));
      // Second must be the older alert (timestamp 1789900000)
      expect(parsed[1].id, equals('alert_patientZ_1'));
      // Third must be the alert without timestamp
      expect(parsed[2].id, equals('-P12345678'));

      service.dispose();
    });

    test('correctly parses String timestamps (numeric and ISO)', () {
      final alertFromNumStr = AlertItem.fromMap('id1', {
        'timestamp': '1790000000',
      });
      expect(alertFromNumStr.timestamp, equals(1790000000));

      final alertFromIso = AlertItem.fromMap('id2', {
        'timestamp': '2026-10-13T02:00:00Z',
      });
      expect(alertFromIso.timestamp, isNotNull);
      expect(alertFromIso.timestamp, greaterThan(1700000000));
    });

    test('uses stored chair value directly without duplicating "Chair"', () {
      final alert = AlertItem.fromMap('id1', {
        'chair': 'Chair 2',
        'station': 'Station 1',
        'patient_name': 'Carlos Mendoza',
      });

      // Must be 'Chair 2', NOT 'Chair Chair 2'
      expect(alert.chairLocation, equals('Chair 2'));
      expect(alert.wardArea, equals('Station 1'));
      expect(alert.patientName, equals('Carlos Mendoza'));
    });

    test('shows "Unknown" rather than invented placeholders when fields are missing', () {
      final alert = AlertItem.fromMap('id2', <String, dynamic>{});

      // Missing fields must show 'Unknown' instead of 'Jane Doe', 'Station 2', or 'Chair 2'
      expect(alert.chairLocation, equals('Unknown'));
      expect(alert.patientName, equals('Unknown'));
      expect(alert.wardArea, equals('Unknown'));
    });
  });
}

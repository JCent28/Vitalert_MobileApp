import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalert/services/firebase_realtime_service.dart';
import 'package:vitalert/services/session_storage_service.dart';
import 'package:vitalert/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M1 (P0) Staff Authentication - BCrypt Hashing, Status & Role Validation', () {
    late FirebaseRealtimeService service;

    // PHP-style $2y$ prefix hash
    final phpStyleHash = r'$2y$12$MrnUVFCTBQgWYxrmweugMuRC36vRubd4mAPuT3QHLmffDUjjRto7m'; // password: '123'

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FirebaseRealtimeService();
    });

    test('authenticateStaff succeeds with valid bcrypt hash and active status', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/HN-00312.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'HN-00312',
              'name': 'Clark Kent',
              'role': 'Head Nurse',
              'status': 'Active',
              'password': phpStyleHash,
              'created_at': '2026-08-20 12:38:30',
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'HN-00312',
        password: '123',
        selectedRole: 'Head Nurse (Shift Lead)',
        client: mockClient,
      );

      expect(user, isNotNull);
      expect(user!.staffId, equals('HN-00312'));
      expect(user.name, equals('Clark Kent'));
      expect(user.role, equals('Head Nurse'));
      expect(user.status, equals('Active'));
      expect(user.isHeadNurse, isTrue);
      expect(user.isActive, isTrue);
      expect(service.lastAuthError, isNull);
    });

    test('authenticateStaff rejects invalid password against bcrypt hash', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/HN-00312.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'HN-00312',
              'name': 'Clark Kent',
              'role': 'Head Nurse',
              'status': 'Active',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'HN-00312',
        password: 'wrong_password',
        selectedRole: 'Head Nurse (Shift Lead)',
        client: mockClient,
      );

      expect(user, isNull);
      expect(service.lastAuthError, contains('Invalid password'));
    });

    test('authenticateStaff rejects deactivated account even with correct password', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/SN-00999.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'SN-00999',
              'name': 'Inactive Nurse',
              'role': 'Staff Nurse',
              'status': 'Inactive',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'SN-00999',
        password: '123',
        selectedRole: 'Staff Nurse',
        client: mockClient,
      );

      expect(user, isNull);
      expect(service.lastAuthError, contains('Account is deactivated'));
    });

    test('authenticateStaff rejects Deactivated status case-insensitively', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/SN-00888.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'SN-00888',
              'name': 'Deactivated Nurse',
              'role': 'Staff Nurse',
              'status': 'Deactivated',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'SN-00888',
        password: '123',
        selectedRole: 'Staff Nurse',
        client: mockClient,
      );

      expect(user, isNull);
      expect(service.lastAuthError, contains('Account is deactivated'));
    });

    test('authenticateStaff rejects role mismatch when Staff Nurse selects Head Nurse', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/SN-00123.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'SN-00123',
              'name': 'Hal Jordan',
              'role': 'Staff Nurse',
              'status': 'Active',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'SN-00123',
        password: '123',
        selectedRole: 'Head Nurse (Shift Lead)',
        client: mockClient,
      );

      expect(user, isNull);
      expect(service.lastAuthError, contains('Role mismatch'));
      expect(service.lastAuthError, contains('Staff Nurse'));
    });

    test('authenticateStaff rejects unauthorized non-clinical roles', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/GU-00001.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'GU-00001',
              'name': 'Guest User',
              'role': 'Guest',
              'status': 'Active',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'GU-00001',
        password: '123',
        client: mockClient,
      );

      expect(user, isNull);
      expect(service.lastAuthError, contains('Unauthorized role'));
    });

    test('authenticateStaff allows Admin supervisory access with any clinical role', () async {
      final adminHash = BCrypt.hashpw('adminpass', BCrypt.gensalt());
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/AM-00777.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'AM-00777',
              'name': 'Bruce Wayne',
              'role': 'Admin',
              'status': 'Active',
              'password': adminHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final user = await service.authenticateStaff(
        staffId: 'AM-00777',
        password: 'adminpass',
        selectedRole: 'Head Nurse (Shift Lead)',
        client: mockClient,
      );

      expect(user, isNotNull);
      expect(user!.role, equals('Admin'));
      expect(user.isAdmin, isTrue);
    });

    test('AppState.signInWithFirebase persists session and sets currentUser on success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/HN-00312.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'HN-00312',
              'name': 'Clark Kent',
              'role': 'Head Nurse',
              'status': 'Active',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final state = AppState();
      final success = await state.signInWithFirebase(
        'HN-00312',
        '123',
        selectedRole: 'Head Nurse (Shift Lead)',
        client: mockClient,
      );

      expect(success, isTrue);
      expect(state.isLoggedIn, isTrue);
      expect(state.currentUser?.staffId, equals('HN-00312'));
      expect(state.currentUser?.name, equals('Clark Kent'));
      expect(state.lastAuthError, isNull);

      final saved = await SessionStorageService.loadSession();
      expect(saved, isNotNull);
      expect(saved!['staffId'], equals('HN-00312'));
      expect(saved['status'], equals('Active'));
    });

    test('AppState.signInWithFirebase exposes lastAuthError when deactivated nurse attempts login', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/SN-00999.json')) {
          return http.Response(
            jsonEncode({
              'staff_id': 'SN-00999',
              'name': 'Disabled Nurse',
              'role': 'Staff Nurse',
              'status': 'Inactive',
              'password': phpStyleHash,
            }),
            200,
          );
        }
        return http.Response('null', 404);
      });

      final state = AppState();
      final success = await state.signInWithFirebase(
        'SN-00999',
        '123',
        selectedRole: 'Staff Nurse',
        client: mockClient,
      );

      expect(success, isFalse);
      expect(state.isLoggedIn, isFalse);
      expect(state.lastAuthError, contains('Account is deactivated'));
    });
  });
}

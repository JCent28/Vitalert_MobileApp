import 'package:shared_preferences/shared_preferences.dart';

/// Persists the logged-in nurse's session to local storage so that
/// the app can restore the session automatically after a restart.
class SessionStorageService {
  static const _keyIsLoggedIn = 'vitalert_is_logged_in';
  static const _keyStaffId = 'vitalert_staff_id';
  static const _keyName = 'vitalert_staff_name';
  static const _keyRole = 'vitalert_staff_role';
  static const _keyStatus = 'vitalert_staff_status';

  /// Writes the authenticated user's data to shared_preferences.
  /// Called after a successful Firebase login.
  static Future<void> saveSession({
    required String staffId,
    required String name,
    required String role,
    String status = 'Active',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyStaffId, staffId);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyStatus, status);
  }

  /// Reads the session from disk on app startup or background service poll.
  /// Returns a map of user fields, or null if no saved session exists.
  static Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {}
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final staffId = prefs.getString(_keyStaffId) ?? '';
    final name = prefs.getString(_keyName) ?? '';
    final role = prefs.getString(_keyRole) ?? '';
    final status = prefs.getString(_keyStatus) ?? 'Active';

    // Treat an empty staffId as no valid session
    if (staffId.isEmpty) return null;

    return {
      'staffId': staffId,
      'name': name,
      'role': role,
      'status': status,
    };
  }

  /// Removes all session data from disk.
  /// Called when the nurse explicitly logs out.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyStaffId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyStatus);
  }
}

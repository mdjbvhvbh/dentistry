import 'package:shared_preferences/shared_preferences.dart';

enum AdminRole { owner, admin, none }

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  AdminRole _currentRole = AdminRole.none;
  DateTime? _sessionStart;
  static const int _sessionTimeoutMinutes = 30;

  AdminRole get currentRole => _currentRole;
  bool get isLoggedIn => _currentRole != AdminRole.none;
  bool get isOwner => _currentRole == AdminRole.owner;
  bool get isAdmin =>
      _currentRole == AdminRole.admin || _currentRole == AdminRole.owner;

  bool get isSessionValid {
    if (_sessionStart == null) return false;
    final elapsed = DateTime.now().difference(_sessionStart!).inMinutes;
    return elapsed < _sessionTimeoutMinutes;
  }

  void refreshSession() {
    if (isLoggedIn) _sessionStart = DateTime.now();
  }

  Future<AdminRole?> login(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final ownerPass = prefs.getString('owner_password') ?? 'Owner@2026';
    final adminPass = prefs.getString('admin_password') ?? 'Admin@2026';

    if (password == ownerPass) {
      _currentRole = AdminRole.owner;
      _sessionStart = DateTime.now();
      return AdminRole.owner;
    } else if (password == adminPass) {
      _currentRole = AdminRole.admin;
      _sessionStart = DateTime.now();
      return AdminRole.admin;
    }
    return null;
  }

  void logout() {
    _currentRole = AdminRole.none;
    _sessionStart = null;
  }

  Future<bool> changeOwnerPassword(String newPassword) async {
    if (!isOwner) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owner_password', newPassword);
    return true;
  }

  Future<bool> changeAdminPassword(String newPassword) async {
    if (!isOwner) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_password', newPassword);
    return true;
  }
}

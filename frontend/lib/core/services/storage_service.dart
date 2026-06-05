import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── JWT Tokens ──────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _secure.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _secure.read(key: AppConstants.tokenKey);
  }

  static Future<void> saveAdminToken(String token) async {
    await _secure.write(key: AppConstants.adminTokenKey, value: token);
  }

  static Future<String?> getAdminToken() async {
    return _secure.read(key: AppConstants.adminTokenKey);
  }

  // ── User Data ───────────────────────────────────────────────────────────────

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(AppConstants.userKey, jsonEncode(user));
  }

  static Map<String, dynamic>? getUser() {
    final raw = _prefs.getString(AppConstants.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> setIsAdmin(bool val) async {
    await _prefs.setBool(AppConstants.isAdminKey, val);
  }

  static bool isAdmin() => _prefs.getBool(AppConstants.isAdminKey) ?? false;

  // ── Clear ───────────────────────────────────────────────────────────────────

  static Future<void> clearUser() async {
    await _secure.delete(key: AppConstants.tokenKey);
    await _prefs.remove(AppConstants.userKey);
    await _prefs.remove(AppConstants.isAdminKey);
  }

  static Future<void> clearAdmin() async {
    await _secure.delete(key: AppConstants.adminTokenKey);
    await _prefs.remove(AppConstants.isAdminKey);
  }

  static Future<void> clearAll() async {
    await _secure.deleteAll();
    await _prefs.clear();
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveUserData(Map<String, dynamic> userJson);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> clearAll();
}

class SharedPreferencesAuthLocalDataSource implements AuthLocalDataSource {
  static const String _keyToken = 'swappia_auth_token';
  static const String _keyUserData = 'swappia_auth_user_data';

  final SharedPreferences? _injectedPrefs;

  SharedPreferencesAuthLocalDataSource([this._injectedPrefs]);

  Future<SharedPreferences> get _prefs async =>
      _injectedPrefs ?? await SharedPreferences.getInstance();

  @override
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyToken, token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await _prefs;
    final token = prefs.getString(_keyToken);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token;
  }

  @override
  Future<void> deleteToken() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userJson) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserData, jsonEncode(userJson));
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? _token;
  AppUser? _currentUser;
  bool _initialized = false;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  AppUser? get currentUser => _currentUser;
  bool get isInitialized => _initialized;

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      final userJson = prefs.getString(_keyUser);
      if (userJson != null) {
        _currentUser = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
      if (_token != null) {
        ApiService.instance.setAuthToken(_token);
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> saveAuthData(String token, AppUser user) async {
    _token = token;
    _currentUser = user;
    ApiService.instance.setAuthToken(token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await ApiService.instance.logout();
      }
    } catch (_) {}

    _token = null;
    _currentUser = null;
    ApiService.instance.setAuthToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/core/constants/api_constants.dart';
import 'package:volunteer_app/data/models/user_model.dart';
import 'package:volunteer_app/data/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;
  static const String _userCacheKey = 'cached_current_user';

  AuthRepository(this._apiService);

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userCacheKey);
    if (jsonStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
  }

  Future<UserModel> login(String email, String password) async {
    final res = await _apiService.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });

    final token = res['token'];
    await _apiService.saveToken(token);

    final user = UserModel.fromJson(res['user']);
    await _cacheUser(user);
    return user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'volunteer',
  }) async {
    final res = await _apiService.post(ApiConstants.register, {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });

    final token = res['token'];
    await _apiService.saveToken(token);

    final user = UserModel.fromJson(res['user']);
    await _cacheUser(user);
    return user;
  }

  Future<UserModel?> fetchCurrentProfile() async {
    if (_apiService.authToken == null) return null;
    try {
      final res = await _apiService.get(ApiConstants.me);
      final user = UserModel.fromJson(res['user']);
      await _cacheUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }
}

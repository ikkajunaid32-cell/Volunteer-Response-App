import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_app/data/models/user_model.dart';
import 'package:volunteer_app/data/services/app_database.dart';

class AuthRepository {
  final AppDatabase _db = AppDatabase.instance;
  static const String _userCacheKey = 'cached_current_user';

  AuthRepository();

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
  }

  Future<UserModel> login(String email, String password) async {
    final user = await _db.login(email, password);
    if (user == null) {
      throw Exception('Invalid email or password. Please try again.');
    }
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
    final user = await _db.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
    await _cacheUser(user);
    return user;
  }

  Future<UserModel?> fetchCurrentProfile() async {
    final cached = await getCachedUser();
    if (cached == null) return null;
    final fresh = await _db.getUserById(cached.userId);
    if (fresh != null) {
      await _cacheUser(fresh);
      return fresh;
    }
    return cached;
  }
}

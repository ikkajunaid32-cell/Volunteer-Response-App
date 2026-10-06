import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  // Key for local storage
  static const String _prefBaseUrlKey = 'custom_api_base_url';

  // Default host addresses
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 connects from Android emulator to host machine localhost
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static String _activeBaseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _activeBaseUrl = prefs.getString(_prefBaseUrlKey) ?? defaultBaseUrl;
  }

  static String get baseUrl {
    if (_activeBaseUrl.isEmpty) {
      return defaultBaseUrl;
    }
    return _activeBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    var formatted = newUrl.trim();
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _activeBaseUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefBaseUrlKey, formatted);
  }

  static Future<void> resetBaseUrl() async {
    _activeBaseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefBaseUrlKey);
  }

  // Endpoints
  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';
  static String get me => '$baseUrl/api/auth/me';

  static String get tasks => '$baseUrl/api/tasks';
  static String taskDetails(int taskId) => '$baseUrl/api/tasks/$taskId';

  static String applyTask(int taskId) => '$baseUrl/api/registrations/task/$taskId/apply';
  static String cancelTask(int taskId) => '$baseUrl/api/registrations/task/$taskId/cancel';
  static String get myTasks => '$baseUrl/api/registrations/my-tasks';
  static String taskVolunteers(int taskId) => '$baseUrl/api/registrations/task/$taskId/volunteers';

  static String get upload => '$baseUrl/api/upload';

  // Formatter for relative upload image paths
  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://images.unsplash.com/photo-1547683905-f686c993aae5?auto=format&fit=crop&w=800&q=80';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Relative upload URL e.g. /uploads/xyz.jpg
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$baseUrl$cleanPath';
  }
}

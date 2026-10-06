import 'package:flutter/foundation.dart';
import 'package:volunteer_app/data/models/user_model.dart';
import 'package:volunteer_app/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isVolunteer => _currentUser?.isVolunteer ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthViewModel(this._authRepository);

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cached = await _authRepository.getCachedUser();
      if (cached != null) {
        _currentUser = cached;
        notifyListeners();
        // Background verify
        final refreshed = await _authRepository.fetchCurrentProfile();
        if (refreshed != null) {
          _currentUser = refreshed;
        }
      }
    } catch (_) {
      // Token expired or network issue
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'volunteer',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.clearSession();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

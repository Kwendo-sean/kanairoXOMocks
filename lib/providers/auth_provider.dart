import 'package:flutter/foundation.dart';
import 'package:kanairoxo/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isAuthenticated = await _authService.isLoggedIn();
    notifyListeners();
  }

  Future<void> login(String phoneNumber, String password) async {
    await _authService.login(phoneNumber: phoneNumber, password: password);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}

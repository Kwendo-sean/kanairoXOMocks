import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/models/couple_model.dart';
import 'package:kanairoxo/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  CoupleStatus? _coupleStatus;
  bool _isLoading = false;
  String? _error;

  final StreamController<User?> _userController =
  StreamController<User?>.broadcast();

  // ── Getters ──────────────────────────────────────────────────────────────

  User? get user => _user;
  CoupleStatus? get coupleStatus => _coupleStatus;
  Stream<User?> get userStream => _userController.stream;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Routing helpers — use these in AuthGate / GoRouter redirect
  String get accountType => _user?.accountType ?? 'single';
  bool get isCoupleAccount => _user?.isCoupleAccount ?? false;
  bool get isSingleAccount => _user?.isSingleAccount ?? true;
  bool get isSearchingAccount => _user?.isSearchingAccount ?? false;

  // Couple status helpers
  bool get hasPartner => _coupleStatus != null;
  User? get partner => _coupleStatus?.partner;
  String? get coupleName => _coupleStatus?.coupleName;

  // ── Constructor ───────────────────────────────────────────────────────────

  AuthProvider() {
    _checkLoginStatus();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _setUser(User? user) {
    _user = user;
    _userController.add(user);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ── Auth flow ─────────────────────────────────────────────────────────────

  Future<void> _checkLoginStatus() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // Fetch the real profile so accountType is always accurate on resume
        final profile = await _authService.getProfile();
        _setUser(profile);

        // If user has a couple account, fetch their couple relationship status
        if (profile.isCoupleAccount) {
          _coupleStatus = await _authService.getCoupleStatus();
          notifyListeners(); // notify again after couple status loads
        }
      } else {
        _setUser(null);
      }
    } catch (e) {
      // Token expired or network error — treat as logged out
      await _authService.logout();
      _setUser(null);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String phoneNumber, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      _setUser(response.user); // User is from user_model.dart — no conflict

      // If couple account, fetch relationship status
      if (response.user.isCoupleAccount) {
        _coupleStatus = await _authService.getCoupleStatus();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.register(
        phoneNumber: data['phoneNumber'],
        email: data['email'] ?? '',
        password: data['password'],
        password2: data['password2'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        termsAccepted: data['termsAccepted'],
        privacyPolicyAccepted: data['privacyPolicyAccepted'],
        accountType: data['accountType'] ?? 'single',
        gender: data['gender'],
        dateOfBirth: data['dateOfBirth'],
        partnerFirstName: data['partnerFirstName'],
        partnerLastName: data['partnerLastName'],
        partnerEmail: data['partnerEmail'],
      );
      _setUser(response.user); // Same User type — no conflict

      // If couple account, try to fetch couple status (likely null on first register)
      if (response.user.isCoupleAccount) {
        _coupleStatus = await _authService.getCoupleStatus();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final profile = await _authService.getProfile();
      _setUser(profile);

      // Also refresh couple status if applicable
      if (profile.isCoupleAccount) {
        _coupleStatus = await _authService.getCoupleStatus();
        notifyListeners();
      }
    } catch (e) {
      // Non-fatal — keep existing user state
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _coupleStatus = null;
    _setUser(null);
  }

  @override
  void dispose() {
    _userController.close();
    super.dispose();
  }
}

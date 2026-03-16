import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/models/couple_model.dart';
import 'package:kanairoxo/services/auth_service.dart';
import 'package:kanairoxo/services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  User? _user;
  CoupleStatus? _coupleStatus;
  List<User>? _coupleUsers;
  User? _selectedPartner;
  bool _isLoading = false;
  String? _error;

  final StreamController<User?> _userController =
  StreamController<User?>.broadcast();

  // ── Getters ──────────────────────────────────────────────────────────────

  User? get user => _user;
  CoupleStatus? get coupleStatus => _coupleStatus;
  List<User>? get coupleUsers => _coupleUsers;
  User? get selectedPartner => _selectedPartner;
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
    if (user != null) {
      _notificationService.registerFCMToken();
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setCoupleUser(User user) {
    _selectedPartner = user;
    _user = user;
    notifyListeners();
  }

  // ── Auth flow ─────────────────────────────────────────────────────────────

  Future<void> _checkLoginStatus() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final profile = await _authService.getProfile();

        try {
          // Attempt to fetch couple status to determine the correct account type.
          _coupleUsers = await _authService.getCoupleUsers();

          // If successful, the user is part of a couple. Re-create the user
          // object with the correct account_type to ensure UI consistency.
          final correctedUser = User(
            id: profile.id,
            phoneNumber: profile.phoneNumber,
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName,
            displayName: profile.displayName,
            role: profile.role,
            accountType: 'couple', // Manually correct the account type.
            isVerified: profile.isVerified,
            dateJoined: profile.dateJoined,
            lastActive: profile.lastActive,
            profile: profile.profile,
          );
          _setUser(correctedUser);
        } catch (e) {
          // If fetching couple status fails, it's likely a single user.
          _coupleStatus = null;
          _setUser(profile);
        }

        notifyListeners();
      } else {
        _setUser(null);
      }
    } catch (e) {
      // Token expired or network error — treat as logged out.
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
      await _authService.login(
        phoneNumber: phoneNumber,
        password: password,
      );
      await _checkLoginStatus(); // Fetch full profile after login
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
      DateTime? dateOfBirth = data['dateOfBirth'] != null
          ? DateTime.parse(data['dateOfBirth'])
          : null;

      await _authService.register(
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
        dateOfBirth: dateOfBirth,
        partnerFirstName: data['partnerFirstName'],
        partnerLastName: data['partnerLastName'],
        partnerEmail: data['partnerEmail'],
      );

      // After registration, immediately fetch the complete user profile.
      await _checkLoginStatus();

    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProfile() async {
    if (_user == null) return;
    try {
      final profileData = await _authService.getProfile();
      final updatedUser = User(
        id: _user!.id,
        phoneNumber: _user!.phoneNumber,
        email: profileData.email ?? _user!.email,
        firstName: profileData.firstName ?? _user!.firstName,
        lastName: profileData.lastName ?? _user!.lastName,
        displayName: profileData.displayName ?? _user!.displayName,
        role: _user!.role,
        accountType: _user!.accountType,
        isVerified: profileData.isVerified,
        dateJoined: _user!.dateJoined,
        lastActive: profileData.lastActive,
        profile: profileData.profile,
      );
      _setUser(updatedUser);

      if (updatedUser.isCoupleAccount) {
        _coupleStatus = await _authService.getCoupleStatus();
        notifyListeners();
      }
    } catch (e) {
      // Non-fatal
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _coupleStatus = null;
    _coupleUsers = null;
    _selectedPartner = null;
    _setUser(null);
  }

  @override
  void dispose() {
    _userController.close();
    super.dispose();
  }
}

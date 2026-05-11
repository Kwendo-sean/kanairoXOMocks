import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/models/couple_model.dart';
import 'package:kanairoxo/services/auth_service.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/services/notification_service.dart';
import 'package:kanairoxo/utils/auth_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  User? _user;
  CoupleStatus? _coupleStatus;
  List<User>? _coupleUsers;
  User? _selectedPartner;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

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
  bool get initialized => _initialized;

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
    _init();
  }

  Future<void> _init() async {
    // 1. Load from cache immediately for fast UI response
    final cachedUser = await AuthStorage.getCachedUser();
    if (cachedUser != null) {
      _user = cachedUser;
      _userController.add(cachedUser);
      notifyListeners();
    }
    
    // 2. Verify with server in background
    await _checkLoginStatus();
    _initialized = true;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _setUser(User? user) {
    _user = user;
    _userController.add(user);
    if (user != null) {
      AuthStorage.setCachedUserId(user.id);
      AuthStorage.saveUser(user); // Persist to storage
      _notificationService.registerFCMToken();
    } else {
      AuthStorage.setCachedUserId('');
      AuthStorage.clearAll(); // This will clear cached user too
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
    AuthStorage.setCachedUserId(user.id);
    AuthStorage.saveUser(user);
    notifyListeners();
  }

  // ── Auth flow ─────────────────────────────────────────────────────────────

  Future<void> _checkLoginStatus() async {
    // Only set loading if we don't already have a cached user to show
    if (_user == null) _setLoading(true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        try {
          final profile = await _authService.getProfile();

          try {
            _coupleUsers = await _authService.getCoupleUsers();
            final correctedUser = User(
              id: profile.id,
              phoneNumber: profile.phoneNumber,
              email: profile.email,
              firstName: profile.firstName,
              lastName: profile.lastName,
              displayName: profile.displayName,
              role: profile.role,
              accountType: 'couple',
              isVerified: profile.isVerified,
              dateJoined: profile.dateJoined,
              lastActive: profile.lastActive,
              profile: profile.profile,
              gender: profile.gender,
              dateOfBirth: profile.dateOfBirth,
            );
            _setUser(correctedUser);
          } catch (e) {
            _coupleStatus = null;
            _setUser(profile);
          }
        } catch (e) {
          // If profile fetch fails (e.g. timeout/offline), keep using cached user
          // if we have one. Don't logout unless it's a definitive auth failure.
          if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
             await logout();
          }
        }
      } else {
        // No tokens found at all
        _setUser(null);
      }
    } catch (e) {
      // General error, don't logout unless it's an AuthException
      if (e is AuthException) {
        await logout();
      }
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
      await _checkLoginStatus();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> googleLogin(String idToken) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _authService.googleLogin(idToken);
      await _checkLoginStatus();
      return response.isNewUser;
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
        gender: profileData.gender,
        dateOfBirth: profileData.dateOfBirth,
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

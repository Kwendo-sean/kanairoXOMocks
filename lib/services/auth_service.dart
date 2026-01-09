import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/api_models.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<LoginResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _api.post('auth/login/', {
        'phone_number': phoneNumber,
        'password': password,
      });

      // Save tokens
      await _api.saveTokens(response['access'], response['refresh']);

      return LoginResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<RegisterResponse> register({
    required String phoneNumber,
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
    required bool termsAccepted,
    required bool privacyPolicyAccepted,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      final response = await _api.post('auth/register/', {
        'phone_number': phoneNumber,
        'email': email.isNotEmpty ? email : null,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'password2': password2,
        'terms_accepted': termsAccepted,
        'privacy_policy_accepted': privacyPolicyAccepted,
        'gender': gender,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      });

      // Save tokens
      await _api.saveTokens(response['access'], response['refresh']);

      return RegisterResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _api.getRefreshToken();
      if (refreshToken != null) {
        await _api.post('auth/logout/', {
          'refresh': refreshToken,
        });
      }
    } catch (e) {
      // Even if logout fails on server, clear local tokens
    }
    await _api.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getCurrentToken() async {
    return await _api.getAccessToken();
  }

  Future<void> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    await _api.post('auth/verify-otp/', {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post('auth/password-reset/', {
      'phone_number': phoneNumber,
      'otp': otp,
      'new_password': newPassword,
    });
  }
}

// Response models
class LoginResponse {
  final User user;
  final String access;
  final String refresh;

  LoginResponse({
    required this.user,
    required this.access,
    required this.refresh,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      access: json['access'],
      refresh: json['refresh'],
    );
  }
}

class RegisterResponse {
  final User user;
  final String access;
  final String refresh;

  RegisterResponse({
    required this.user,
    required this.access,
    required this.refresh,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      user: User.fromJson(json['user']),
      access: json['access'],
      refresh: json['refresh'],
    );
  }
}

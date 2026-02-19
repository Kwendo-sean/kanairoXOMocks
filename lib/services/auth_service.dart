import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/models/couple_model.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  String _formatPhoneNumber(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      return '+254${digits.substring(1)}';
    } else if (digits.startsWith('7') && digits.length == 9) {
      return '+254$digits';
    } else if (digits.startsWith('254') && digits.length == 12) {
      return '+$digits';
    }
    return phone;
  }

  Future<LoginResponse> login({
    required String phoneNumber,
    required String password,
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final response = await _api.post('api/v1/auth/login/', {
      'phone_number': formattedPhone,
      'password': password,
    });
    await _api.saveTokens(response['access'], response['refresh']);
    return LoginResponse.fromJson(response);
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
    required String accountType,
    String? gender,
    DateTime? dateOfBirth,
    String? partnerFirstName,
    String? partnerLastName,
    String? partnerEmail,
  }) async {
    final response = await _api.post('api/v1/auth/register/', {
      'phone_number': _formatPhoneNumber(phoneNumber),
      'email': email.isNotEmpty ? email : null,
      'first_name': firstName,
      'last_name': lastName,
      'password': password,
      'password2': password2,
      'terms_accepted': termsAccepted,
      'privacy_policy_accepted': privacyPolicyAccepted,
      'account_type': accountType,
      'gender': gender,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      if (partnerFirstName != null) 'partner_first_name': partnerFirstName,
      if (partnerLastName != null) 'partner_last_name': partnerLastName,
      if (partnerEmail != null) 'partner_email': partnerEmail,
    });
    await _api.saveTokens(response['access'], response['refresh']);
    return RegisterResponse.fromJson(response);
  }

  Future<User> getProfile() async {
    final response = await _api.get('api/v1/auth/profile/');
    return User.fromJson(response);
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _api.getRefreshToken();
      if (refreshToken != null) {
        await _api.post('api/v1/auth/logout/', {'refresh': refreshToken});
      }
    } catch (_) {
      // Even if server logout fails, clear local tokens
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

  /// Fetch the user's couple relationship status (null if no couple exists)
  Future<CoupleStatus?> getCoupleStatus() async {
    try {
      final response = await _api.get('api/v1/couples/my-couple/');
      return CoupleStatus.fromJson(response);
    } catch (e) {
      // 404 or any error means no active couple relationship
      return null;
    }
  }

  Future<void> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    await _api.post('api/v1/auth/verify-otp/', {
      'phone_number': _formatPhoneNumber(phoneNumber),
      'otp': otp,
    });
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    await _api.post('api/v1/auth/password-reset/', {
      'phone_number': _formatPhoneNumber(phoneNumber),
      'otp': otp,
      'new_password': newPassword,
    });
  }
}

// ---------------------------------------------------------------------------
// Response models — live here alongside AuthService, not in api_models.dart
// ---------------------------------------------------------------------------

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
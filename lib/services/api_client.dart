import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  // TODO: Replace with your production HTTPS URL before deploying.
  // Never use a plain http:// URL or a private LAN IP in production.
  static const String baseUrl = 'https://api.kanairoxo.com';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _secureStorage = const FlutterSecureStorage();
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<Map<String, String>> _getHeaders({bool hasToken = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (hasToken) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParameters}) async {
    return _handleRequest(() async {
      final url = Uri.parse('${ApiClient.baseUrl}/$endpoint').replace(queryParameters: queryParameters);
      return http.get(url, headers: await _getHeaders());
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data,
      {bool hasToken = true}) async {
    return _handleRequest(() async {
      final url = Uri.parse('${ApiClient.baseUrl}/$endpoint');
      return http.post(
        url,
        headers: await _getHeaders(hasToken: hasToken),
        body: jsonEncode(data),
      );
    });
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    return _handleRequest(() async {
      final url = Uri.parse('${ApiClient.baseUrl}/$endpoint');
      return http.patch(url, headers: await _getHeaders(), body: jsonEncode(data));
    });
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    return _handleRequest(() async {
      final url = Uri.parse('${ApiClient.baseUrl}/$endpoint');
      final request = http.Request('DELETE', url);
      request.headers.addAll(await _getHeaders());
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<dynamic> uploadMultipleFiles(String endpoint, {required List<XFile> files, required String fileFieldName}) async {
    return _handleRequest(() async {
      final url = Uri.parse('${ApiClient.baseUrl}/$endpoint');
      final request = http.MultipartRequest('POST', url);
      final token = await getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));
      }

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<dynamic> _handleRequest(Future<http.Response> Function() request) async {
    var response = await request();

    if (response.statusCode == 401) {
      if (await _refreshToken()) {
        response = await request(); // Retry the request with the new token
      } else {
        // If refresh fails, throw a specific auth exception to be caught by the UI layer
        throw AuthException('Your session has expired. Please log in again.');
      }
    }

    return _handleResponse(response);
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // Wait for the in-progress refresh and return its actual result.
      return await _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    bool success = false;
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return false; // Can't refresh without a refresh token
      }

      final response = await http.post(
        Uri.parse('${ApiClient.baseUrl}/api/v1/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access'], refreshToken);
        if (kDebugMode) print('✅ Token refreshed successfully');
        success = true;
      } else {
        if (kDebugMode) print('❌ Failed to refresh token');
        await clearTokens();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error during token refresh: $e');
      await clearTokens();
    } finally {
      _isRefreshing = false;
      _refreshCompleter!.complete(success);
    }
    return success;
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _secureStorage.write(key: 'access_token', value: access);
    await _secureStorage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    if (kDebugMode) print('Cleared auth tokens');
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      // Extract a user-friendly message from the backend without leaking
      // raw response bodies or internal stack details.
      String userMessage = _extractUserMessage(response);
      throw Exception(userMessage);
    }
  }

  String _extractUserMessage(http.Response response) {
    if (response.body.isNotEmpty) {
      try {
        final errorData = jsonDecode(response.body);
        // Use the 'detail' field if present — it is a standard DRF field and
        // safe to surface. Avoid exposing full errorData.toString() which may
        // include internal field names or stack traces.
        if (errorData is Map && errorData.containsKey('detail')) {
          final detail = errorData['detail'];
          if (detail is String && detail.isNotEmpty) return detail;
        }
      } catch (_) {
        // JSON parse failure — fall through to generic message.
      }
    }

    switch (response.statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
        return 'A server error occurred. Please try again later.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

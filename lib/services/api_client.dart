import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kanairoxo/utils/constants.dart';

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static String baseUrl = ApiConstants.baseUrl;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _secureStorage = const FlutterSecureStorage();
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

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

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParameters, Map<String, String>? headers}) async {
    return _handleRequest(() async {
      final url = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParameters);
      final mergedHeaders = await _getHeaders();
      if (headers != null) {
        mergedHeaders.addAll(headers);
      }
      return http.get(url, headers: mergedHeaders);
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    return _handleRequest(() async {
      final url = Uri.parse('$baseUrl/$endpoint');
      return http.post(
        url,
        headers: await _getHeaders(hasToken: !endpoint.contains('login')),
        body: jsonEncode(data),
      );
    });
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    return _handleRequest(() async {
      final url = Uri.parse('$baseUrl/$endpoint');
      return http.patch(url, headers: await _getHeaders(), body: jsonEncode(data));
    });
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    return _handleRequest(() async {
      final url = Uri.parse('$baseUrl/$endpoint');
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
      final url = Uri.parse('$baseUrl/$endpoint');
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
      await _refreshCompleter?.future;
      return true; // Assume success if another process is already refreshing
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return false; // Can't refresh without a refresh token
      }

      // Use the full path for token refresh, as it's a specific auth endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/v1/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['access'], refreshToken); // Keep the same refresh token
        if (kDebugMode) print('✅ Token refreshed successfully');
        return true;
      } else {
        if (kDebugMode) print('❌ Failed to refresh token, status: ${response.statusCode}');
        // If refresh fails, clear tokens as they are invalid
        await clearTokens();
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error during token refresh: $e');
      await clearTokens();
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter?.complete();
    }
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
    if (kDebugMode) {
      print('[API] ${response.request?.method} ${response.request?.url} -> ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('[API] Body: ${response.body}');
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'An unknown error occurred';
      if (response.body.isNotEmpty) {
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? errorData.toString();
        } catch (e) {
          errorMessage = response.body;
        }
      }
      throw Exception('Error ${response.statusCode}: $errorMessage');
    }
  }
}

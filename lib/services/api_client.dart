import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // The baseUrl for your API.
  //
  // IMPORTANT: It looks like you're running on a physical device. You need to use your
  // computer's local network IP address here. The address '10.0.2.2' is only
  // for the Android Emulator.
  //
  // To find your computer's IP:
  // - Windows: run `ipconfig` in Command Prompt.
  // - macOS/Linux: run `ifconfig` or `ip addr` in the terminal.
  //
  // Then, replace '10.0.2.2' with your computer's IP address.
  // Example: static const String baseUrl = 'http://192.168.1.10:8000/api/v1';
  static const String baseUrl = 'http://192.168.100.6:8000/api/v1'; // Corrected from 10.0.0.2. Replace with your computer's IP for physical device.

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      url,
      headers: await _getHeaders(hasToken: !endpoint.contains('login')),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

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

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Try to refresh token if we have a refresh token
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        try {
          await _refreshToken();
          // The original request should be retried by the caller.
          // Throwing an exception to signal that a retry might be needed.
          throw Exception('Token refreshed. Please retry the request.');
        } catch (e) {
          await clearTokens();
          throw Exception('Session expired. Please login again.');
        }
      } else {
        await clearTokens();
        throw Exception('Authentication failed. Please login again.');
      }
    } else {
      // Handle other error status codes to provide more context.
      String errorMessage;
      if (response.body.isNotEmpty) {
        try {
          // Try to parse a JSON error from the backend.
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'];
          } else {
            // If it's a map of field errors, format them.
            errorMessage = errorData.toString();
          }
        } catch (e) {
          // If the body is not JSON (e.g., HTML from a server debug page),
          // show the raw body to help with debugging.
          errorMessage = 'The server returned an unexpected error. Response body: \n${response.body}';
        }
      } else {
        errorMessage = response.reasonPhrase ?? 'Unknown network error';
      }
      throw Exception('Error ${response.statusCode}: $errorMessage');
    }
  }

  Future<void> _refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final url = Uri.parse('$baseUrl/auth/token/refresh/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(data['access'], refreshToken);
    } else {
      await clearTokens();
      throw Exception('Failed to refresh token');
    }
  }

  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null) return false;

    final parts = token.split('.');
    return parts.length == 3;
  }
}

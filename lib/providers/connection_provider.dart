// lib/providers/connection_provider.dart
import 'package:flutter/material.dart';
import '../services/connection_service.dart';

class ConnectionProvider with ChangeNotifier {
  final ConnectionService _connectionService = ConnectionService();

  bool _isLoading = false;
  String? _error;
  Map<String, String> _connectionStatus = {}; // userId -> status

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Send connection request
  Future<Map<String, dynamic>> sendConnectionRequest({
    required String receiverId,
    String? message,
    String? intent,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectionService.sendConnectionRequest(
        receiverId: receiverId,
        message: message,
        intent: intent,
      );

      if (result['success'] == true) {
        // Update local status
        _connectionStatus[receiverId] = 'pending_sent';
        notifyListeners();
      }

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Quick connect (for discovery flow)
  Future<Map<String, dynamic>> quickConnect(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectionService.quickConnect(userId);

      if (result['success'] == true) {
        // Update local status
        _connectionStatus[userId] = 'pending_sent';
        notifyListeners();
      }

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check connection status
  Future<Map<String, dynamic>> checkConnectionStatus(String userId) async {
    try {
      final result = await _connectionService.checkConnectionStatus(userId);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;

        // Cache the status
        if (data['exists'] == true) {
          _connectionStatus[userId] = data['connection_type'] ?? 'unknown';
        } else {
          _connectionStatus[userId] = 'none';
        }

        notifyListeners();
      }

      return result;
    } catch (e) {
      print('Error checking connection status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Accept connection request
  Future<Map<String, dynamic>> acceptConnection(String connectionId, {String? message}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectionService.acceptConnection(
        connectionId,
        message: message,
      );

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject connection request
  Future<Map<String, dynamic>> rejectConnection(String connectionId, {String? message}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectionService.rejectConnection(
        connectionId,
        message: message,
      );

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get connection status for a user
  String? getConnectionStatus(String userId) {
    return _connectionStatus[userId];
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
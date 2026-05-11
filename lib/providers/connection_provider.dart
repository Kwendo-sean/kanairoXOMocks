// lib/providers/connection_provider.dart
import 'package:flutter/material.dart';
import '../services/connection_service.dart';

class ConnectionProvider with ChangeNotifier {
  final ConnectionService _connectionService = ConnectionService();

  bool _isLoading = false;
  String? _error;
  
  // Cache for connection statuses
  final Map<String, String> _statuses = {}; // userId -> status string ('mutual', 'pending', 'none')
  final Map<String, bool> _initiators = {}; // userId -> bool

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Global getters for user status
  String getConnectionStatus(String userId) => _statuses[userId] ?? 'none';
  bool isInitiator(String userId) => _initiators[userId] ?? false;

  Future<Map<String, dynamic>> checkConnectionStatus(String userId) async {
    try {
      final result = await _connectionService.checkConnectionStatus(userId);
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (data['exists'] == true) {
          _statuses[userId] = data['connection_type'] ?? 'none';
          _initiators[userId] = data['is_initiator'] ?? false;
        } else {
          _statuses[userId] = 'none';
          _initiators[userId] = false;
        }
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> quickConnect(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _connectionService.quickConnect(userId);
      
      // Handle the "already connected" case as a success state for UI
      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map && (data['status'] == 'already_connected' || data['connection_status'] == 'connected')) {
          _statuses[userId] = 'mutual';
        } else {
          _statuses[userId] = 'pending';
          _initiators[userId] = true;
        }
      } else if (result['status'] == 'already_connected' || (result['error']?.toString().contains('already connected') ?? false)) {
        _statuses[userId] = 'mutual';
        // Overwrite failure to success for UI flow
        return {'success': true, 'data': {'status': 'already_connected'}};
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> acceptConnection(String connectionId, {String? targetUserId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _connectionService.acceptConnection(connectionId);
      if (result['success'] == true && targetUserId != null) {
        _statuses[targetUserId] = 'mutual';
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> rejectConnection(String connectionId, {String? targetUserId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _connectionService.rejectConnection(connectionId);
      if (result['success'] == true && targetUserId != null) {
        _statuses[targetUserId] = 'none';
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
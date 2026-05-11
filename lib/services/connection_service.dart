// lib/services/connection_service.dart
import 'api_client.dart';

class ConnectionService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> sendConnectionRequest({
    required String receiverId,
    String? message,
    String? intent,
  }) async {
    try {
      final response = await _apiClient.post(
        'api/v1/connections/send-request/',
        {
          'receiver_id': receiverId,
          'message': message,
          'intent': intent,
        },
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('Error sending connection request: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> quickConnect(String userId) async {
    try {
      final response = await _apiClient.post(
        'api/v1/connections/quick-connect/$userId/',
        {},
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('Error in quick connect: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> checkConnectionStatus(String userId) async {
    try {
      final response = await _apiClient.get(
        'api/v1/connections/check-status/$userId/',
      );

      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('Error checking connection status: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> acceptConnection(String connectionId, {String? message}) async {
  try {
    print('Accepting connection: $connectionId');
    final response = await _apiClient.post(
      'api/v1/connections/$connectionId/accept/',
      {'message': message},
    );
    
    print('Accept response: $response');
    
    return {
      'success': true,
      'data': response,
    };
  } catch (e) {
    print('Error accepting connection: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

Future<Map<String, dynamic>> rejectConnection(String connectionId, {String? message}) async {
  try {
    print('Rejecting connection: $connectionId');
    final response = await _apiClient.post(
      'api/v1/connections/$connectionId/reject/',
      {'message': message},
    );
    
    print('Reject response: $response');
    
    return {
      'success': true,
      'data': response,
    };
  } catch (e) {
    print('Error rejecting connection: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

  Future<Map<String, dynamic>> getMyConnections() async {
    try {
      final response = await _apiClient.get('api/v1/connections/');
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('Error getting connections: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getPendingRequests() async {
    try {
      final response = await _apiClient.get('api/v1/connections/pending/');
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('Error getting pending requests: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteConnection(String connectionId) async {
    try {
      await _apiClient.delete('api/v1/connections/$connectionId/');
      return {
        'success': true,
      };
    } catch (e) {
      print('Error deleting connection: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

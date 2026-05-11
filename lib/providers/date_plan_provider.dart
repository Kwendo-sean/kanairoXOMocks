import 'package:flutter/material.dart';
import '../models/date_plan_model.dart';
import '../models/date_request_model.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

class DatePlanProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  DatePlan _currentPlan = DatePlan();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _currentUserId;
  
  List<DateConnection> _connections = [];
  List<Venue> _venues = [];
  List<DatePackage> _packages = [];
  DateConfig? _config;
  DateReceipt? _lastReceipt;

  List<DateRequestModel> _receivedRequests = [];
  List<DateRequestModel> _sentRequests = [];
  int _pendingCount = 0;
  
  DatePlan get currentPlan => _currentPlan;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  List<DateConnection> get connections => _connections;
  List<Venue> get venues => _venues;
  List<DatePackage> get packages => _packages;
  DateConfig? get config => _config;
  DateReceipt? get lastReceipt => _lastReceipt;
  String? get currentUserId => _currentUserId;

  List<DateRequestModel> get receivedRequests => _receivedRequests;
  List<DateRequestModel> get sentRequests => _sentRequests;
  int get pendingCount => _pendingCount;

  void update(AuthProvider auth) {
    _currentUserId = auth.user?.id;
    if (auth.isAuthenticated) {
      fetchRequests();
      fetchConfig();
    }
  }

  void nextStep() {
    if (_currentStep < 5) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void updatePlan({
    String? personId,
    String? personName,
    String? personPhoto,
    DateTime? preferredDate,
    String? message,
    String? vibe,
    Venue? venue,
    DatePackage? package,
    double? budget,
  }) {
    if (personId != null) _currentPlan.personId = personId;
    if (personName != null) _currentPlan.personName = personName;
    if (personPhoto != null) _currentPlan.personPhoto = personPhoto;
    if (preferredDate != null) _currentPlan.preferredDate = preferredDate;
    if (message != null) _currentPlan.message = message;
    if (vibe != null) _currentPlan.vibe = vibe;
    if (venue != null) _currentPlan.selectedVenue = venue;
    if (package != null) _currentPlan.selectedPackage = package;
    if (budget != null) _currentPlan.budget = budget;
    notifyListeners();
  }

  Future<void> fetchConfig() async {
    try {
      final response = await _apiClient.get('api/v1/date-planning/config/');
      _config = DateConfig.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching date config: $e');
      _config = DateConfig(commissionRate: 0.1, reservationFee: 500);
    }
  }

  Future<void> fetchConnections() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('api/v1/connections/');
      final list = response is List ? response : (response['results'] as List? ?? []);
      _connections = list.map((e) => DateConnection.fromJson(e, currentUserId: _currentUserId)).toList();
    } catch (e) {
      debugPrint('Error fetching connections: $e');
      _connections = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVenues(String? vibe) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('api/v1/venues/', queryParameters: {'vibe': vibe?.toLowerCase() ?? ''});
      final list = response is List ? response : (response['results'] as List? ?? []);
      _venues = list.map((e) => Venue.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching venues: $e');
      _venues = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPackages(String venueId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('api/v1/date-planning/venues/$venueId/packages/');
      final list = response is List ? response : (response['results'] as List? ?? []);
      _packages = list.map((e) => DatePackage.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching packages: $e');
      _packages = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('api/v1/date-planning/requests/');
      
      final sentList = response['sent'] as List?;
      if (sentList != null) {
        _sentRequests = sentList
            .map((json) => DateRequestModel.fromJson(json))
            .toList();
      }

      final receivedList = response['received'] as List?;
      if (receivedList != null) {
        _receivedRequests = receivedList
            .map((json) => DateRequestModel.fromJson(json))
            .toList();
      }
      
      _pendingCount = _receivedRequests.where((r) => r.status == 'pending').length;
    } catch (e) {
      debugPrint('Error fetching date requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> respondToRequest(String requestId, String action) async {
    try {
      await _apiClient.patch('api/v1/date-planning/requests/$requestId/respond/', {'action': action});
      await fetchRequests();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> payForRequest(String requestId, String phoneNumber, int amount) async {
    try {
      await _apiClient.post('api/v1/date-planning/requests/$requestId/pay/', {
        'phone': phoneNumber,
        'amount': amount,
      });
      await fetchRequests();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendDateRequest() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiClient.post('api/v1/date-planning/requests/', _currentPlan.toJson());
      _isLoading = false;
      await fetchRequests();
      return true;
    } catch (e) {
      debugPrint('Error sending date request: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _currentPlan = DatePlan();
    _currentStep = 0;
    _lastReceipt = null;
    notifyListeners();
  }
}

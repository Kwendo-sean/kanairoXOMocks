import 'package:flutter/material.dart';
import '../models/moment.dart';
import '../services/moment_service.dart';
import 'auth_provider.dart';

class MomentProvider with ChangeNotifier {
  final MomentService _momentService = MomentService();
  
  List<Moment> _moments = [];
  List<Moment> _savedMoments = [];
  bool _isLoading = false;
  bool _isSavedLoading = false;
  String? _error;

  List<Moment> get moments => _moments;
  List<Moment> get savedMoments => _savedMoments;
  bool get isLoading => _isLoading;
  bool get isSavedLoading => _isSavedLoading;
  String? get error => _error;

  void update(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      _moments = [];
      _savedMoments = [];
      _error = null;
      notifyListeners();
    } else {
      // Prefetch data when authenticated
      prefetch();
    }
  }

  Future<void> prefetch() async {
    // Fire and forget fetches to populate cache
    fetchMoments();
    fetchSavedMoments();
  }

  Future<void> fetchMoments({String? type, bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final fetched = await _momentService.getMoments(type: type);
      _moments = fetched;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSavedMoments({bool refresh = false}) async {
    if (_isSavedLoading && !refresh) return;
    
    _isSavedLoading = true;
    notifyListeners();

    try {
      // Since MomentService doesn't have getSavedMoments, we use the logic from the screen
      // or we should ideally add it to MomentService.
      // For now, let's assume we'll update MomentService or call the API directly via a helper
      final response = await _momentService.getSavedMoments();
      _savedMoments = response;
    } catch (e) {
      debugPrint('Error fetching saved moments: $e');
    } finally {
      _isSavedLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave(Moment moment) async {
    try {
      // Optimistic UI update
      final isSaved = moment.isSavedByMe;
      if (isSaved) {
        _savedMoments.removeWhere((m) => m.id == moment.id);
      } else {
        _savedMoments.insert(0, moment);
      }
      notifyListeners();
      
      // Call API (Add this to MomentService if not exists)
      // await _momentService.toggleSave(moment.id);
      
    } catch (e) {
      // Revert on error if needed
      fetchSavedMoments(refresh: true);
    }
  }
}

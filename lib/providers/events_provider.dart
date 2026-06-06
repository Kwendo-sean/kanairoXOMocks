import 'dart:async';
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../services/events_api_service.dart';
import './auth_provider.dart';

class EventsProvider with ChangeNotifier {
  final EventsApiService _eventsApiService = EventsApiService();
  
  Map<String, List<Experience>> _feed = {};
  List<Experience> _searchResults = [];
  List<Experience> _savedEvents = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSavedLoading = false;
  String? _error;
  Timer? _searchDebounce;

  Map<String, List<Experience>> get feed => _feed;
  List<Experience> get searchResults => _searchResults;
  List<Experience> get savedEvents => _savedEvents;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isSavedLoading => _isSavedLoading;
  String? get error => _error;

  void update(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      _feed = {};
      _savedEvents = [];
      notifyListeners();
    } else {
      if (_feed.isEmpty && !_isLoading) {
        fetchFeed();
      }
    }
  }

  Future<void> fetchFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feed = await _eventsApiService.fetchEventFeed();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ITEM 2: Wire search TextField onChanged → debounce 300ms → call this endpoint
  Future<void> search(String query) async {
    _searchDebounce?.cancel();
    
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        _searchResults = await _eventsApiService.searchEvents(query);
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchSavedEvents() async {
    _isSavedLoading = true;
    notifyListeners();

    try {
      _savedEvents = await _eventsApiService.fetchSavedEvents();
    } catch (e) {
      debugPrint('Error fetching saved events: $e');
    } finally {
      _isSavedLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSave(Experience event) async {
    // Optimistic Update
    final originalStatus = event.isSaved;
    final originalCount = event.savesCount;
    
    _updateEventSaveStatus(event.id, !originalStatus, 
      newCount: !originalStatus ? originalCount + 1 : (originalCount > 0 ? originalCount - 1 : 0));
    
    try {
      final response = await _eventsApiService.toggleSave(event.id);
      final newStatus = response['status'] == 'saved';
      final newCountFromApi = response['saves_count'];
      
      if (newStatus != !originalStatus || (newCountFromApi != null && newCountFromApi != event.savesCount)) {
        _updateEventSaveStatus(event.id, newStatus, newCount: newCountFromApi);
      }
    } catch (e) {
      // Revert on error
      _updateEventSaveStatus(event.id, originalStatus, newCount: originalCount);
      debugPrint('Toggle save error: $e');
    }
  }

  void _updateEventSaveStatus(String id, bool isSaved, {int? newCount}) {
    // Update in feed
    _feed.forEach((key, list) {
      final index = list.indexWhere((e) => e.id == id);
      if (index != -1) {
        list[index] = list[index].copyWith(
          isSaved: isSaved,
          savesCount: newCount ?? list[index].savesCount,
        );
      }
    });

    // Update in search results
    final searchIndex = _searchResults.indexWhere((e) => e.id == id);
    if (searchIndex != -1) {
      _searchResults[searchIndex] = _searchResults[searchIndex].copyWith(
        isSaved: isSaved,
        savesCount: newCount ?? _searchResults[searchIndex].savesCount,
      );
    }

    // Update in saved events list
    if (isSaved) {
      final existingIndex = _savedEvents.indexWhere((e) => e.id == id);
      if (existingIndex == -1) {
        Experience? found;
        _feed.values.forEach((list) {
          final matchIndex = list.indexWhere((e) => e.id == id);
          if (matchIndex != -1) found = list[matchIndex];
        });
        if (found != null) {
          _savedEvents.insert(0, found!.copyWith(isSaved: true, savesCount: newCount ?? found!.savesCount));
        }
      } else {
        _savedEvents[existingIndex] = _savedEvents[existingIndex].copyWith(
          isSaved: true,
          savesCount: newCount ?? _savedEvents[existingIndex].savesCount,
        );
      }
    } else {
      _savedEvents.removeWhere((e) => e.id == id);
    }
    
    notifyListeners();
  }

  Future<Experience> fetchExperienceDetail(String id) async {
    return await _eventsApiService.fetchExperienceDetail(id);
  }
}

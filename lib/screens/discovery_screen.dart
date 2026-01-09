// lib/screens/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/services/discovery_service.dart';
import 'package:kanairoxo/widgets/profile_card.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();
  final PageController _pageController = PageController();

  DiscoverySession? _currentSession;
  List<DiscoveryItem> _discoveries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  BatchInfo? _batchInfo;

  // Stats
  int _remainingToday = 50;
  int _connectionsMade = 0;
  double _averageScore = 0.0;

  // For swipe gestures
  double _dragStartX = 0.0;
  bool _showLeftIcon = false;
  bool _showRightIcon = false;
  double _iconOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDiscovery();
    _loadStats();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeDiscovery() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Start a new session or continue existing one
      if (_currentSession == null) {
        try {
          final session = await _discoveryService.startDiscoverySession();
          setState(() {
            _currentSession = session;
          });
        } catch (e) {
          print('Error starting session: $e');
          // Try to get existing active sessions
          try {
            final sessions = await _discoveryService.getMySessions();
            final activeSessions = sessions.where((s) => s.isActive).toList();

            if (activeSessions.isNotEmpty) {
              setState(() {
                _currentSession = activeSessions.first;
              });
            } else {
              throw Exception('Could not start or find a discovery session. Please try again.');
            }
          } catch (e2) {
            throw Exception('Failed to start discovery: ${e2.toString()}');
          }
        }
      }

      // Get discovery batch
      if (_currentSession != null) {
        try {
          final batch = await _discoveryService.getDiscoveryBatch(
            _currentSession!.sessionId,
            batchSize: 10,
          );

          setState(() {
            _discoveries = batch.discoveries;
            _batchInfo = batch.batchInfo;
            _remainingToday = _batchInfo?.remainingToday ?? 50;
            _currentIndex = 0;
            _isLoading = false;
          });

          // Reset page controller if needed
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }

        } catch (e) {
          print('Error getting batch: $e');
          setState(() {
            _error = 'Failed to load discoveries: ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _discoveryService.getStats(days: 7);
      setState(() {
        _connectionsMade = stats['connections_made'] ?? 0;
        _averageScore = (stats['average_score'] ?? 0).toDouble();
      });
    } catch (e) {
      // Silently fail, stats are not critical
      print('Error loading stats: $e');
    }
  }

  Future<void> _handleConnect() async {
    if (_currentIndex >= _discoveries.length) return;

    final currentItem = _discoveries[_currentIndex];

    try {
      await _discoveryService.recordUserAction(
        currentItem.id,
        'connect',
        rating: 5.0,
        context: {'action_source': 'discovery_screen'},
      );

      // Move to next profile
      _moveToNextProfile();

      // Update stats
      setState(() {
        _connectionsMade++;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connected with ${_getCurrentProfile()?.displayName ?? 'user'}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNotNow() async {
    if (_currentIndex >= _discoveries.length) return;

    final currentItem = _discoveries[_currentIndex];

    try {
      await _discoveryService.recordUserAction(
        currentItem.id,
        'pass',
      );

      // Move to next profile
      _moveToNextProfile();

    } catch (e) {
      // Silently handle error for pass action
      print('Error passing: $e');
    }
  }

  Future<void> _handleSave() async {
    if (_currentIndex >= _discoveries.length) return;

    final currentItem = _discoveries[_currentIndex];

    try {
      await _discoveryService.recordUserAction(
        currentItem.id,
        'save',
      );

      // Move to next profile
      _moveToNextProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved for later!'),
            backgroundColor: Colors.blue,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _moveToNextProfile() {
    setState(() {
      _currentIndex++;
      if (_currentIndex >= _discoveries.length) {
        _initializeDiscovery();
      } else if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  DiscoveryProfile? _getCurrentProfile() {
    if (_currentIndex >= _discoveries.length) return null;

    final currentItem = _discoveries[_currentIndex];
    if (currentItem.isProfile && currentItem.profileDetails.isNotEmpty) {
      try {
        return DiscoveryProfile.fromJson(currentItem.profileDetails);
      } catch (e) {
        print('Error getting profile: $e');
        return null;
      }
    }
    return null;
  }

  DiscoveryProfile? _getProfileAtIndex(int index) {
    if (index >= _discoveries.length) return null;

    final item = _discoveries[index];
    if (item.isProfile && item.profileDetails.isNotEmpty) {
      try {
        return DiscoveryProfile.fromJson(item.profileDetails);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Finding great matches for you...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeDiscovery,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 20),
          const Text(
            'No more profiles to discover',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'Check back later for new matches',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _initializeDiscovery,
            child: const Text('Refresh Discoveries'),
          ),
        ],
      ),
    );
  }

  void _navigateToMessages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Messages'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _navigateToNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Notifications'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _discoveries.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemBuilder: (context, index) {
        if (index >= _discoveries.length) {
          return _buildEmpty();
        }

        final currentItem = _discoveries[index];
        final profile = _getProfileAtIndex(index);

        if (profile == null || profile.userId == '0') {
          return _buildEmpty();
        }

        return GestureDetector(
          onHorizontalDragStart: (details) {
            _dragStartX = details.localPosition.dx;
            setState(() {
              _showLeftIcon = false;
              _showRightIcon = false;
              _iconOpacity = 0.0;
            });
          },
          onHorizontalDragUpdate: (details) {
            final dragDistance = details.localPosition.dx - _dragStartX;

            if (dragDistance < -50) {
              setState(() {
                _showLeftIcon = true;
                _showRightIcon = false;
                _iconOpacity = (-dragDistance - 50) / 100;
              });
            } else if (dragDistance > 50) {
              setState(() {
                _showLeftIcon = false;
                _showRightIcon = true;
                _iconOpacity = (dragDistance - 50) / 100;
              });
            } else {
              setState(() {
                _iconOpacity = 0.0;
              });
            }
          },
          onHorizontalDragEnd: (details) {
            final dragDistance = details.primaryVelocity ?? 0;

            if (dragDistance < -500) {
              _navigateToMessages();
            } else if (dragDistance > 500) {
              _navigateToNotifications();
            }

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _showLeftIcon = false;
                  _showRightIcon = false;
                  _iconOpacity = 0.0;
                });
              }
            });
          },
          child: Stack(
            children: [
              ProfileCard(
                profile: profile,
                compatibilityScore: currentItem.overallScore,
                compatibilityText: currentItem.compatibilityText,
                explanation: currentItem.explanation,
                onConnect: _handleConnect,
                onNotNow: _handleNotNow,
                onSave: _handleSave,
              ),

              if (_showLeftIcon && index == _currentIndex)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: _iconOpacity.clamp(0.0, 1.0),
                      child: Container(
                        margin: const EdgeInsets.only(left: 30),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.message, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),

              if (_showRightIcon && index == _currentIndex)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: _iconOpacity.clamp(0.0, 1.0),
                      child: Container(
                        margin: const EdgeInsets.only(right: 30),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeDiscovery,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoading()
              : _error != null
              ? _buildError()
              : _discoveries.isEmpty
              ? _buildEmpty()
              : _buildPageView(),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
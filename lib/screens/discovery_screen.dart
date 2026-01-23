// lib/screens/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/services/discovery_service.dart';
import 'package:kanairoxo/widgets/profile_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final DiscoveryService _discoveryService = DiscoveryService();
  final PageController _pageController = PageController();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  DiscoverySession? _currentSession;
  List<DiscoveryItem> _discoveries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0), // Swoosh to the left
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeDiscovery();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
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
              throw Exception('Could not start or find a discovery session.');
            }
          } catch (e2) {
            print('Error getting existing sessions: $e2');
            rethrow;
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

          print('Received ${batch.discoveries.length} discoveries');

          setState(() {
            _discoveries = batch.discoveries;
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
            _error = 'Failed to load discoveries. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Unexpected error: $e');
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConnect() async {
    if (_currentIndex >= _discoveries.length || _isProcessingAction) return;

    setState(() {
      _isProcessingAction = true;
    });

    final currentItem = _discoveries[_currentIndex];
    final profile = _getCurrentProfile();
    final profileName = profile?.displayName ?? 'user';

    try {
      await _discoveryService.recordUserAction(
        currentItem.id,
        'connect',
        rating: 5.0,
        context: {'action_source': 'discovery_screen'},
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connected with $profileName! 🎉',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Move to next profile after a short delay
      await Future.delayed(const Duration(milliseconds: 800));
      _moveToNextProfile();

    } catch (e) {
      print('Error connecting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to connect. Please try again.',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  Future<void> _handleNotNow() async {
    if (_currentIndex >= _discoveries.length || _isProcessingAction) return;

    setState(() {
      _isProcessingAction = true;
    });

    await _animationController.forward();

    final currentItem = _discoveries[_currentIndex];

    try {
      await _discoveryService.recordUserAction(
        currentItem.id,
        'pass',
      );

      // Move to next profile immediately
      _moveToNextProfile();

    } catch (e) {
      print('Error passing: $e');
      // Silently handle error, still move to next profile
      _moveToNextProfile();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _animationController.reset();
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_currentIndex >= _discoveries.length || _isProcessingAction) return;

    setState(() {
      _isProcessingAction = true;
    });

    await _animationController.forward();

    final currentItem = _discoveries[_currentIndex];
    final profile = _getCurrentProfile();
    final profileName = profile?.displayName ?? 'user';

    try {
      await _discoveryService.recordUserAction(
        currentItem.id,
        'save',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $profileName for later! 💾',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Move to next profile after a short delay
      await Future.delayed(const Duration(milliseconds: 800));
      _moveToNextProfile();

    } catch (e) {
      print('Error saving: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save. Please try again.',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _animationController.reset();
        });
      }
    }
  }

  void _moveToNextProfile() {
    if (_isProcessingAction) return;

    setState(() {
      _currentIndex++;
      if (_currentIndex >= _discoveries.length) {
        // Load more if we're at the end
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
        print('Error getting profile at index $index: $e');
        return null;
      }
    }
    return null;
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Finding great matches for you...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeDiscovery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Try Again', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No profiles to show right now',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Check back later for new matches!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _initializeDiscovery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _discoveries.length,
      itemBuilder: (context, index) {
        final profile = _getProfileAtIndex(index);
        if (profile == null) {
          return const SizedBox.shrink(); // Should not happen if itemCount is correct
        }
        return SlideTransition(
          position: _slideAnimation,
          child: ProfileCard(
            profile: profile,
            compatibilityScore: _discoveries[index].overallScore,
            compatibilityText: _discoveries[index].compatibilityText,
            explanation: _discoveries[index].explanation,
            onConnect: _handleConnect,
            onNotNow: _handleNotNow,
            onSave: _handleSave,
            isProcessing: _isProcessingAction,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.bell()),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _discoveries.isEmpty
          ? _buildEmpty()
          : _buildPageView(),
    );
  }
}

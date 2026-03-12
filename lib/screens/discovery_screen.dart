import 'package:flutter/material.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/services/discovery_service.dart';
import 'package:kanairoxo/widgets/profile_card.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

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
      end: const Offset(-1.5, 0.0),
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_currentSession == null) {
        try {
          final session = await _discoveryService.startDiscoverySession();
          if (!mounted) return;
          setState(() {
            _currentSession = session;
          });
        } catch (e) {
          try {
            final sessions = await _discoveryService.getMySessions();
            final activeSessions = sessions.where((s) => s.isActive).toList();
            if (activeSessions.isNotEmpty) {
              if (!mounted) return;
              setState(() {
                _currentSession = activeSessions.first;
              });
            } else {
              throw Exception('Could not start or find a discovery session.');
            }
          } catch (e2) {
            rethrow;
          }
        }
      }

      if (_currentSession != null) {
        try {
          final batch = await _discoveryService.getDiscoveryBatch(
            _currentSession!.sessionId,
            batchSize: 10,
          );
          if (!mounted) return;
          setState(() {
            _discoveries = batch.discoveries;
            _currentIndex = 0;
            _isLoading = false;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _error = 'Failed to load discoveries. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_currentIndex >= _discoveries.length || _isProcessingAction) return;
    if (!mounted) return;
    setState(() {
      _isProcessingAction = true;
    });

    await _animationController.forward();
    final currentItem = _discoveries[_currentIndex];

    try {
      await _discoveryService.recordUserAction(currentItem.id, 'save');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved for later! 💾'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await Future.delayed(const Duration(milliseconds: 800));
      _moveToNextProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save.')),
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
    if (_isProcessingAction || !mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Discover', style: AppTypography.screenTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF1A1A1A),
              size: 22,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _discoveries.isEmpty
                  ? _buildEmpty()
                  : _buildPageView(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(_error ?? 'An error occurred', textAlign: TextAlign.center, style: AppTypography.bodyLarge),
            const SizedBox(height: 12),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: _initializeDiscovery,
              child: Text('Try Again', style: AppTypography.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No profiles right now', style: AppTypography.displayMedium),
            const SizedBox(height: 8),
            Text("Check back later!", style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: _initializeDiscovery,
              child: Text('Refresh', style: AppTypography.buttonText),
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
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final profile = _getProfileAtIndex(index);
        if (profile == null) return const SizedBox.shrink();

        final discoveryItem = _discoveries[index];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          child: Column(
            children: [
              if (discoveryItem.explanation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            discoveryItem.explanation,
                            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ProfileCard(
                    profile: profile,
                    compatibilityScore: discoveryItem.overallScore,
                    compatibilityText: discoveryItem.compatibilityText,
                    explanation: discoveryItem.explanation,
                    onNotNow: _moveToNextProfile,
                    onSave: _handleSave,
                    onConnectionSuccess: () {
                      Future.delayed(const Duration(seconds: 1), _moveToNextProfile);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

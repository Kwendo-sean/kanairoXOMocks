import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/models/discovery_models.dart';
import 'package:kanairoxo/models/connection_context_model.dart';
import 'package:kanairoxo/services/discovery_service.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/widgets/profile_card.dart';
import 'package:kanairoxo/widgets/discovery/ad_card.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/screens/notification_screen.dart';
import 'package:kanairoxo/models/messaging/conversation_model.dart';
import 'package:kanairoxo/screens/messaging/chat_screen.dart';
import 'package:kanairoxo/providers/notification_provider.dart';
import 'package:kanairoxo/providers/profile_provider.dart';
import 'package:kanairoxo/screens/messages/date_planner_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final DiscoveryService _discoveryService = DiscoveryService();
  final ApiClient _apiClient = ApiClient();
  final PageController _pageController = PageController();

  List<DiscoveryItem> _discoveries = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingAction = false;

  ConnectionContextModel? _contextCard;
  bool _contextLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeDiscovery();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeDiscovery() async {
    if (!mounted) return;

    // GATE: Check profile completion
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    if (profileProvider.myProfile == null) {
      await profileProvider.refreshMyProfile();
    }
    
    final completion = profileProvider.myProfile?.completionPercentage ?? 0;
    if (completion < 70) {
      setState(() {
        _isLoading = false;
        _discoveries = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get('api/v1/discovery/recommendations/');
      final batch = DiscoveryBatch.fromJson(response);
      
      if (!mounted) return;
      setState(() {
        _discoveries = batch.discoveries;
        _currentIndex = 0;
        _isLoading = false;
      });
      
      if (_discoveries.isNotEmpty && !_discoveries[0].isAd) {
        _loadContextCard(_discoveries[0].id!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load discoveries. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContextCard(String targetUserId) async {
    setState(() {
      _contextCard = null;
      _contextLoading = true;
    });
    final context = await _discoveryService.getConnectionContext(targetUserId);
    if (!mounted) return;
    setState(() {
      _contextCard = context;
      _contextLoading = false;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (!_discoveries[index].isAd) {
      _loadContextCard(_discoveries[index].id!);
    } else {
      setState(() {
        _contextCard = null;
      });
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

  Future<void> _openChat() async {
    final item = _discoveries[_currentIndex];
    if (item.isAd) return;
    
    final userId = item.id;
    if (userId == null) return;
    
    try {
      final response = await _apiClient.post(
        'api/v1/messaging/start/',
        {'user_id': userId});
      
      if (!mounted) return;
      
      final conv = ConversationModel.fromJson(response['conversation']);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open chat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = context.bgColor;
    final textColor = context.textColor;
    final primaryColor = context.primaryColor;
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.unreadCount;
    final profileProvider = context.watch<ProfileProvider>();
    final completion = profileProvider.myProfile?.completionPercentage ?? 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Discover', style: AppTypography.screenTitle.copyWith(color: textColor)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: textColor, size: 22),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: completion < 70 
        ? _buildGate(completion)
        : _error != null
              ? _buildError()
              : (_discoveries.isEmpty && !_isLoading)
                  ? _buildEmpty()
                  : _buildPageView(),
    );
  }

  Widget _buildGate(int completion) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 24),
            Text('Complete your profile', style: AppTypography.displaySmall.copyWith(color: Colors.white)),
            const SizedBox(height: 12),
            Text('Your profile is $completion% complete. Reach 70% to start discovering people.', 
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
            const SizedBox(height: 32),
            LinearProgressIndicator(
              value: completion / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(AppConstants.primaryRed),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 48),
            LiquidGlassButton(
              onPressed: () => Navigator.pushNamed(context, '/profile_editor'),
              child: const Text('Finish Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    if (_isLoading && _discoveries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _discoveries.length,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final item = _discoveries[index];

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (!item.isAd && item.explanation != null)
                  _buildExplanation(item.explanation!),
                
                if (item.isAd)
                  AdCard(ad: item, onNext: _moveToNextProfile)
                else
                  ProfileCard(
                    profile: DiscoveryProfile.fromJson(item.profileDetails),
                    compatibilityScore: item.overallScore,
                    compatibilityText: item.compatibilityText,
                    explanation: item.explanation ?? '',
                    onNotNow: _moveToNextProfile,
                    onMessage: _openChat,
                    onConnectionSuccess: () {
                      Future.delayed(const Duration(seconds: 1), _moveToNextProfile);
                    },
                  ),
                
                const SizedBox(height: 16),
                if (!item.isAd) _buildContextCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExplanation(String text) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1C1612) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.isDark ? const Color(0xFF2E2820) : Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 16, color: context.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: context.isDark ? const Color(0xFF7A6E66) : AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard() {
    if (_contextLoading) return const Center(child: CircularProgressIndicator());
    if (_contextCard == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: Text('Shared interests and more...', style: TextStyle(color: context.textColor)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'An error occurred'),
          TextButton(onPressed: _initializeDiscovery, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 24),
          const Text('No more recommendations today', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          LiquidGlassButton(onPressed: () => Navigator.pushNamed(context, '/date-planner'), child: const Text('Plan a Date')),
        ],
      ),
    );
  }
}

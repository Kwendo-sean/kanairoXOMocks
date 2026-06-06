import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/connection_models.dart';
import 'package:kanairoxo/models/messaging/conversation_model.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/screens/messaging/chat_screen.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/providers/connection_provider.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/modals/report_modal.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String userId;
  final String? connectionId; // From notification or other sources
  final VoidCallback? onActionComplete;

  const ProfilePreviewScreen({
    super.key,
    required this.userId,
    this.connectionId,
    this.onActionComplete,
  });

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final ApiClient apiClient = ApiClient();
  ProfilePreviewModel? _profile;
  bool _loading = true;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) setState(() => _loading = true);
    try {
      final response = await apiClient.get('api/v1/profiles/${widget.userId}/full/');
      if (mounted) {
        setState(() {
          _profile = ProfilePreviewModel.fromJson(response);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAccept() async {
    final connId = _profile?.connectionId ?? widget.connectionId;
    if (connId == null) return;

    setState(() => _responding = true);
    try {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      final result = await connectionProvider.acceptConnection(connId, targetUserId: widget.userId);
      
      if (result['success'] == true) {
        _loadProfile();
        widget.onActionComplete?.call();
      } else {
        throw Exception(result['error'] ?? 'Failed to accept');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  Future<void> _handleDecline() async {
    final connId = _profile?.connectionId ?? widget.connectionId;
    if (connId == null) return;

    setState(() => _responding = true);
    try {
      // Assuming a decline endpoint or reusing generic connection removal
      await apiClient.delete('api/v1/connections/$connId/');
      if (mounted) {
        Navigator.pop(context);
        widget.onActionComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  Future<void> _handleConnect() async {
    setState(() => _responding = true);
    try {
      final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
      final result = await connectionProvider.quickConnect(widget.userId);
      if (result['success'] == true) {
        _loadProfile();
        widget.onActionComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  Future<void> _openChat() async {
    try {
      final response = await apiClient.post('api/v1/messaging/start/', {'user_id': widget.userId});
      if (!mounted) return;
      final conv = ConversationModel.fromJson(response['conversation']);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open chat')));
    }
  }

  void _showKebabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ReportModal.show(context, targetType: 'user', targetId: widget.userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('Block', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _confirmBlock();
              },
            ),
            if (_profile?.connectionStatus == 'connected')
              ListTile(
                leading: const Icon(Icons.person_remove_outlined, color: Colors.white),
                title: const Text('Unfriend', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnfriend();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Block User?', style: TextStyle(color: Colors.white)),
        content: const Text('They will no longer be able to see your profile or message you.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await apiClient.post('api/v1/connections/${widget.userId}/block/', {});
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Block', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmUnfriend() {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Unfriend?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this connection?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final connId = _profile?.connectionId;
              if (connId != null) {
                await apiClient.delete('api/v1/connections/$connId/');
                _loadProfile();
              }
            },
            child: const Text('Unfriend', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading ? const Center(child: CircularProgressIndicator()) : _profile == null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 450,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(url: p.photoUrl, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showKebabMenu,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${p.name}${p.age != null ? ', ${p.age}' : ''}', 
                          style: AppTypography.displayMedium.copyWith(color: Colors.white)),
                        if (p.badges.contains('premium'))
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.bolt, color: Colors.amber, size: 24),
                          ),
                      ],
                    ),
                    Text(p.headline, style: AppTypography.bodyLarge.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text(p.neighborhood, style: AppTypography.caption.copyWith(color: Colors.white)),
                        const SizedBox(width: 16),
                        const Icon(Icons.group, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(p.socialCircle, style: AppTypography.caption.copyWith(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection('About', p.bio),
                    if (p.interests.isNotEmpty) _buildChips('Interests', p.interests),
                    if (p.intents.isNotEmpty) _buildChips('Looking for', p.intents),
                    if (p.compatibility != null) _buildCompatibility(p.compatibility!),
                    if (p.gallery.isNotEmpty) _buildGallery(p.gallery),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
              ),
            ),
            child: _buildActionButtons(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChips(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(i, style: AppTypography.caption.copyWith(color: Colors.white)),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCompatibility(CompatibilityModel compat) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Compatibility Score', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
              Text('${compat.score}%', style: AppTypography.displaySmall.copyWith(color: AppConstants.primaryRed)),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompatRow('Interests', compat.breakdown.interests),
          _buildCompatRow('Intents', compat.breakdown.intent),
          _buildCompatRow('Lifestyle', compat.breakdown.lifeStage),
        ],
      ),
    );
  }

  Widget _buildCompatRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.caption.copyWith(color: Colors.white70))),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(AppConstants.primaryRed),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<GalleryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gallery', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) => Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SafeNetworkImage(url: items[index].imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _profile?.connectionStatus ?? 'none';

    if (status == 'connected') {
      return LiquidGlassButton(
        onPressed: _openChat,
        child: const Text('Message'),
      );
    }

    if (status == 'request_received') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _responding ? null : _handleDecline,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Decline', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LiquidGlassButton(
              onPressed: _responding ? null : _handleAccept,
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    }

    if (status == 'request_sent') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('Request Sent', style: TextStyle(color: Colors.white60))),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {}, // Save logic
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LiquidGlassButton(
            onPressed: _responding ? null : _handleConnect,
            child: const Text('Connect'),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Error loading profile', style: TextStyle(color: Colors.white)),
          TextButton(onPressed: _loadProfile, child: const Text('Retry')),
        ],
      ),
    );
  }
}

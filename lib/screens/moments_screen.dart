import 'package:flutter/material.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/screens/moments/creation/moment_creation_flow.dart';
import 'package:kanairoxo/widgets/modals/report_modal.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> with SingleTickerProviderStateMixin {
  late TabController _feedTabController;
  final MomentService _momentService = MomentService();
  List<Moment> _moments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _feedTabController = TabController(length: 4, vsync: this);
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    setState(() => _isLoading = true);
    try {
      final moments = await _momentService.getMoments();
      setState(() {
        _moments = moments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Moments', style: AppTypography.screenTitle.copyWith(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _feedTabController,
          indicatorColor: AppConstants.primaryRed,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Connections'),
            Tab(text: 'Discover'),
            Tab(text: 'Saved'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentCreationFlow()));
              if (result == true) _loadMoments();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _feedTabController,
        children: [
          _buildFeed(),
          _buildPlaceholder('Connections Feed'),
          _buildPlaceholder('Discover Moments'),
          _buildPlaceholder('Saved Moments'),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_moments.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadMoments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _moments.length,
        itemBuilder: (context, index) => _NewMomentCard(moment: _moments[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No moments yet', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentCreationFlow())),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryRed),
            child: const Text('Share your first moment'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(child: Text(text, style: const TextStyle(color: Colors.white54)));
  }
}

class _NewMomentCard extends StatelessWidget {
  final Moment moment;
  const _NewMomentCard({required this.moment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => ReportModal.show(context, targetType: 'moment', targetId: moment.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: moment.userAvatarUrl != null ? NetworkImage(moment.userAvatarUrl!) : null,
                    child: moment.userAvatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(moment.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (moment.location != null)
                          Text(moment.location!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.grey[900],
                        builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.report, color: Colors.white),
                              title: const Text('Report', style: TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(ctx);
                                ReportModal.show(context, targetType: 'moment', targetId: moment.id);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Multi-media Carousel
            AspectRatio(
              aspectRatio: 1,
              child: moment.gallery.isEmpty
                  ? SafeNetworkImage(url: moment.photoUrl, fit: BoxFit.cover)
                  : PageView.builder(
                      itemCount: moment.gallery.length,
                      itemBuilder: (context, index) => SafeNetworkImage(
                        url: moment.gallery[index].imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),

            // Reactions Row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const _ReactionItem(icon: Icons.favorite_border, label: '❤️'),
                  const _ReactionItem(icon: Icons.chat_bubble_outline, label: '😂'),
                  const _ReactionItem(icon: Icons.sentiment_satisfied_alt_outlined, label: '😮'),
                  const _ReactionItem(icon: Icons.local_fire_department_outlined, label: '🔥'),
                  const Spacer(),
                  const Icon(Icons.bookmark_border, color: Colors.white),
                ],
              ),
            ),

            // Music Indicator
            if (moment.trackName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text('${moment.trackName} • ${moment.trackArtist}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white),
                  children: [
                    TextSpan(text: moment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' '),
                    TextSpan(text: moment.caption),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('View all ${moment.commentCount} comments', style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ReactionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

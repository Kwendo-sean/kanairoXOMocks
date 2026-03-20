import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_theme.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/screens/create_moment_screen.dart';
import 'package:kanairoxo/screens/singles/moment_viewer_screen.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';
import '../widgets/moments/the_drop_widget.dart';
import '../widgets/moments/polaroid_stack.dart';
import '../widgets/moments/constellation_view.dart';
import '../services/widget_service.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key});

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  final MomentService _momentService = MomentService();
  final Dio apiClient = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  
  List<Moment> _allMoments = [];
  DropModel? _dropData;
  
  bool _isLoading = true;
  String _selectedTag = 'All';
  String _carouselStyle = 'polaroid';

  final List<String> _subtitles = [
    'Where Nairobi comes alive',
    'The city through your eyes',
    'Real moments, real connections',
    'Life in Nairobi, unfiltered',
    'Your story, your city',
    'Nairobi never sleeps',
    'Captured in the moment',
  ];
  
  late final String _carouselSubtitle;

  @override
  void initState() {
    super.initState();
    _carouselSubtitle = _subtitles[DateTime.now().millisecond % _subtitles.length];
    
    _loadMoments();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStylePreference();
      _loadDropData();
    });
  }

  Future<void> _loadStylePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('carousel_style');
      if (mounted) {
        setState(() {
          _carouselStyle = saved ?? 'polaroid';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carouselStyle = 'polaroid';
        });
      }
    }
  }

  Future<void> _switchStyle(String style) async {
    if (_carouselStyle == style) return;
    
    setState(() => _carouselStyle = style);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('carousel_style', style);
    } catch (e) {
      // Error
    }
  }

  Future<void> _loadMoments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final moments = await _momentService.getMoments();
      if (!mounted) return;
      setState(() {
        _allMoments = moments;
        _isLoading = false;
      });
      WidgetService.refreshAllWidgets(_allMoments, 0, 0); 
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDropData() async {
    try {
      final response = await apiClient.get('/api/v1/moments/drop/');
      if (mounted) {
        setState(() {
          _dropData = DropModel.fromJson(response.data as Map<String, dynamic>);
        });
        if (_dropData != null) {
          WidgetService.updateDropWidget(
              secondsUntilDrop: _dropData!.secondsUntilDrop,
              isLive: _dropData!.status == 'live');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _dropData = null);
      }
    }
  }

  List<Moment> get filteredMoments {
    if (_selectedTag == 'All') return _allMoments;
    return _allMoments
        .where((m) => m.type.name.toLowerCase() == _selectedTag.toLowerCase())
        .toList();
  }

  void openCreateMoment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateMomentScreen()),
    );
    if (result == true) {
      _loadMoments();
    }
  }

  void _openMomentViewer(int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => MomentViewerScreen(
            moments: _allMoments, initialIndex: index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildScreen();
    } catch (e) {
      return Scaffold(
        backgroundColor: context.bgColor,
        appBar: _buildAppBar(),
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
              size: 48, color: context.mutedColor),
            const SizedBox(height: 12),
            Text('Something went wrong',
              style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
            const SizedBox(height: 8),
            Text(e.toString(),
              style: AppTypography.caption.copyWith(
                color: context.mutedColor),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            LiquidGlassButton(
              size: LiquidButtonSize.md,
              onPressed: () => setState(() {}),
              child: Text('Retry',
                style: AppTypography.buttonText)),
          ])));
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Moments', style: AppTypography.screenTitle.copyWith(color: context.textColor)),
        centerTitle: true,
        actions: [
          TextButton.icon(
              icon: Icon(Icons.add_circle_outline,
                  size: 16, color: context.primaryColor),
              label: Text('Create',
                  style: AppTypography.labelMedium.copyWith(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w600)),
              onPressed: openCreateMoment),
        ]);
  }

  Widget _buildScreen() {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(
            color: context.primaryColor,
            strokeWidth: 2))
        : _buildBody());
  }
  
  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        
        SliverToBoxAdapter(
          child: _safeTopSection()),

        if (_dropData?.status != 'live')
          SliverToBoxAdapter(
            child: _buildViewToggle()),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_carouselSubtitle,
              style: AppTypography.caption.copyWith(
                color: context.mutedColor,
                fontStyle: FontStyle.italic),
              textAlign: TextAlign.center))),
        
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterTabsDelegate(
            selectedTag: _selectedTag,
            onTagSelected: (tag) => setState(() =>
              _selectedTag = tag),
            backgroundColor: context.bgColor)),
        
        if (filteredMoments.isEmpty)
          SliverToBoxAdapter(
            child: _buildTagEmptyState())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _MomentCard(
                moment: filteredMoments[i],
                onLike: () => _toggleLike(filteredMoments[i]),
                onComment: () => _openComments(context, filteredMoments[i]),
                onImageTap: () => _openMomentViewer(_allMoments.indexOf(filteredMoments[i]))),
              childCount: filteredMoments.length)),
        
        const SliverToBoxAdapter(
          child: SizedBox(height: 80)),
      ]);
  }

  Widget _buildViewToggle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: context.borderColor),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _switchStyle('polaroid'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _carouselStyle == 'polaroid'
                    ? context.primaryColor
                    : Colors.transparent,
                  borderRadius: 
                    BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      size: 14,
                      color: _carouselStyle == 'polaroid'
                        ? Colors.white
                        : context.mutedColor),
                    const SizedBox(width: 5),
                    Text('Polaroid',
                      style: AppTypography.caption
                        .copyWith(
                          color: _carouselStyle == 
                            'polaroid'
                            ? Colors.white
                            : context.mutedColor,
                          fontWeight: _carouselStyle == 
                            'polaroid'
                            ? FontWeight.w600
                            : FontWeight.w400)),
                  ])),
            ),
            GestureDetector(
              onTap: () => _switchStyle(
                'constellation'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _carouselStyle == 
                    'constellation'
                    ? context.primaryColor
                    : Colors.transparent,
                  borderRadius: 
                    BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: _carouselStyle == 
                        'constellation'
                        ? Colors.white
                        : context.mutedColor),
                    const SizedBox(width: 5),
                    Text('Stars',
                      style: AppTypography.caption
                        .copyWith(
                          color: _carouselStyle == 
                            'constellation'
                            ? Colors.white
                            : context.mutedColor,
                          fontWeight: _carouselStyle == 
                            'constellation'
                            ? FontWeight.w600
                            : FontWeight.w400)),
                  ])),
            ),
          ])));
  }
  
  Widget _safeTopSection() {
    try {
      return _buildTopSection();
    } catch (e) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.isDark ? context.surfaceColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
        child: Center(child: Icon(
          Icons.photo_library_outlined,
          size: 48, color: context.mutedColor)));
    }
  }

  Widget _buildTopSection() {
    if (_dropData != null && (_dropData!.status == 'live' || _dropData!.secondsUntilDrop > 0)) {
       return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TheDropWidget(
          dropData: _dropData!,
          onRefresh: _loadDropData));
    }

    if (_carouselStyle == 'constellation') {
      return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ConstellationView(
              moments: _allMoments, 
              onTap: (m) => _openMomentViewer(_allMoments.indexOf(m))));
    }

    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: PolaroidStack(
            moments: _allMoments.take(10).toList(),
            onTap: (m) => _openMomentViewer(_allMoments.indexOf(m))));
  }

  Widget _buildTagEmptyState() {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.photo_library_outlined,
                  size: 44, color: context.mutedColor),
              const SizedBox(height: 12),
              Text(
                  _selectedTag == 'All'
                      ? 'No moments yet'
                      : 'No $_selectedTag moments yet',
                  style:
                      AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
              const SizedBox(height: 6),
              Text('Be the first to share one',
                  style:
                      AppTypography.caption.copyWith(color: context.mutedColor)),
              const SizedBox(height: 16),
              LiquidGlassButton(
                  size: LiquidButtonSize.md,
                  onPressed: openCreateMoment,
                  child: Text('Create Moment', style: AppTypography.buttonText)),
            ])));
  }

  Future<void> _toggleLike(Moment moment) async {
    try {
      await _momentService.toggleLike(moment.id);
      _loadMoments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not like moment')),
        );
      }
    }
  }

  void _openComments(BuildContext context, Moment moment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MomentCommentsSheet(moment: moment),
    );
  }
}

class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  final String selectedTag;
  final Function(String) onTagSelected;
  final Color backgroundColor;

  _FilterTabsDelegate({
    required this.selectedTag,
    required this.onTagSelected,
    required this.backgroundColor,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;
  
  @override
  bool shouldRebuild(_FilterTabsDelegate old) =>
    old.selectedTag != selectedTag ||
    old.backgroundColor != backgroundColor;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _buildTabs(context));
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['All', 'Event', 'Meetup', 'Vibe']
            .map((tag) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onTagSelected(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selectedTag == tag ? context.primaryColor : context.surfaceColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: selectedTag == tag ? context.primaryColor : context.borderColor,
                            width: 1),
                      ),
                      child: Text(tag,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: selectedTag == tag ? Colors.white : context.mutedColor,
                            fontWeight: selectedTag == tag ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final Moment moment;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onImageTap;

  const _MomentCard({
    required this.moment,
    required this.onLike,
    required this.onComment,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (moment.userAvatarUrl != null && moment.userAvatarUrl!.isNotEmpty) 
                      ? NetworkImage(moment.userAvatarUrl!) 
                      : null,
                  backgroundColor: AppColors.themePrimaryGlass(context),
                  child: (moment.userAvatarUrl == null || moment.userAvatarUrl!.isEmpty) 
                      ? Icon(Icons.person_outline, size: 18, color: context.primaryColor) 
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moment.userName,
                        style: AppTypography.labelMedium
                            .copyWith(fontWeight: FontWeight.w600, color: context.textColor)),
                    Text(moment.timeAgo, style: AppTypography.caption.copyWith(color: context.mutedColor)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.themePrimaryGlass(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    moment.type.name.toUpperCase(),
                    style: AppTypography.caption.copyWith(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onDoubleTap: onLike,
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                moment.photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: context.isDark ? context.borderColor.withOpacity(0.3) : Colors.grey.shade100,
                  height: 300,
                  child: Center(child: Icon(Icons.broken_image_outlined, color: context.mutedColor)),
                ),
              ),
            ),
          ),

          if (moment.location != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: context.mutedColor),
                  const SizedBox(width: 3),
                  Text(moment.location!, style: AppTypography.caption.copyWith(color: context.mutedColor)),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Text(
              moment.caption,
              style: AppTypography.bodyMedium.copyWith(color: context.textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              children: [
                _MomentAction(
                  icon: moment.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: moment.isLiked ? context.primaryColor : context.mutedColor,
                  label: '${moment.likeCount}',
                  onTap: onLike,
                ),
                const SizedBox(width: 4),
                _MomentAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${moment.commentCount}',
                  onTap: onComment,
                ),
                const Spacer(),
                _MomentAction(
                  icon: moment.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: moment.isSaved ? context.primaryColor : context.mutedColor,
                  label: '',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MomentAction({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color ?? context.mutedColor),
      label: label.isNotEmpty ? Text(label, style: AppTypography.caption.copyWith(color: context.mutedColor)) : const SizedBox.shrink(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _MomentCommentsSheet extends StatefulWidget {
  final Moment moment;
  const _MomentCommentsSheet({required this.moment});

  @override
  State<_MomentCommentsSheet> createState() => _MomentCommentsSheetState();
}

class _MomentCommentsSheetState extends State<_MomentCommentsSheet> {
  final MomentService _momentService = MomentService();
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _momentService.getComments(widget.moment.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await _momentService.addComment(widget.moment.id, _commentController.text);
      _commentController.clear();
      _loadComments();
    } catch (e) {
      // Error
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('Comments', style: AppTypography.displayMedium.copyWith(color: context.textColor)),
              Expanded(
                child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: context.primaryColor))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundImage: comment['user_avatar'] != null ? NetworkImage(comment['user_avatar']) : null,
                            child: comment['user_avatar'] == null ? const Icon(Icons.person, size: 14) : null,
                          ),
                          title: Text(comment['user_name'] ?? 'User', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: context.textColor)),
                          subtitle: Text(comment['text'] ?? '', style: AppTypography.bodyMedium.copyWith(color: context.textColor)),
                        );
                      },
                    ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: TextStyle(color: context.textColor),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: AppTypography.caption.copyWith(color: context.mutedColor),
                          filled: true,
                          fillColor: context.isDark ? context.borderColor.withOpacity(0.3) : Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: context.primaryColor),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

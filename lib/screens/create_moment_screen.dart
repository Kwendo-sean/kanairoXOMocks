import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/models/music/spotify_models.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/services/spotify_service.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/utils/feature_flags.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final _momentService = MomentService();
  final _captionController = TextEditingController();
  File? _selectedImage;
  String _selectedType = 'vibe';
  bool _isSubmitting = false;
  TrackModel? _attachedTrack;
  
  List<LinkedEvent> _linkableEvents = [];
  bool _loadingEvents = true;
  int? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final events = await _momentService.getLinkableEvents();
    if (mounted) {
      setState(() {
        _linkableEvents = events;
        _loadingEvents = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _attachCurrentSong() async {
    if (!FeatureFlags.spotifyEnabled) return;
    final track = await SpotifyService().getNowPlaying();
    if (track != null && mounted) {
      setState(() => _attachedTrack = track);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nothing playing on Spotify'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, String>? trackData;
      if (FeatureFlags.spotifyEnabled && _attachedTrack != null) {
        trackData = {
          'name': _attachedTrack!.name,
          'artist': _attachedTrack!.artist,
          'image_url': _attachedTrack!.imageUrl ?? '',
          'preview_url': _attachedTrack!.previewUrl ?? '',
        };
      }

      await _momentService.createMoment(
        caption: _captionController.text,
        type: _selectedType,
        photo: _selectedImage!,
        linkedEventId: _selectedEventId,
        trackData: trackData,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moment shared successfully'), backgroundColor: Color(0xFF9B111E)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFF9B111E)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAF7F4);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE8E0D0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 22),
          onPressed: () => Navigator.pop(context)),
        title: Text('Create Moment', 
          style: AppTypography.screenTitle.copyWith(color: textColor)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Polaroid-style Photo picker area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: Color(0xFFBBAA99), size: 32),
                          const SizedBox(height: 8),
                          const Text(
                            "Select a Photo",
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              color: Color(0xFFBBAA99),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Caption Section
            _buildLabel("What's happening?"),
            TextField(
              controller: _captionController,
              maxLines: 4,
              style: TextStyle(fontFamily: 'DMSans', color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Share the vibe...',
                hintStyle: const TextStyle(fontFamily: 'DMSans', color: Color(0xFFA09080), fontSize: 14),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF9B111E), width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Event linking row
            if (_loadingEvents || _linkableEvents.isNotEmpty) ...[
              _buildLabel("At an event?"),
              if (_loadingEvents)
                _buildEventShimmer()
              else
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _linkableEvents.length,
                    itemBuilder: (context, index) {
                      final event = _linkableEvents[index];
                      final isSelected = _selectedEventId == event.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedEventId = null;
                              } else {
                                _selectedEventId = event.id;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected ? const Color(0xFF9B111E) : borderColor),
                              borderRadius: BorderRadius.circular(20),
                              color: isSelected ? const Color(0xFF9B111E) : cardColor,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: event.coverImageUrl != null 
                                    ? NetworkImage(ApiConstants.fixMediaUrl(event.coverImageUrl)) 
                                    : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    color: isSelected ? Colors.white : textColor,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // Music Attachment
            if (FeatureFlags.spotifyEnabled) ...[
              _buildLabel("Attach a song?"),
              GestureDetector(
                onTap: _attachCurrentSong,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note_rounded, size: 14, color: Color(0xFF9B111E)),
                      const SizedBox(width: 6),
                      Text(
                        _attachedTrack != null ? "${_attachedTrack!.name} · ${_attachedTrack!.artist}" : 'Select current track',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: textColor,
                          fontSize: 13,
                        )),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Submit Button
            LiquidGlassButton(
              size: LiquidButtonSize.xl,
              width: double.infinity,
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Post Moment', 
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: Colors.white, 
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      )
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: Color(0xFF666666),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.white,
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

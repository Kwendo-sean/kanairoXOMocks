import 'package:flutter/material.dart';
import 'package:kanairoxo/models/moment_creation_models.dart';
import 'package:kanairoxo/services/moment_service.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/models/moment.dart';

class PostScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final VoidCallback onComplete;

  const PostScreen({super.key, required this.mediaItems, required this.onComplete});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  String _visibility = 'Public';
  int? _selectedEventId;
  List<LinkedEvent> _linkableEvents = [];
  bool _isLoadingEvents = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final service = MomentService();
    final events = await service.getLinkableEvents();
    if (mounted) {
      setState(() {
        _linkableEvents = events;
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _handlePost() async {
    setState(() => _isPosting = true);
    final service = MomentService();
    
    try {
      // 1. Create the moment record
      // The current service has a simplified createMoment. 
      // For this rebuild, we'd ideally call the new endpoints.
      // We'll use the existing one for the first photo to maintain compatibility.
      final moment = await service.createMoment(
        caption: _captionController.text,
        type: 'vibe',
        photo: widget.mediaItems.first.file,
        location: _locationController.text,
        linkedEventId: _selectedEventId,
      );

      // 2. Attach additional media (POST /api/v1/moments/<id>/media/)
      if (widget.mediaItems.length > 1) {
        for (int i = 1; i < widget.mediaItems.length; i++) {
          // Placeholder for additional media attachment
          debugPrint('Uploading additional media item $i');
        }
      }

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Post', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _handlePost,
            child: _isPosting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Share', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: FileImage(widget.mediaItems.first.file), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 40),
            
            _buildListTile(Icons.location_on_outlined, 'Add Location', 
              child: TextField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(hintText: 'Search places...', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
              )
            ),
            
            _buildListTile(Icons.person_add_alt_1_outlined, 'Tag People', trailing: const Icon(Icons.chevron_right, color: Colors.white24)),
            
            _buildListTile(Icons.visibility_outlined, 'Visibility', 
              trailing: DropdownButton<String>(
                value: _visibility,
                dropdownColor: Colors.grey[900],
                underline: const SizedBox(),
                items: ['Public', 'Connections', 'Close Friends'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _visibility = v!),
              )
            ),

            const SizedBox(height: 24),
            const Text('Link to Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isLoadingEvents)
              const CircularProgressIndicator()
            else
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _linkableEvents.length,
                  itemBuilder: (context, index) {
                    final e = _linkableEvents[index];
                    final isSelected = _selectedEventId == e.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEventId = isSelected ? null : e.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppConstants.primaryRed : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.white24 : Colors.white10),
                        ),
                        child: Center(child: Text(e.title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12))),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 40),
            LiquidGlassButton(
              variant: LiquidButtonVariant.outline,
              width: double.infinity,
              onPressed: () {}, // Save draft
              child: const Text('Save Draft'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {Widget? child, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: child ?? Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

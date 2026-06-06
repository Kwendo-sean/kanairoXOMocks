import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kanairoxo/models/moment_creation_models.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';
import 'package:kanairoxo/utils/constants.dart';

class EditScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final Function(List<MediaItem>) onComplete;

  const EditScreen({super.key, required this.mediaItems, required this.onComplete});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<String> _filters = ['None', 'Vivid', 'B&W', 'Vintage', 'Warm', 'Cool', 'Dramatic', 'Fade', 'Noir', 'Bright', 'Golden', 'Film'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => widget.onComplete(widget.mediaItems),
            child: const Text('Next', style: TextStyle(color: AppConstants.primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[900],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(widget.mediaItems[_currentIndex].file, fit: BoxFit.contain),
              ),
            ),
          ),

          // Multi-item Carousel (if more than 1)
          if (widget.mediaItems.length > 1)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.mediaItems.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    width: 44,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _currentIndex == index ? AppConstants.primaryRed : Colors.transparent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(widget.mediaItems[index].file, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),

          // Edit Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppConstants.primaryRed,
            tabs: const [
              Tab(icon: Icon(Icons.filter), text: 'Filters'),
              Tab(icon: Icon(Icons.crop), text: 'Crop'),
              Tab(icon: Icon(Icons.text_fields), text: 'Text'),
              Tab(icon: Icon(Icons.sticky_note_2), text: 'Stickers'),
              Tab(icon: Icon(Icons.music_note), text: 'Music'),
              Tab(icon: Icon(Icons.mic), text: 'Voice'),
            ],
          ),

          // Tab Content (Simplified Filter view for demo)
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFilterList(),
                _buildPlaceholderTool('Crop Tool'),
                _buildPlaceholderTool('Text Overlay'),
                _buildPlaceholderTool('Stickers'),
                _buildPlaceholderTool('Music Library'),
                _buildPlaceholderTool('Voice Memo (Premium)'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: _filters.length,
      itemBuilder: (context, index) => Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
                image: DecorationImage(image: FileImage(widget.mediaItems[_currentIndex].file), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 4),
            Text(_filters[index], style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTool(String label) {
    return Center(child: Text(label, style: const TextStyle(color: Colors.white54)));
  }
}

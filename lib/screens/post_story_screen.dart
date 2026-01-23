import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class PostStoryScreen extends StatefulWidget {
  final bool isStory;
  
  const PostStoryScreen({super.key, this.isStory = true});
  
  @override
  State<PostStoryScreen> createState() => _PostStoryScreenState();
}

class _PostStoryScreenState extends State<PostStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  List<String> _selectedMedia = [];
  bool _isLoading = false;
  String _selectedMood = 'Calm';
  List<String> _moods = ['Calm', 'Energetic', 'Reflective', 'Adventurous', 'Creative', 'Curious'];
  
  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:  Icon(PhosphorIcons.image(), color: AppConstants.primaryRed),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Pick photo
                },
              ),
              ListTile(
                leading:  Icon(PhosphorIcons.video(), color: AppConstants.primaryRed),
                title: const Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  // Pick video
                },
              ),
              ListTile(
                leading:  Icon(PhosphorIcons.camera(), color: AppConstants.primaryRed),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  // Open camera
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _createPost() async {
    if (_captionController.text.isEmpty && _selectedMedia.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isStory 
              ? 'Story posted! It will disappear in 12 hours.'
              : 'Post published!',
        ),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          widget.isStory ? 'Create Story' : 'Create Post',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryRed,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isStory ? 'Post' : 'Share',
                    style: const TextStyle(
                      color: AppConstants.primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current user info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&h=200&fit=crop',
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      widget.isStory ? 'Visible for 12 hours' : 'Post to your profile',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Caption
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: widget.isStory 
                    ? 'What\'s happening? This will disappear in 12 hours...'
                    : 'Share what\'s on your mind...',
                border: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.secondaryGray,
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            
            // Mood selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.secondaryGray,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moods.map((mood) {
                    final isSelected = mood == _selectedMood;
                    return ChoiceChip(
                      label: Text(mood),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedMood = mood);
                      },
                      selectedColor: AppConstants.primaryRed.withOpacity(0.2),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? AppConstants.primaryRed : AppConstants.primaryBlack,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppConstants.primaryRed : AppConstants.lightGray,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Media preview
            if (_selectedMedia.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedMedia.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.lightGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PhosphorIcons.image(),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMedia.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child:  Icon(
                              PhosphorIcons.x(),
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            
            // Add media button
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(
                    color: AppConstants.lightGray,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      PhosphorIcons.plusCircle(),
                      size: 48,
                      color: AppConstants.secondaryGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isStory ? 'Add to Story' : 'Add Photo/Video',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.secondaryGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isStory ? 'Photos disappear in 12 hours' : 'Up to 10 items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConstants.lightGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Audience selector
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audience',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(PhosphorIcons.users(), size: 20, color: AppConstants.secondaryGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isStory ? 'Story Audience' : 'Post Audience',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      DropdownButton<String>(
                        value: 'Connections',
                        items: const ['Only Me', 'Connections', 'Everyone']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                  if (widget.isStory) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(PhosphorIcons.clock(), size: 20, color: AppConstants.secondaryGray),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Story Duration',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        DropdownButton<String>(
                          value: '12 hours',
                          items: const ['6 hours', '12 hours', '24 hours']
                              .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ))
                              .toList(),
                          onChanged: (value) {},
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
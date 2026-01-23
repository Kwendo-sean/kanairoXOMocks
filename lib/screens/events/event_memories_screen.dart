import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class EventMemoriesScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  
  const EventMemoriesScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });
  
  @override
  State<EventMemoriesScreen> createState() => _EventMemoriesScreenState();
}

class _EventMemoriesScreenState extends State<EventMemoriesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _photos = [
    {
      'url': 'assets/images/kanairoxo_logo.png',
      'user': 'Sofia',
      'likes': 24,
      'comments': 5,
    },
    {
      'url': 'assets/images/kanairoxo_logo.png',
      'user': 'Marcus',
      'likes': 42,
      'comments': 8,
    },
    {
      'url': 'assets/images/kanairoxo_logo.png',
      'user': 'You',
      'likes': 18,
      'comments': 3,
    },
  ];
  
  final List<Map<String, dynamic>> _reviews = [
    {
      'user': 'Sofia',
      'rating': 5,
      'comment': 'Amazing conversations! Met some really interesting people.',
      'time': '2 days ago',
      'userImage': 'assets/images/kanairoxo_logo.png',
    },
    {
      'user': 'Marcus',
      'rating': 4,
      'comment': 'Great coffee and even better company. Will definitely attend again!',
      'time': '3 days ago',
      'userImage': 'assets/images/kanairoxo_logo.png',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _addMemory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryRed,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:  Icon(PhosphorIcons.x(), color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add Memory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Pick photo/video
                        },
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryBeige,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppConstants.lightGray,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.image(),
                                size: 48,
                                color: AppConstants.secondaryGray,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Add Photo/Video',
                                style: TextStyle(
                                  color: AppConstants.secondaryGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppConstants.lightGray),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                           Icon(PhosphorIcons.star(), color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: 5,
                              min: 1,
                              max: 5,
                              divisions: 4,
                              onChanged: (value) {},
                            ),
                          ),
                          const Text(
                            '5.0',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Memory added successfully'),
                                backgroundColor: AppConstants.successGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text('Share Memory'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          'Event Memories',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryRed,
          labelColor: AppConstants.primaryBlack,
          unselectedLabelColor: AppConstants.secondaryGray,
          tabs: const [
            Tab(text: 'Photos'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemory,
        backgroundColor: AppConstants.primaryRed,
        foregroundColor: Colors.white,
        child: Icon(PhosphorIcons.plus()),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Photos tab
          GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Container(
                          color: AppConstants.lightGray,
                          child: photo['url'].startsWith('http') 
                          ? Image.network(
                            photo['url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                          : Image.asset(
                            photo['url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'By ${photo['user']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.heart(),
                                size: 16,
                                color: AppConstants.secondaryGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${photo['likes']}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                PhosphorIcons.chatCircle(),
                                size: 16,
                                color: AppConstants.secondaryGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${photo['comments']}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Reviews tab
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: review['userImage'].startsWith('http')
                              ? NetworkImage(review['userImage'])
                              : AssetImage(review['userImage']) as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['user'],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                review['time'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppConstants.secondaryGray,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review['rating']
                                  ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                                  : PhosphorIcons.star(),
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      review['comment'],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            PhosphorIcons.heart(),
                            size: 20,
                            color: AppConstants.secondaryGray,
                          ),
                        ),
                        Text(
                          'Helpful',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.secondaryGray,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Reply'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
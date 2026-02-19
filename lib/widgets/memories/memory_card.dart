import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum MemoryType { photo, text, voice, location }

class MemoryCard extends StatelessWidget {
  final MemoryType type;

  const MemoryCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppConstants.lightGray,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jane & John', // Placeholder
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Shared a memory • 2d ago', // Placeholder
                style: TextStyle(color: AppConstants.secondaryGray, fontSize: 12),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case MemoryType.photo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image,
                  color: AppConstants.secondaryGray,
                  size: 80,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Our first hike of the year! The view was breathtaking. ☀️'),
            ),
          ],
        );
      case MemoryType.text:
        return const SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Just wanted to say how much I appreciate you today. You always know how to make me smile.',
              style: TextStyle(fontSize: 18, height: 1.5),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const PhosphorIcon(PhosphorIcons.heart, size: 22),
                tooltip: 'React',
              ),
              IconButton(
                onPressed: () {},
                icon: const PhosphorIcon(PhosphorIcons.chatCircle, size: 22),
                tooltip: 'Comment',
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const PhosphorIcon(PhosphorIcons.bookmarkSimple, size: 22),
            tooltip: 'Favorite',
          ),
        ],
      ),
    );
  }
}

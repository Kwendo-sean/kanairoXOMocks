import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';

class RecentMemories extends StatelessWidget {
  const RecentMemories({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Memories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: AppConstants.primaryRed),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4, // Placeholder count
            itemBuilder: (context, index) {
              return const _MemoryCard();
            },
          ),
        ),
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image,
                  color: AppConstants.secondaryGray,
                  size: 40,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beach Day', // Example
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    '2 days ago',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.secondaryGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

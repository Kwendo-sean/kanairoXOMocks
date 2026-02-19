import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DateCategories extends StatelessWidget {
  const DateCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      _Category(name: 'Romantic', icon: PhosphorIcons.heart(PhosphorIconsStyle.fill), color: Colors.pink),
      _Category(name: 'Adventurous', icon: PhosphorIcons.binoculars(PhosphorIconsStyle.fill), color: Colors.teal),
      _Category(name: 'Cozy', icon: PhosphorIcons.house(PhosphorIconsStyle.fill), color: Colors.orange),
      _Category(name: 'Growth', icon: PhosphorIcons.plant(PhosphorIconsStyle.fill), color: Colors.green),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Browse by Category',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(category: category);
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: category.color.withOpacity(0.1),
              child: PhosphorIcon(category.icon, color: category.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;

  _Category({required this.name, required this.icon, required this.color});
}

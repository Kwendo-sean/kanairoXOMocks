import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class VisionBoardScreen extends StatelessWidget {
  const VisionBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Vision Board'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const PhosphorIcon(PhosphorIcons.plus),
            tooltip: 'Add Image',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 8, // Placeholder count
        itemBuilder: (context, index) {
          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius / 2),
            ),
            child: GridTile(
              child: Image.network(
                'https://picsum.photos/seed/${index + 1}/400/400', // Placeholder images
                fit: BoxFit.cover,
              ),
              footer: GridTileBar(
                backgroundColor: Colors.black45,
                title: Text('Aspiration ${index + 1}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kanairoxo/screens/someday/vision_board_screen.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class VisionBoardCard extends StatelessWidget {
  const VisionBoardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        side: const BorderSide(color: AppConstants.lightGray, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const VisionBoardScreen()),
          );
        },
        child: AspectRatio(
          aspectRatio: 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/600x400?text=Our+Future'), // Placeholder
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PhosphorIcon(PhosphorIcons.mountains, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Our Vision Board',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Tap to see our dreams',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

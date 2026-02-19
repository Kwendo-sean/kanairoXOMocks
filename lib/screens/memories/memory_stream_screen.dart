import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/memories/filter_bar.dart';
import 'package:kanairoxo/widgets/memories/memory_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemoryStreamScreen extends StatelessWidget {
  const MemoryStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const PhosphorIcon(PhosphorIcons.magnifyingGlass),
            tooltip: 'Search',
          ),
        ],
      ),
      body: Column(
        children: [
          const FilterBar(),
          Expanded(
            child: ListView(
              children: const [
                MemoryCard(type: MemoryType.photo),
                MemoryCard(type: MemoryType.text),
                 MemoryCard(type: MemoryType.photo),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement memory creation flow
        },
        backgroundColor: AppConstants.primaryRed,
        child: const PhosphorIcon(PhosphorIcons.plus, color: Colors.white, size: 28),
        tooltip: 'Add Memory',
      ),
    );
  }
}

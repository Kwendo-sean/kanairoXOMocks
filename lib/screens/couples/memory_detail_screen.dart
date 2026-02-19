import 'package:flutter/material.dart';
import 'package:kanairoxo/services/memory_service.dart';

class MemoryDetailScreen extends StatelessWidget {
  final Memory memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(memory.title),
      ),
      body: Center(
        child: Text('Memory Detail Screen'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AddMemoryScreen extends StatelessWidget {
  const AddMemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Memory'),
      ),
      body: const Center(
        child: Text('Add Memory Screen'),
      ),
    );
  }
}

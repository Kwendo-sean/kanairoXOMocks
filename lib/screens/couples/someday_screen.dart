import 'package:flutter/material.dart';

class SomedayScreen extends StatelessWidget {
  const SomedayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aspirations'),
      ),
      body: const Center(
        child: Text('Aspirations Screen'),
      ),
    );
  }
}

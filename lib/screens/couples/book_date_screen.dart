import 'package:flutter/material.dart';

class BookDateScreen extends StatelessWidget {
  const BookDateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Date'),
      ),
      body: const Center(
        child: Text('Book a Date Screen'),
      ),
    );
  }
}

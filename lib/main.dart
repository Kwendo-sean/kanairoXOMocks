// lib/main.dart
import 'package:flutter/material.dart';
import 'app.dart'; // Your main app file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KanairoXO',
      debugShowCheckedModeBanner: false,
      home: const KanairoXOApp(),
    );
  }
}
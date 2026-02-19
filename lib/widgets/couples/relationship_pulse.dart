import 'package:flutter/material.dart';

class RelationshipPulse extends StatelessWidget {
  const RelationshipPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Relationship Pulse'),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.75, // Example value
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 5),
            Text('75%'),
          ],
        ),
      ),
    );
  }
}

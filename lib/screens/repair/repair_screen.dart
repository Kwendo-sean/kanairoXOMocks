import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/repair/deescalation_tools_card.dart';
import 'package:kanairoxo/widgets/repair/guided_resolution_card.dart';
import 'package:kanairoxo/widgets/repair/safe_space_card.dart';

class RepairScreen extends StatelessWidget {
  const RepairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SafeSpaceCard(),
            SizedBox(height: 24),
            GuidedResolutionCard(),
            SizedBox(height: 24),
            DeescalationToolsCard(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kanairoxo/widgets/dates/date_categories.dart';
import 'package:kanairoxo/widgets/dates/date_idea_generator_card.dart';
import 'package:kanairoxo/widgets/dates/date_templates.dart';

class PlanDateScreen extends StatelessWidget {
  const PlanDateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan a Date'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: DateIdeaGeneratorCard(),
            ),
            SizedBox(height: 16),
            DateCategories(),
            DateTemplates(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

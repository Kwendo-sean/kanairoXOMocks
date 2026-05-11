import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/dates/date_stats.dart';
import 'package:kanairoxo/widgets/dates/past_date_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DatesHistoryScreen extends StatelessWidget {
  const DatesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date History'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: PhosphorIcon(PhosphorIcons.magnifyingGlass()),
            tooltip: 'Search',
          ),
        ],
      ),
      body: ListView(
        children: const [
          SizedBox(height: 16),
          DateStats(),
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'All Dates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          SizedBox(height: 8),
          PastDateCard(),
          PastDateCard(),
          SizedBox(height: 80), // FAB Spacing
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Plan Date Screen
        },
        label: const Text('Plan New Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: PhosphorIcon(PhosphorIcons.calendarPlus(), color: Colors.white),
        backgroundColor: AppConstants.primaryRed,
      ),
    );
  }
}

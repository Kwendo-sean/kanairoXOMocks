import 'package:flutter/material.dart';
import 'package:kanairoxo/models/moment.dart';
import 'package:kanairoxo/widgets/moment_card.dart';
import 'package:kanairoxo/utils/constants.dart';

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for screenshots
    final List<Moment> moments = _getSampleMoments();

    return Scaffold(
      backgroundColor: AppConstants.primaryBeige,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppConstants.primaryBeige,
            title: Text(
              'Moments',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlack,
              ),
            ),
            floating: true,
            pinned: true,
            elevation: 0,
          ),
          if (moments.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No moments yet. Go on some dates and attend events to create them!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppConstants.secondaryGray, fontSize: 16),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MomentCard(moment: moments[index]),
                    );
                  },
                  childCount: moments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // More sample data for moments
  List<Moment> _getSampleMoments() {
    return [
      Moment(
        id: '1',
        eventName: 'Art & Sip Workshop',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: MomentType.event,
        photoUrl: 'https://images.unsplash.com/photo-1515187029135-18ee286d815b?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
      Moment(
        id: '2',
        eventName: 'Dinner at The Carnivore',
        date: DateTime.now().subtract(const Duration(days: 15)),
        type: MomentType.date,
        photoUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
      Moment(
        id: '3',
        eventName: 'Blankets & Wine Festival',
        date: DateTime.now().subtract(const Duration(days: 30)),
        type: MomentType.event,
        photoUrl: 'https://images.unsplash.com/photo-1586922572364-3dd437ae10e2?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
       Moment(
        id: '4',
        eventName: 'Jazz Night at J\'s',
        date: DateTime.now().subtract(const Duration(days: 45)),
        type: MomentType.event,
        photoUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=2670&auto=format&fit=crop&ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
       Moment(
        id: '5',
        eventName: 'Hike at Karura Forest',
        date: DateTime.now().subtract(const Duration(days: 62)),
        type: MomentType.date,
        photoUrl: 'https://images.unsplash.com/photo-1542385152-75b583556c54?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
      ),
    ];
  }
}

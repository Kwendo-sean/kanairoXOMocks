import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:kanairoxo/utils/constants.dart';

class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Upcoming',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            side: const BorderSide(color: AppConstants.lightGray, width: 1.5),
          ),
          child: Column(
            children: [
              _buildEventTile(
                icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                iconColor: Colors.blue,
                title: 'Next Date Night',
                subtitle: 'Dinner at The Carnivore',
                trailing: 'In 3 days',
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildEventTile(
                icon: PhosphorIcons.gift(PhosphorIconsStyle.fill),
                iconColor: Colors.pink,
                title: '6 Month Anniversary',
                subtitle: 'Celebrating half a year!',
                trailing: 'July 25, 2024',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: PhosphorIcon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppConstants.secondaryGray)),
      trailing: Text(trailing, style: const TextStyle(color: AppConstants.secondaryGray, fontSize: 12)),
    );
  }
}

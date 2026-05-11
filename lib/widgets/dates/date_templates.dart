import 'package:flutter/material.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DateTemplates extends StatelessWidget {
  const DateTemplates({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Quick-start Templates',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        _buildTemplateTile(
          title: 'At-Home Movie Night',
          subtitle: 'Classic, cozy, and simple.',
          icon: PhosphorIcons.filmStrip(PhosphorIconsStyle.regular),
        ),
        _buildTemplateTile(
          title: 'Half-Day Adventure',
          subtitle: 'Explore a new neighborhood or park.',
          icon: PhosphorIcons.mapTrifold(PhosphorIconsStyle.regular),
        ),
         _buildTemplateTile(
          title: 'Spontaneous Local Coffee',
          subtitle: 'A quick 30-minute reconnect.',
          icon: PhosphorIcons.coffee(PhosphorIconsStyle.regular),
        ),
      ],
    );
  }

  Widget _buildTemplateTile({required String title, required String subtitle, required IconData icon}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppConstants.primaryRed.withOpacity(0.1),
        child: PhosphorIcon(icon, color: AppConstants.primaryRed, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppConstants.secondaryGray)),
      trailing: const Icon(Icons.chevron_right, color: AppConstants.secondaryGray),
      onTap: () {},
    );
  }
}

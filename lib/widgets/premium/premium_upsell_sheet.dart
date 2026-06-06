import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class PremiumUpsellSheet extends StatelessWidget {
  final String featureName;

  const PremiumUpsellSheet({super.key, required this.featureName});

  static void show(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumUpsellSheet(featureName: featureName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.amber, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Unlock $featureName',
            style: AppTypography.displaySmall.copyWith(color: Colors.white, fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This is a Premium feature. Unlock with KanairoXO+ for KES 499/mo.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LiquidGlassButton(
            width: double.infinity,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/premium');
            },
            child: const Text('Upgrade to KanairoXO+'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

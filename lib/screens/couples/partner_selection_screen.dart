import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/core/theme/app_radius.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanairoxo/widgets/glass_card.dart';

class PartnerSelectionScreen extends StatelessWidget {
  const PartnerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final coupleUsers = authProvider.coupleUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGlass.withOpacity(0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Who are you?',
                style: AppTypography.displayLarge,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Select your profile to continue to your shared space.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(height: 48),
              if (coupleUsers != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: coupleUsers
                        .map((user) => _buildPartnerProfile(context, user))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerProfile(BuildContext context, User user) {
    return GestureDetector(
      onTap: () {
        // This will update AuthProvider, triggering AuthGate to show CoupleHomeScreen
        context.read<AuthProvider>().setCoupleUser(user);
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primaryGlass,
                backgroundImage: user.profile?.mainProfilePhoto != null 
                  ? NetworkImage(user.profile!.mainProfilePhoto!) 
                  : null,
                child: user.profile?.mainProfilePhoto == null
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primary,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.firstName ?? 'Partner',
            style: AppTypography.displayMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGlass,
              borderRadius: AppRadius.full,
            ),
            child: Text(
              'Switch to',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/models/user_model.dart';
import 'package:kanairoxo/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PartnerSelectionScreen extends StatelessWidget {
  const PartnerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final coupleUsers = authProvider.coupleUsers;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5E6E6), Color(0xFFFAF7F4)],
              ),
            ),
          ),
          
          // KXO stamp watermark
          Center(
            child: Opacity(
              opacity: 0.04,
              child: Text(
                'KXO',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 180,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Who are you?',
                  style: AppTypography.screenTitle,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Select your profile to continue to your shared space.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 64),
                if (coupleUsers != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: coupleUsers
                          .map((user) => _buildAvatar(context, user))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, User user) {
    final photoUrl = user.profile?.mainProfilePhoto;

    return GestureDetector(
      onTap: () {
        context.read<AuthProvider>().setCoupleUser(user);
      },
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: photoUrl ?? '',
            imageBuilder: (ctx, img) => CircleAvatar(
              radius: 44,
              backgroundImage: img,
            ),
            placeholder: (ctx, url) => CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            errorWidget: (ctx, url, err) => CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.firstName ?? 'Partner',
            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999), // AppRadius.full is BorderRadius, instructions say 999
            ),
            child: Text(
              'Switch to',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

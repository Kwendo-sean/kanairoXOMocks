import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:kanairoxo/core/theme/app_colors.dart';
import 'package:kanairoxo/core/theme/app_typography.dart';
import 'package:kanairoxo/models/connection_models.dart';
import 'package:kanairoxo/services/api_client.dart';
import 'package:kanairoxo/utils/constants.dart';
import 'package:kanairoxo/widgets/safe_network_image.dart';
import 'package:kanairoxo/widgets/liquid_glass_button.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String userId;
  final String? requestId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ProfilePreviewScreen({
    super.key,
    required this.userId,
    this.requestId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final ApiClient _apiClient = ApiClient();
  ProfilePreviewModel? _profile;
  bool _loading = true;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('api/v1/profiles/${widget.userId}/preview/');
      setState(() {
        _profile = ProfilePreviewModel.fromJson(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : _profile == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _profile!;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    width: double.infinity,
                    child: SafeNetworkImage(url: p.profilePhotoUrl, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.4, 1.0],
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName,
                          style: AppTypography.displayMedium.copyWith(color: Colors.white, fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (p.neighborhood.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                                  const SizedBox(width: 3),
                                  Text(p.neighborhood,
                                      style: AppTypography.caption.copyWith(color: Colors.white70)),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            if (p.lifeStage.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.work_outline, size: 13, color: Colors.white70),
                                  const SizedBox(width: 3),
                                  Text(p.lifeStage,
                                      style: AppTypography.caption.copyWith(color: Colors.white70)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.headline.isNotEmpty) ...[
                      Text(
                        p.headline,
                        style: AppTypography.bodyMedium
                            .copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (p.bio.isNotEmpty) ...[
                      Text('About', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Text(p.bio, style: AppTypography.bodyMedium),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (p.interests.isNotEmpty) ...[
                      Text('Interests', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.interests
                            .map(
                              (i) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGlass,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                ),
                                child: Text(
                                  i,
                                  style: AppTypography.caption
                                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (p.moments.isNotEmpty) ...[
                      Row(
                        children: [
                          Text('Moments', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                          if (p.momentsAreLimited) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Public only',
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemCount: p.moments.length,
                        itemBuilder: (ctx, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SafeNetworkImage(url: p.moments[i].imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _responding ? null : widget.onDecline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'Decline',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: LiquidGlassButton(
                    size: LiquidButtonSize.xl,
                    onPressed: _responding ? null : widget.onAccept,
                    child: _responding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Accept', style: AppTypography.buttonText),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Could not load profile', style: AppTypography.bodyMedium),
          const SizedBox(height: 16),
          LiquidGlassButton(
            size: LiquidButtonSize.md,
            onPressed: _loadProfile,
            child: Text('Retry', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Drop-in replacements for CircularProgressIndicator.
/// Use Skeleton.feed() / Skeleton.grid() / Skeleton.list() / Skeleton.profileCard()
/// etc. on screens while data is loading.
class Skeleton {
  static Color _base(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1612)
      : const Color(0xFFE8E2D8);

  static Color _highlight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2E2820)
      : const Color(0xFFF5F0E8);

  static Widget block({
    required BuildContext context,
    double? width,
    double height = 16,
    double radius = 6,
  }) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base(context),
          borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }

  /// Vertical feed of card placeholders — moments, events, etc.
  static Widget feed(BuildContext context, {int count = 4}) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => _bigCard(context),
    );
  }

  /// 2-column grid of card placeholders — connections, gallery, etc.
  static Widget grid(BuildContext context, {int count = 6}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78),
      itemCount: count,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: _base(context),
        highlightColor: _highlight(context),
        child: Container(
          decoration: BoxDecoration(
            color: _base(context),
            borderRadius: BorderRadius.circular(20))),
      ),
    );
  }

  /// Row-style list — notifications, connections, messages, etc.
  static Widget list(BuildContext context, {int count = 6}) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => Row(children: [
        _circle(context, 48),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(context: context, width: 140, height: 12),
            const SizedBox(height: 8),
            block(context: context, width: double.infinity, height: 10),
          ])),
      ]),
    );
  }

  /// One big preview card (image area + caption).
  static Widget _bigCard(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: _base(context),
              borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 12),
          Container(width: 200, height: 14, color: _base(context)),
          const SizedBox(height: 8),
          Container(width: 120, height: 12, color: _base(context)),
        ],
      ),
    );
  }

  /// Single profile-card placeholder (discovery, profile preview, etc.).
  static Widget profileCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: _base(context),
        highlightColor: _highlight(context),
        child: Column(children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.48,
            decoration: BoxDecoration(
              color: _base(context),
              borderRadius: BorderRadius.circular(28))),
          const SizedBox(height: 16),
          Container(width: 240, height: 14, color: _base(context)),
          const SizedBox(height: 8),
          Container(width: 160, height: 12, color: _base(context)),
        ]),
      ),
    );
  }

  /// Full-screen reel placeholder — matches the EventsFeedTab trailer/memory card.
  static Widget reel(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    const baseC    = Color(0xFF1A1A1A);
    const shimmerC = Color(0xFF2E2E2E);
    return Shimmer.fromColors(
      baseColor: baseC,
      highlightColor: shimmerC,
      child: Container(
        width: double.infinity,
        height: h,
        color: baseC,
        child: Stack(children: [
          // Badge pill top-left
          Positioned(
            left: 20, bottom: 205,
            child: Container(
              width: 60, height: 18,
              decoration: BoxDecoration(
                color: shimmerC,
                borderRadius: BorderRadius.circular(4)),
            ),
          ),
          // Title block
          Positioned(
            left: 20, right: 20, bottom: 175,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: shimmerC,
                borderRadius: BorderRadius.circular(6)),
            ),
          ),
          // Venue block
          Positioned(
            left: 20, right: 80, bottom: 148,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: shimmerC,
                borderRadius: BorderRadius.circular(4)),
            ),
          ),
          // CTA pill button
          Positioned(
            left: 20, right: 20, bottom: 80,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: shimmerC,
                borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ]),
      ),
    );
  }

  static Widget _circle(BuildContext context, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: _base(context), shape: BoxShape.circle));
  }
}

import 'package:flutter/material.dart';

/// Filter presets shown in the moment editor. The `id` is what gets sent to
/// the backend so it can apply the corresponding ffmpeg filter chain.
class MomentFilter {
  final String id;
  final String label;
  final ColorFilter? colorFilter;

  const MomentFilter({required this.id, required this.label, this.colorFilter});

  static const presets = <MomentFilter>[
    MomentFilter(id: 'none', label: 'None'),

    MomentFilter(id: 'vivid', label: 'Vivid', colorFilter: ColorFilter.matrix([
      1.45, 0, 0, 0, 0,
      0, 1.45, 0, 0, 0,
      0, 0, 1.45, 0, 0,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'bw', label: 'B&W', colorFilter: ColorFilter.matrix([
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0.299, 0.587, 0.114, 0, 0,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'vintage', label: 'Vintage', colorFilter: ColorFilter.matrix([
      0.9, 0.5, 0.1, 0, 0,
      0.3, 0.8, 0.1, 0, 0,
      0.2, 0.3, 0.5, 0, 0,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'warm', label: 'Warm', colorFilter: ColorFilter.matrix([
      1.1, 0, 0, 0, 15,
      0, 1.05, 0, 0, 5,
      0, 0, 0.9, 0, -10,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'cool', label: 'Cool', colorFilter: ColorFilter.matrix([
      0.9, 0, 0, 0, -10,
      0, 1.0, 0, 0, 0,
      0, 0, 1.15, 0, 15,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'dramatic', label: 'Dramatic', colorFilter: ColorFilter.matrix([
      1.3, 0, 0, 0, -20,
      0, 1.3, 0, 0, -20,
      0, 0, 1.3, 0, -20,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'fade', label: 'Fade', colorFilter: ColorFilter.matrix([
      0.85, 0, 0, 0, 30,
      0, 0.85, 0, 0, 30,
      0, 0, 0.85, 0, 30,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'noir', label: 'Noir', colorFilter: ColorFilter.matrix([
      0.4, 0.6, 0.1, 0, -10,
      0.4, 0.6, 0.1, 0, -10,
      0.4, 0.6, 0.1, 0, -10,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'bright', label: 'Bright', colorFilter: ColorFilter.matrix([
      1.05, 0, 0, 0, 20,
      0, 1.05, 0, 0, 20,
      0, 0, 1.05, 0, 20,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'golden', label: 'Golden', colorFilter: ColorFilter.matrix([
      1.2, 0.1, 0, 0, 10,
      0.05, 1.1, 0, 0, 5,
      0, 0, 0.85, 0, -15,
      0, 0, 0, 1, 0,
    ])),

    MomentFilter(id: 'film', label: 'Film', colorFilter: ColorFilter.matrix([
      1.0, 0.05, 0, 0, -5,
      0, 0.95, 0, 0, 0,
      0, 0.05, 0.95, 0, 5,
      0, 0, 0, 1, 0,
    ])),
  ];

  static MomentFilter byId(String id) =>
      presets.firstWhere((f) => f.id == id, orElse: () => presets.first);
}

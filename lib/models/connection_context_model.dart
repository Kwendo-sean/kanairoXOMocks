import '../core/utils/url_helper.dart';

enum ContextType {
  sharedEvent,
  music,
  moments,
  hotspots,
  nextEvent,
  musicTeaser,
  unknown,
}

class ConnectionContextModel {
  final ContextType type;
  final Map<String, dynamic> data;
  
  ConnectionContextModel({
    required this.type,
    required this.data,
  });
  
  factory ConnectionContextModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] ?? '';
    final type = switch(typeStr) {
      'shared_event' => ContextType.sharedEvent,
      'music' => ContextType.music,
      'moments' => ContextType.moments,
      'hotspots' => ContextType.hotspots,
      'next_event' => ContextType.nextEvent,
      'music_teaser' => ContextType.musicTeaser,
      _ => ContextType.unknown,
    };
    return ConnectionContextModel(
      type: type,
      data: json['data'] is Map<String, dynamic> 
        ? json['data'] as Map<String, dynamic> 
        : {},
    );
  }
}

class SharedEventData {
  final String eventId;
  final String title;
  final String date;
  final String location;
  final String? coverImageUrl;
  
  SharedEventData({
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    this.coverImageUrl,
  });

  factory SharedEventData.fromMap(Map<String, dynamic> m) {
    return SharedEventData(
      eventId: m['event_id']?.toString() ?? '',
      title: m['title'] ?? '',
      date: m['date'] ?? '',
      location: m['location'] ?? '',
      coverImageUrl: UrlHelper.fixMediaUrl(m['cover_image_url']),
    );
  }
}

class MomentsData {
  final List<MomentPreview> photos;
  final int totalMoments;
  
  MomentsData({
    required this.photos,
    required this.totalMoments,
  });

  factory MomentsData.fromMap(Map<String, dynamic> m) {
    return MomentsData(
      photos: (m['photos'] as List? ?? [])
        .map((p) => MomentPreview.fromMap(p))
        .toList(),
      totalMoments: m['total_moments'] ?? 0,
    );
  }
}

class MomentPreview {
  final String id;
  final String imageUrl;
  final String caption;
  
  MomentPreview({
    required this.id,
    required this.imageUrl,
    required this.caption,
  });

  factory MomentPreview.fromMap(Map<String, dynamic> m) {
    return MomentPreview(
      id: m['id']?.toString() ?? '',
      imageUrl: UrlHelper.fixMediaUrl(m['image_url']),
      caption: m['caption'] ?? '',
    );
  }
}

class HotspotsData {
  final List<String> hotspots;
  final String neighborhood;
  final bool sameNeighborhood;
  
  HotspotsData({
    required this.hotspots,
    required this.neighborhood,
    required this.sameNeighborhood,
  });

  factory HotspotsData.fromMap(Map<String, dynamic> m) {
    return HotspotsData(
      hotspots: List<String>.from(m['hotspots'] ?? []),
      neighborhood: m['neighborhood'] ?? '',
      sameNeighborhood: m['same_neighborhood'] ?? false,
    );
  }
}

class NextEventData {
  final String eventId;
  final String title;
  final String date;
  final String location;
  final String? coverImageUrl;
  final bool isHosting;
  final int attendeeCount;
  
  NextEventData({
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    this.coverImageUrl,
    required this.isHosting,
    required this.attendeeCount,
  });

  factory NextEventData.fromMap(Map<String, dynamic> m) {
    return NextEventData(
      eventId: m['event_id']?.toString() ?? '',
      title: m['title'] ?? '',
      date: m['date'] ?? '',
      location: m['location'] ?? '',
      coverImageUrl: UrlHelper.fixMediaUrl(m['cover_image_url']),
      isHosting: m['is_hosting'] ?? false,
      attendeeCount: m['attendee_count'] ?? 0,
    );
  }
}

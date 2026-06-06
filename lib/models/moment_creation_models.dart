import 'dart:io';

enum MediaType { photo, video }

class MediaItem {
  final File file;
  final MediaType type;
  final int position;
  final int? durationMs;

  MediaItem({
    required this.file,
    required this.type,
    required this.position,
    this.durationMs,
  });
}

class MomentDraft {
  final String? id;
  final String caption;
  final String? location;
  final List<String> taggedUserIds;
  final String visibility; // Public, Connections, Close Friends
  final int? linkedEventId;
  final DateTime? scheduledAt;
  final List<MediaItem> media;

  MomentDraft({
    this.id,
    this.caption = '',
    this.location,
    this.taggedUserIds = const [],
    this.visibility = 'Public',
    this.linkedEventId,
    this.scheduledAt,
    this.media = const [],
  });

  MomentDraft copyWith({
    String? id,
    String? caption,
    String? location,
    List<String>? taggedUserIds,
    String? visibility,
    int? linkedEventId,
    DateTime? scheduledAt,
    List<MediaItem>? media,
  }) {
    return MomentDraft(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      visibility: visibility ?? this.visibility,
      linkedEventId: linkedEventId ?? this.linkedEventId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      media: media ?? this.media,
    );
  }
}

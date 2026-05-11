class SpotifyStatus {
  final bool connected;
  final String? spotifyUser;
  final String? profileImage;
  
  SpotifyStatus({
    required this.connected,
    this.spotifyUser,
    this.profileImage,
  });

  factory SpotifyStatus.fromJson(Map<String, dynamic> json) {
    return SpotifyStatus(
      connected: json['connected'] ?? false,
      spotifyUser: json['spotify_user'],
      profileImage: json['profile_image'],
    );
  }
}

class TrackModel {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String? imageUrl;
  final String? previewUrl;
  final String? spotifyUrl;
  final String? uri;
  final int durationMs;
  final bool? isPlaying;
  final int? progressMs;
  
  TrackModel({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    this.imageUrl,
    this.previewUrl,
    this.spotifyUrl,
    this.uri,
    required this.durationMs,
    this.isPlaying,
    this.progressMs,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      imageUrl: json['image_url'],
      previewUrl: json['preview_url'],
      spotifyUrl: json['spotify_url'],
      uri: json['uri'],
      durationMs: json['duration_ms'] ?? 0,
      isPlaying: json['is_playing'],
      progressMs: json['progress_ms'],
    );
  }
}

class ArtistModel {
  final String id;
  final String name;
  final List<String> genres;
  final String? imageUrl;
  final int popularity;
  
  ArtistModel({
    required this.id,
    required this.name,
    required this.genres,
    this.imageUrl,
    required this.popularity,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      imageUrl: json['image_url'],
      popularity: json['popularity'] ?? 0,
    );
  }
}

class MusicProfile {
  final List<ArtistModel> topArtists;
  final List<TrackModel> topTracks;
  final List<String> topGenres;
  final List<TrackModel> recentlyPlayed;
  final DateTime? lastSynced;
  
  MusicProfile({
    required this.topArtists,
    required this.topTracks,
    required this.topGenres,
    required this.recentlyPlayed,
    this.lastSynced,
  });

  factory MusicProfile.fromJson(Map<String, dynamic> json) {
    return MusicProfile(
      topArtists: (json['top_artists'] as List? ?? [])
        .map((a) => ArtistModel.fromJson(a as Map<String, dynamic>))
        .toList(),
      topTracks: (json['top_tracks'] as List? ?? [])
        .map((t) => TrackModel.fromJson(t as Map<String, dynamic>))
        .toList(),
      topGenres: List<String>.from(json['top_genres'] ?? []),
      recentlyPlayed: (json['recently_played'] as List? ?? [])
        .map((t) => TrackModel.fromJson(t as Map<String, dynamic>))
        .toList(),
      lastSynced: json['last_synced'] != null
        ? DateTime.tryParse(json['last_synced'])
        : null,
    );
  }
}

class MusicCompatibility {
  final double score;
  final double artistOverlap;
  final double genreOverlap;
  final List<String> sharedGenres;
  final bool hasSpotify;
  
  MusicCompatibility({
    required this.score,
    required this.artistOverlap,
    required this.genreOverlap,
    required this.sharedGenres,
    required this.hasSpotify,
  });

  factory MusicCompatibility.fromJson(Map<String, dynamic> json) {
    return MusicCompatibility(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      artistOverlap: (json['artist_overlap'] as num?)?.toDouble() ?? 0.0,
      genreOverlap: (json['genre_overlap'] as num?)?.toDouble() ?? 0.0,
      sharedGenres: List<String>.from(json['shared_genres'] ?? []),
      hasSpotify: json['has_spotify'] ?? false,
    );
  }
}

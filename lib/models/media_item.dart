enum MediaType {
  localFile,
  radioStation,
  cdTrack,
}

class MediaItem {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? artworkUrl;
  final String uri;
  final MediaType type;
  final Duration? duration;
  final Map<String, dynamic>? metadata;

  MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    required this.uri,
    required this.type,
    this.duration,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'uri': uri,
        'type': type.toString(),
        'duration': duration?.inSeconds,
        'metadata': metadata,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String?,
        album: json['album'] as String?,
        artworkUrl: json['artworkUrl'] as String?,
        uri: json['uri'] as String,
        type: MediaType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => MediaType.localFile,
        ),
        duration: json['duration'] != null
            ? Duration(seconds: json['duration'] as int)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  MediaItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    String? uri,
    MediaType? type,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) =>
      MediaItem(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        artworkUrl: artworkUrl ?? this.artworkUrl,
        uri: uri ?? this.uri,
        type: type ?? this.type,
        duration: duration ?? this.duration,
        metadata: metadata ?? this.metadata,
      );
}

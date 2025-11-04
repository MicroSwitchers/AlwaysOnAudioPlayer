class RadioStation {
  final String id;
  final String name;
  final String streamUrl;
  final String? country;
  final String? language;
  final String? genre;
  final String? logoUrl;
  final String? homepage;
  final int? bitrate;
  bool isFavorite;

  RadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.country,
    this.language,
    this.genre,
    this.logoUrl,
    this.homepage,
    this.bitrate,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'country': country,
        'language': language,
        'genre': genre,
        'logoUrl': logoUrl,
        'homepage': homepage,
        'bitrate': bitrate,
        'isFavorite': isFavorite,
      };

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
        id: json['id']?.toString() ?? json['stationuuid']?.toString() ?? '',
        name: json['name'] as String? ?? 'Unknown Station',
        streamUrl: json['streamUrl'] as String? ??
            json['url_resolved'] as String? ??
            json['url'] as String? ??
            '',
        country: json['country'] as String?,
        language: json['language'] as String?,
        genre: json['genre'] as String? ?? json['tags'] as String?,
        logoUrl: json['logoUrl'] as String? ?? json['favicon'] as String?,
        homepage: json['homepage'] as String?,
        bitrate: json['bitrate'] as int?,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  RadioStation copyWith({
    String? id,
    String? name,
    String? streamUrl,
    String? country,
    String? language,
    String? genre,
    String? logoUrl,
    String? homepage,
    int? bitrate,
    bool? isFavorite,
  }) =>
      RadioStation(
        id: id ?? this.id,
        name: name ?? this.name,
        streamUrl: streamUrl ?? this.streamUrl,
        country: country ?? this.country,
        language: language ?? this.language,
        genre: genre ?? this.genre,
        logoUrl: logoUrl ?? this.logoUrl,
        homepage: homepage ?? this.homepage,
        bitrate: bitrate ?? this.bitrate,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

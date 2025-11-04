import 'radio_station.dart';

/// Categories for curated radio stations
enum RadioCategory {
  indieMusic('Indie Music', 'Alternative and indie rock stations'),
  punk('Punk', 'Punk, ska, oi!, and hardcore music'),
  vintage('78s / Vintage Music', 'Classic recordings from the early 20th century'),
  eclectic('Eclectic', 'Diverse mix of genres and styles'),
  college('College Radio', 'University and community radio stations');

  final String displayName;
  final String description;

  const RadioCategory(this.displayName, this.description);
}

/// Extended radio station model for curated content
class CuratedRadioStation extends RadioStation {
  final RadioCategory category;
  final String officialName;
  final String description;
  final String? frequency;
  final String? address;
  final String? phone;
  final List<String> notes;

  CuratedRadioStation({
    required super.id,
    required super.name,
    required super.streamUrl,
    required this.category,
    required this.officialName,
    required this.description,
    super.country,
    super.language,
    super.genre,
    super.logoUrl,
    super.homepage,
    super.bitrate,
    this.frequency,
    this.address,
    this.phone,
    this.notes = const [],
  });

  /// Creates a CuratedRadioStation from a map
  factory CuratedRadioStation.fromMap(Map<String, dynamic> map) {
    return CuratedRadioStation(
      id: map['id'] as String,
      name: map['name'] as String,
      streamUrl: map['streamUrl'] as String,
      category: RadioCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => RadioCategory.eclectic,
      ),
      officialName: map['officialName'] as String,
      description: map['description'] as String,
      country: map['country'] as String?,
      language: map['language'] as String?,
      genre: map['genre'] as String?,
      logoUrl: map['logoUrl'] as String?,
      homepage: map['homepage'] as String?,
      bitrate: map['bitrate'] as int?,
      frequency: map['frequency'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      notes: (map['notes'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Converts this station to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'category': category.name,
      'officialName': officialName,
      'description': description,
      'country': country,
      'language': language,
      'genre': genre,
      'logoUrl': logoUrl,
      'homepage': homepage,
      'bitrate': bitrate,
      'frequency': frequency,
      'address': address,
      'phone': phone,
      'notes': notes,
    };
  }

  @override
  CuratedRadioStation copyWith({
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
    RadioCategory? category,
    String? officialName,
    String? description,
    String? frequency,
    String? address,
    String? phone,
    List<String>? notes,
  }) {
    return CuratedRadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      streamUrl: streamUrl ?? this.streamUrl,
      country: country ?? this.country,
      language: language ?? this.language,
      genre: genre ?? this.genre,
      logoUrl: logoUrl ?? this.logoUrl,
      homepage: homepage ?? this.homepage,
      bitrate: bitrate ?? this.bitrate,
      category: category ?? this.category,
      officialName: officialName ?? this.officialName,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    )..isFavorite = isFavorite ?? this.isFavorite;
  }
}

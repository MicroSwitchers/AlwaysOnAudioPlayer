import 'media_item.dart';

class Playlist {
  final String id;
  final String name;
  final List<MediaItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>)
            .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Playlist copyWith({
    String? id,
    String? name,
    List<MediaItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Playlist(
        id: id ?? this.id,
        name: name ?? this.name,
        items: items ?? this.items,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

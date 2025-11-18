import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/media_item.dart';

class LocalMusicService extends ChangeNotifier {
  final List<MediaItem> _localTracks = [];
  final List<String> _musicDirectories = [];
  bool _isScanning = false;

  List<MediaItem> get localTracks => List.unmodifiable(_localTracks);
  List<String> get musicDirectories => List.unmodifiable(_musicDirectories);
  bool get isScanning => _isScanning;

  final List<String> _supportedExtensions = [
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
    '.wma',
  ];

  Future<void> addMusicDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && !_musicDirectories.contains(selectedDirectory)) {
        _musicDirectories.add(selectedDirectory);
        notifyListeners();
        await scanDirectory(selectedDirectory);
      }
    } catch (e) {
      debugPrint('Error selecting directory: $e');
    }
  }

  Future<void> removeMusicDirectory(String path) async {
    _musicDirectories.remove(path);
    _localTracks.removeWhere((track) => track.uri.startsWith(path));
    notifyListeners();
  }

  Future<void> scanDirectory(String path) async {
    _isScanning = true;
    notifyListeners();

    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: $path');
        return;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final ext =
              entity.path.substring(entity.path.lastIndexOf('.')).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final mediaItem = await _createMediaItemFromFile(entity);
            if (mediaItem != null) {
              // Remove existing item with same path if exists
              _localTracks.removeWhere((item) => item.uri == entity.path);
              _localTracks.add(mediaItem);
            }
          }
        }
      }

      // Sort by title
      _localTracks.sort((a, b) => a.title.compareTo(b.title));
    } catch (e) {
      debugPrint('Error scanning directory: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> scanAllDirectories() async {
    for (final directory in _musicDirectories) {
      await scanDirectory(directory);
    }
  }

  Future<MediaItem?> _createMediaItemFromFile(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final titleWithExt = fileName.substring(0, fileName.lastIndexOf('.'));

      // Basic parsing of filename (can be enhanced with metadata reading)
      String title = titleWithExt;
      String? artist;
      String? album;

      // Try to parse Artist - Title format
      if (titleWithExt.contains(' - ')) {
        final parts = titleWithExt.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts[1].trim();
        }
      }

      return MediaItem(
        id: const Uuid().v4(),
        title: title,
        artist: artist,
        album: album,
        uri: file.path,
        type: MediaType.localFile,
        metadata: {
          'filePath': file.path,
          'fileSize': await file.length(),
          'lastModified': (await file.lastModified()).toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error creating media item from file: $e');
      return null;
    }
  }

  Future<List<MediaItem>> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        List<MediaItem> items = [];
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final mediaItem = await _createMediaItemFromFile(file);
            if (mediaItem != null) {
              items.add(mediaItem);
            }
          }
        }
        return items;
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
    return [];
  }

  List<MediaItem> searchTracks(String query) {
    if (query.isEmpty) return _localTracks;

    final lowerQuery = query.toLowerCase();
    return _localTracks.where((track) {
      return track.title.toLowerCase().contains(lowerQuery) ||
          (track.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
          (track.album?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<String> getAlbums() {
    final albums = <String>{};
    for (final track in _localTracks) {
      if (track.album != null && track.album!.isNotEmpty) {
        albums.add(track.album!);
      }
    }
    return albums.toList()..sort();
  }

  List<String> getArtists() {
    final artists = <String>{};
    for (final track in _localTracks) {
      if (track.artist != null && track.artist!.isNotEmpty) {
        artists.add(track.artist!);
      }
    }
    return artists.toList()..sort();
  }

  List<MediaItem> getTracksByAlbum(String album) {
    return _localTracks.where((track) => track.album == album).toList();
  }

  List<MediaItem> getTracksByArtist(String artist) {
    return _localTracks.where((track) => track.artist == artist).toList();
  }
}

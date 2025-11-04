import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/media_item.dart';

class MusicLibraryService extends ChangeNotifier {
  Database? _database;
  final List<MediaItem> _libraryTracks = [];
  final List<String> _libraryFolders = [];
  bool _isScanning = false;
  bool _isInitialized = false;

  List<MediaItem> get libraryTracks => List.unmodifiable(_libraryTracks);
  List<String> get libraryFolders => List.unmodifiable(_libraryFolders);
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;

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

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    await _initDatabase();
    await _loadLibrary();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _initDatabase() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = path.join(appDocDir.path, 'music_library.db');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create library_folders table
        await db.execute('''
          CREATE TABLE library_folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT UNIQUE NOT NULL,
            added_date TEXT NOT NULL
          )
        ''');

        // Create library_tracks table
        await db.execute('''
          CREATE TABLE library_tracks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            file_path TEXT UNIQUE NOT NULL,
            file_size INTEGER,
            duration_seconds INTEGER,
            last_modified TEXT,
            added_date TEXT NOT NULL
          )
        ''');

        // Create index for faster searches
        await db.execute('CREATE INDEX idx_title ON library_tracks(title)');
        await db.execute('CREATE INDEX idx_artist ON library_tracks(artist)');
        await db.execute('CREATE INDEX idx_album ON library_tracks(album)');
      },
    );
  }

  Future<void> _loadLibrary() async {
    if (_database == null) return;

    // Load folders
    final folderResults =
        await _database!.query('library_folders', orderBy: 'path ASC');
    _libraryFolders.clear();
    for (final row in folderResults) {
      _libraryFolders.add(row['path'] as String);
    }

    // Load tracks
    final trackResults =
        await _database!.query('library_tracks', orderBy: 'title ASC');
    _libraryTracks.clear();
    for (final row in trackResults) {
      _libraryTracks.add(_mediaItemFromDb(row));
    }

    notifyListeners();
  }

  MediaItem _mediaItemFromDb(Map<String, dynamic> row) {
    return MediaItem(
      id: row['id'] as String,
      title: row['title'] as String,
      artist: row['artist'] as String?,
      album: row['album'] as String?,
      uri: row['file_path'] as String,
      type: MediaType.localFile,
      duration: row['duration_seconds'] != null
          ? Duration(seconds: row['duration_seconds'] as int)
          : null,
      metadata: {
        'filePath': row['file_path'],
        'fileSize': row['file_size'],
        'lastModified': row['last_modified'],
        'addedDate': row['added_date'],
      },
    );
  }

  Future<void> addFolder(String folderPath) async {
    if (_database == null) return;
    if (_libraryFolders.contains(folderPath)) return;

    try {
      // Add folder to database
      await _database!.insert('library_folders', {
        'path': folderPath,
        'added_date': DateTime.now().toIso8601String(),
      });

      _libraryFolders.add(folderPath);
      notifyListeners();

      // Scan the folder for music files
      await scanFolder(folderPath);
    } catch (e) {
      debugPrint('Error adding folder: $e');
    }
  }

  Future<void> removeFolder(String folderPath) async {
    if (_database == null) return;

    try {
      // Remove folder from database
      await _database!.delete(
        'library_folders',
        where: 'path = ?',
        whereArgs: [folderPath],
      );

      // Remove all tracks from this folder
      await _database!.delete(
        'library_tracks',
        where: 'file_path LIKE ?',
        whereArgs: ['$folderPath%'],
      );

      _libraryFolders.remove(folderPath);
      _libraryTracks.removeWhere((track) => track.uri.startsWith(folderPath));
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing folder: $e');
    }
  }

  Future<void> scanFolder(String folderPath) async {
    _isScanning = true;
    notifyListeners();

    try {
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: $folderPath');
        return;
      }

      int addedCount = 0;
      int updatedCount = 0;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(ext)) {
            final added = await _addOrUpdateTrack(entity);
            if (added == true) {
              addedCount++;
            } else if (added == false) {
              updatedCount++;
            }
          }
        }
      }

      debugPrint('Scan complete: $addedCount added, $updatedCount updated');
      await _loadLibrary(); // Reload from database
    } catch (e) {
      debugPrint('Error scanning folder: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool?> _addOrUpdateTrack(File file) async {
    if (_database == null) return null;

    try {
      final filePath = file.path;
      final fileStat = await file.stat();
      final lastModified = fileStat.modified;

      // Check if track exists
      final existing = await _database!.query(
        'library_tracks',
        where: 'file_path = ?',
        whereArgs: [filePath],
      );

      if (existing.isNotEmpty) {
        // Check if file was modified
        final existingModified =
            DateTime.parse(existing.first['last_modified'] as String);
        if (lastModified.isAfter(existingModified)) {
          // Update existing track
          await _updateTrack(file, fileStat);
          return false; // Updated
        }
        return null; // No change
      } else {
        // Add new track
        await _insertTrack(file, fileStat);
        return true; // Added
      }
    } catch (e) {
      debugPrint('Error adding/updating track: $e');
      return null;
    }
  }

  Future<void> _insertTrack(File file, FileStat fileStat) async {
    if (_database == null) return;

    final fileName = path.basenameWithoutExtension(file.path);
    String title = fileName;
    String? artist;
    String? album;

    // Try to parse Artist - Title format
    if (fileName.contains(' - ')) {
      final parts = fileName.split(' - ');
      if (parts.length >= 2) {
        artist = parts[0].trim();
        title = parts[1].trim();
      }
    }

    await _database!.insert('library_tracks', {
      'id': const Uuid().v4(),
      'title': title,
      'artist': artist,
      'album': album,
      'file_path': file.path,
      'file_size': fileStat.size,
      'duration_seconds': null,
      'last_modified': fileStat.modified.toIso8601String(),
      'added_date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateTrack(File file, FileStat fileStat) async {
    if (_database == null) return;

    await _database!.update(
      'library_tracks',
      {
        'file_size': fileStat.size,
        'last_modified': fileStat.modified.toIso8601String(),
      },
      where: 'file_path = ?',
      whereArgs: [file.path],
    );
  }

  Future<void> rescanAll() async {
    for (final folder in _libraryFolders) {
      await scanFolder(folder);
    }
  }

  Future<void> cleanupMissingFiles() async {
    if (_database == null) return;

    _isScanning = true;
    notifyListeners();

    try {
      int removedCount = 0;

      for (final track in List.from(_libraryTracks)) {
        final file = File(track.uri);
        if (!await file.exists()) {
          await _database!.delete(
            'library_tracks',
            where: 'id = ?',
            whereArgs: [track.id],
          );
          removedCount++;
        }
      }

      debugPrint('Cleanup complete: $removedCount missing files removed');
      await _loadLibrary();
    } catch (e) {
      debugPrint('Error cleaning up: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  List<MediaItem> searchTracks(String query) {
    if (query.isEmpty) return _libraryTracks;

    final lowerQuery = query.toLowerCase();
    return _libraryTracks.where((track) {
      return track.title.toLowerCase().contains(lowerQuery) ||
          (track.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
          (track.album?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  List<String> getAlbums() {
    final albums = <String>{};
    for (final track in _libraryTracks) {
      if (track.album != null && track.album!.isNotEmpty) {
        albums.add(track.album!);
      }
    }
    return albums.toList()..sort();
  }

  List<String> getArtists() {
    final artists = <String>{};
    for (final track in _libraryTracks) {
      if (track.artist != null && track.artist!.isNotEmpty) {
        artists.add(track.artist!);
      }
    }
    return artists.toList()..sort();
  }

  List<MediaItem> getTracksByAlbum(String album) {
    return _libraryTracks.where((track) => track.album == album).toList();
  }

  List<MediaItem> getTracksByArtist(String artist) {
    return _libraryTracks.where((track) => track.artist == artist).toList();
  }

  @override
  Future<void> dispose() async {
    await _database?.close();
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/media_item.dart';
import 'storage_service.dart';

class PlaylistService extends ChangeNotifier {
  final StorageService _storageService;
  List<Playlist> _playlists = [];
  bool _isLoading = false;

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  bool get isLoading => _isLoading;

  PlaylistService(this._storageService) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();

    try {
      final playlistsData = await _storageService.loadPlaylists();
      _playlists = playlistsData;
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      _playlists = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Playlist> createPlaylist(String name) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: '${now.millisecondsSinceEpoch}',
      name: name,
      items: [],
      createdAt: now,
      updatedAt: now,
    );

    _playlists.add(playlist);
    await _savePlaylists();
    notifyListeners();

    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index] = _playlists[index].copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, MediaItem track) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      // Check if track already exists
      if (!playlist.items.any((item) => item.id == track.id)) {
        final updatedItems = List<MediaItem>.from(playlist.items)..add(track);
        _playlists[index] = playlist.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        await _savePlaylists();
        notifyListeners();
      }
    }
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final updatedItems =
          playlist.items.where((item) => item.id != trackId).toList();
      _playlists[index] = playlist.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      await _savePlaylists();
      notifyListeners();
    }
  }

  Future<void> reorderTracksInPlaylist(
      String playlistId, int oldIndex, int newIndex) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      final playlist = _playlists[index];
      final items = List<MediaItem>.from(playlist.items);

      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      _playlists[index] = playlist.copyWith(
        items: items,
        updatedAt: DateTime.now(),
      );
      await _savePlaylists();
      notifyListeners();
    }
  }

  Playlist? getPlaylist(String playlistId) {
    try {
      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePlaylists() async {
    await _storageService.savePlaylists(_playlists);
  }
}

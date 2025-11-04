import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../models/playlist.dart';

class StorageService {
  static const String _keyFavoriteRadios = 'favorite_radios';
  static const String _keyMusicDirectories = 'music_directories';
  static const String _keyPlaylists = 'playlists';
  static const String _keyCdDrivePath = 'cd_drive_path';
  static const String _keyVolume = 'volume';
  static const String _keyLastPlayedUri = 'last_played_uri';
  static const String _keyPlayerBarPosition = 'player_bar_position';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorite Radio Stations
  Future<void> saveFavoriteRadios(List<RadioStation> stations) async {
    final jsonList = stations.map((s) => s.toJson()).toList();
    await _prefs?.setString(_keyFavoriteRadios, json.encode(jsonList));
  }

  Future<List<RadioStation>> loadFavoriteRadios() async {
    final jsonString = _prefs?.getString(_keyFavoriteRadios);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => RadioStation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading favorite radios: $e');
      return [];
    }
  }

  // Music Directories
  Future<void> saveMusicDirectories(List<String> directories) async {
    await _prefs?.setStringList(_keyMusicDirectories, directories);
  }

  Future<List<String>> loadMusicDirectories() async {
    return _prefs?.getStringList(_keyMusicDirectories) ?? [];
  }

  // Playlists
  Future<void> savePlaylists(List<Playlist> playlists) async {
    final jsonList = playlists.map((p) => p.toJson()).toList();
    await _prefs?.setString(_keyPlaylists, json.encode(jsonList));
  }

  Future<List<Playlist>> loadPlaylists() async {
    final jsonString = _prefs?.getString(_keyPlaylists);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      return [];
    }
  }

  // CD Drive Path
  Future<void> saveCdDrivePath(String path) async {
    await _prefs?.setString(_keyCdDrivePath, path);
  }

  Future<String?> loadCdDrivePath() async {
    return _prefs?.getString(_keyCdDrivePath);
  }

  // Volume
  Future<void> saveVolume(double volume) async {
    await _prefs?.setDouble(_keyVolume, volume);
  }

  Future<double> loadVolume() async {
    return _prefs?.getDouble(_keyVolume) ?? 0.7;
  }

  // Last Played URI
  Future<void> saveLastPlayedUri(String uri) async {
    await _prefs?.setString(_keyLastPlayedUri, uri);
  }

  Future<String?> loadLastPlayedUri() async {
    return _prefs?.getString(_keyLastPlayedUri);
  }

  // Player Bar Position
  Future<void> savePlayerBarPosition(String position) async {
    await _prefs?.setString(_keyPlayerBarPosition, position);
  }

  Future<String?> loadPlayerBarPosition() async {
    return _prefs?.getString(_keyPlayerBarPosition);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}

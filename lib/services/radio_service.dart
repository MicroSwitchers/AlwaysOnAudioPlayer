import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';

class RadioService extends ChangeNotifier {
  static const String _baseUrl = 'de1.api.radio-browser.info';

  final List<RadioStation> _searchResults = [];
  final List<RadioStation> _favoriteStations = [];
  bool _isSearching = false;
  String? _errorMessage;

  List<RadioStation> get searchResults => List.unmodifiable(_searchResults);
  List<RadioStation> get favoriteStations =>
      List.unmodifiable(_favoriteStations);
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // Search stations by name
  Future<void> searchByName(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/json/stations/byname/$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _searchResults.clear();

        for (final item in data) {
          try {
            final station = RadioStation.fromJson(item);
            // Check if this station is in favorites
            final favoriteIndex =
                _favoriteStations.indexWhere((fav) => fav.id == station.id);
            if (favoriteIndex >= 0) {
              station.isFavorite = true;
            }
            _searchResults.add(station);
          } catch (e) {
            debugPrint('Error parsing station: $e');
          }
        }
      } else {
        _errorMessage = 'Failed to search stations: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      debugPrint('Error searching stations: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Search stations by country
  Future<void> searchByCountry(String country) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/json/stations/bycountry/$country');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _searchResults.clear();

        for (final item in data) {
          try {
            final station = RadioStation.fromJson(item);
            final favoriteIndex =
                _favoriteStations.indexWhere((fav) => fav.id == station.id);
            if (favoriteIndex >= 0) {
              station.isFavorite = true;
            }
            _searchResults.add(station);
          } catch (e) {
            debugPrint('Error parsing station: $e');
          }
        }
      } else {
        _errorMessage = 'Failed to search stations: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      debugPrint('Error searching stations: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Search stations by genre/tag
  Future<void> searchByTag(String tag) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/json/stations/bytag/$tag');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _searchResults.clear();

        for (final item in data) {
          try {
            final station = RadioStation.fromJson(item);
            final favoriteIndex =
                _favoriteStations.indexWhere((fav) => fav.id == station.id);
            if (favoriteIndex >= 0) {
              station.isFavorite = true;
            }
            _searchResults.add(station);
          } catch (e) {
            debugPrint('Error parsing station: $e');
          }
        }
      } else {
        _errorMessage = 'Failed to search stations: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      debugPrint('Error searching stations: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Get popular stations
  Future<void> getPopularStations({int limit = 50}) async {
    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.https(_baseUrl, '/json/stations/topvote/$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _searchResults.clear();

        for (final item in data) {
          try {
            final station = RadioStation.fromJson(item);
            final favoriteIndex =
                _favoriteStations.indexWhere((fav) => fav.id == station.id);
            if (favoriteIndex >= 0) {
              station.isFavorite = true;
            }
            _searchResults.add(station);
          } catch (e) {
            debugPrint('Error parsing station: $e');
          }
        }
      } else {
        _errorMessage =
            'Failed to get popular stations: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      debugPrint('Error getting popular stations: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Toggle favorite status
  void toggleFavorite(RadioStation station) {
    final index = _favoriteStations.indexWhere((s) => s.id == station.id);

    if (index >= 0) {
      _favoriteStations.removeAt(index);
      station.isFavorite = false;
    } else {
      station.isFavorite = true;
      _favoriteStations.add(station.copyWith(isFavorite: true));
    }

    // Update in search results too
    final searchIndex = _searchResults.indexWhere((s) => s.id == station.id);
    if (searchIndex >= 0) {
      _searchResults[searchIndex].isFavorite = station.isFavorite;
    }

    notifyListeners();
  }

  bool isFavorite(String stationId) {
    return _favoriteStations.any((s) => s.id == stationId);
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  // Load favorites from storage (will be called by storage service)
  void loadFavorites(List<RadioStation> favorites) {
    _favoriteStations.clear();
    _favoriteStations.addAll(favorites);
    notifyListeners();
  }
}

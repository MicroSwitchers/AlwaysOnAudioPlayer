import 'package:flutter/foundation.dart';
import '../models/curated_radio_station.dart';

/// Service for managing curated radio stations
class CuratedRadioService extends ChangeNotifier {
  final List<CuratedRadioStation> _stations = [];
  bool _isLoading = false;

  List<CuratedRadioStation> get stations => List.unmodifiable(_stations);
  bool get isLoading => _isLoading;

  /// Get stations by category
  List<CuratedRadioStation> getStationsByCategory(RadioCategory category) {
    return _stations.where((s) => s.category == category).toList();
  }

  /// Get all categories that have stations
  List<RadioCategory> get availableCategories {
    return RadioCategory.values
        .where((category) => _stations.any((s) => s.category == category))
        .toList();
  }

  /// Initialize the service with curated stations
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stations.clear();
      _stations.addAll(_getCuratedStations());
    } catch (e) {
      debugPrint('Error initializing curated radio service: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle favorite status for a station
  void toggleFavorite(CuratedRadioStation station) {
    final index = _stations.indexWhere((s) => s.id == station.id);
    if (index != -1) {
      _stations[index].isFavorite = !_stations[index].isFavorite;
      notifyListeners();
    }
  }

  /// Get the predefined curated radio stations
  List<CuratedRadioStation> _getCuratedStations() {
    return [
      // 78'S / VINTAGE MUSIC
      CuratedRadioStation(
        id: 'arctic-outpost-am1270',
        name: 'Arctic Outpost Radio AM1270',
        officialName: 'Arctic Outpost Radio AM1270',
        streamUrl: 'http://216.126.196.154:4047/stream/',
        category: RadioCategory.vintage,
        description:
            'Broadcasts vintage 78 rpm records from 1902-1958. Features Big Band, Jazz, Swing, Vintage Country, and Blues from Nordic countries and USA from the 1930s-40s.',
        country: 'Svalbard and Jan Mayen (Norway)',
        language: 'English',
        genre: 'Big Band, Jazz, Swing, Vintage Country, Blues',
        homepage: 'https://www.aor.am/',
        logoUrl: 'https://www.aor.am/images/logo.png',
        bitrate: 128,
        notes: [
          'Broadcasting from 77° latitude',
          'Commercial-free, streams vintage shellac recordings',
          '"Spinning the 78\'s from the top of the world"',
          'Direct stream: 128kbps MP3',
          'Alternative: http://airplanegobrr.us.to:8000/stream/arctic_outpost',
        ],
      ),

      // COLLEGE RADIO
      CuratedRadioStation(
        id: 'kxlu-889',
        name: 'KXLU 88.9 FM',
        officialName: 'KXLU 88.9 FM',
        streamUrl: 'http://kxlu.streamguys1.com:80/kxlu-hi',
        category: RadioCategory.college,
        description:
            "Loyola Marymount University's college radio station. Non-commercial, freeform programming with diverse eclectic range including rock, punk, jazz, hip-hop, Latin jazz, and world music.",
        country: 'United States',
        language: 'English',
        genre: 'Rock, Punk, Jazz, Hip-Hop, Latin Jazz, World Music',
        homepage: 'https://kxlu.com/',
        frequency: '88.9 FM',
        address: 'One LMU Drive, Malone 402, Los Angeles, CA 90045',
        phone: '310-338-2866',
        bitrate: 320,
        notes: [
          'Broadcasting since 1957',
          'Famous for the "Demolisten" show (since 1984)',
          'Introduced bands like Jane\'s Addiction, Red Hot Chili Peppers, and Guns N\' Roses',
          'Commercial-free, broadcasts 24/7/365',
          'High quality 320kbps MP3 stream',
          'Alternative streams: 48kbps AAC+ (http://kxlu.streamguys1.com:80/kxlu-lo)',
        ],
      ),

      // KEXP SEATTLE
      CuratedRadioStation(
        id: 'kexp-903',
        name: 'KEXP 90.3 FM',
        officialName: 'KEXP-FM 90.3',
        streamUrl: 'https://kexp.streamguys1.com/kexp160.aac',
        category: RadioCategory.college,
        description:
            'Legendary Seattle radio station. Non-commercial, listener-supported station known for championing new and emerging artists. Features indie rock, electronic, hip-hop, world music, and more.',
        country: 'United States',
        language: 'English',
        genre: 'Indie Rock, Electronic, Hip-Hop, World Music, Eclectic',
        homepage: 'https://www.kexp.org/',
        frequency: '90.3 FM',
        address: '472 1st Avenue North, Seattle, WA 98109',
        bitrate: 160,
        notes: [
          'Broadcasting since 1972 (as KCMU), rebranded as KEXP in 2001',
          'One of the most influential indie radio stations in the world',
          'Known for breaking artists like Nirvana, Death Cab for Cutie, The Shins',
          'Features live in-studio performances and DJ-curated programming',
          '24/7 commercial-free broadcasting',
          'High quality 160kbps AAC stream',
          'Alternative streams: 128kbps MP3 (http://kexp-mp3-128.streamguys1.com/kexp128.mp3)',
        ],
      ),
    ];
  }
}

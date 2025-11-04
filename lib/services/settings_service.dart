import 'package:flutter/foundation.dart';
import 'storage_service.dart';

enum NavigationBarPosition {
  bottom,
  top,
  left,
  right,
}

class SettingsService extends ChangeNotifier {
  final StorageService _storage;
  NavigationBarPosition _navigationBarPosition = NavigationBarPosition.bottom;

  SettingsService(this._storage) {
    _loadSettings();
  }

  NavigationBarPosition get navigationBarPosition => _navigationBarPosition;

  Future<void> _loadSettings() async {
    try {
      final positionString = await _storage.loadPlayerBarPosition();
      if (positionString != null) {
        _navigationBarPosition = NavigationBarPosition.values.firstWhere(
          (e) => e.name == positionString,
          orElse: () => NavigationBarPosition.bottom,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setNavigationBarPosition(NavigationBarPosition position) async {
    if (_navigationBarPosition != position) {
      _navigationBarPosition = position;
      await _storage.savePlayerBarPosition(position.name);
      notifyListeners();
    }
  }
}

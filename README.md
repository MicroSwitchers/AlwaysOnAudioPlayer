# AlwaysOnAudioPlayer

A comprehensive Flutter-based media player interface optimized for Raspberry Pi with 5-inch touchscreens. This application supports local music playback, internet radio streaming, and curated radio stations. Designed for Linux, Windows, and web platforms.

## 🎯 Optimized for Raspberry Pi 5" Displays
- **Auto-scaling UI** for 800x480 screens
- **Touch-optimized** controls (44px minimum targets)
- **Performance tuned** for Raspberry Pi 3B+ and newer
- **Low memory footprint** suitable for 2GB+ devices
- **Configurable navigation** (bottom/top/left/right positions)

📖 **See [RASPBERRY_PI_SETUP.md](RASPBERRY_PI_SETUP.md)** for complete installation guide
📊 **See [RPI_5INCH_OPTIMIZATIONS.md](RPI_5INCH_OPTIMIZATIONS.md)** for optimization details

## Features

### Local Music Player
- Browse and play local audio files (MP3, FLAC, WAV, OGG, etc.)
- Add multiple music directories
- Search functionality for tracks, artists, and albums
- Automatic directory scanning
- Playlist support

### Internet Radio
- Search radio stations by name, country, or genre
- Browse popular stations
- Favorite stations for quick access
- Integration with Radio Browser API
- Display station metadata and artwork

### Curated Radio Stations
- Hand-picked quality radio stations
- Arctic Outpost AM1270 - Ambient/atmospheric music
- KXLU 88.9 FM - College radio from Los Angeles
- KEXP 90.3 FM - Eclectic music from Seattle
- More curated stations available

### Player Features
- Full playback controls (play, pause, skip, seek)
- Shuffle and repeat modes
- Volume control
- Now playing bar with track info
- Full-screen player interface
- Progress tracking

## Requirements

### For All Platforms
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### For Raspberry Pi
- Raspberry Pi 3B+ or newer (Pi 4 or 5 recommended)
- 2GB+ RAM (4GB+ recommended)
- 5-inch touchscreen display (800x480 recommended)

## Installation

### 1. Clone the Project

```bash
git clone https://github.com/MicroSwitchers/AlwaysOnAudioPlayer.git
cd AlwaysOnAudioPlayer
```

### 2. Install Dependencies

```bash
flutter pub get
```

## Running the Application

### On Linux (Native)

```bash
flutter run -d linux
```

### On Web

```bash
flutter run -d chrome
```

Or build for web deployment:

```bash
flutter build web
```

The built files will be in `build/web/` directory.

### On Raspberry Pi

For optimal performance on Raspberry Pi:

```bash
# Enable Linux desktop support if not already enabled
flutter config --enable-linux-desktop

# Run the app
flutter run -d linux --release
```

## Configuration

### Music Directories

To add music directories:

1. Navigate to the Local Music tab
2. Tap the folder icon in the app bar
3. Select your music directory
4. The app will automatically scan for audio files

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── media_item.dart
│   ├── playlist.dart
│   └── radio_station.dart
├── services/                      # Business logic
│   ├── audio_player_service.dart
│   ├── music_library_service.dart
│   ├── local_music_service.dart
│   ├── radio_service.dart
│   ├── curated_radio_service.dart
│   ├── playlist_service.dart
│   ├── settings_service.dart
│   └── storage_service.dart
├── screens/                       # UI screens
│   ├── home_screen.dart
│   ├── library_screen.dart
│   ├── local_music_screen.dart
│   ├── radio_screen.dart
│   ├── curated_radio_screen.dart
│   └── playlists_screen.dart
└── widgets/                       # Reusable UI components
    ├── media_list_item.dart
    ├── now_playing_bar.dart
    └── player_controls.dart
```

## Key Technologies

- **Flutter**: Cross-platform UI framework
- **just_audio**: Audio playback engine
- **provider**: State management
- **Radio Browser API**: Internet radio station database
- **shared_preferences**: Local data persistence

## Platform Support

| Feature | Web | Linux | Windows | Notes |
|---------|-----|-------|---------|-------|
| Local Music | ✅ | ✅ | ✅ | File picker works on all |
| Internet Radio | ✅ | ✅ | ✅ | Fully supported |
| Curated Radio | ✅ | ✅ | ✅ | Fully supported |
| Playlists | ✅ | ✅ | ✅ | Local storage based |
| File System Access | Limited | ✅ | ✅ | Web has browser restrictions |

## Troubleshooting

### Audio Not Playing

1. Check system audio settings
2. Verify audio files are in supported formats
3. For radio: Check internet connection
4. Check app volume settings

### Performance Issues on Raspberry Pi

1. Use release mode: `flutter run --release`
2. Close background applications
3. Consider using a lighter desktop environment
4. Reduce UI animations if needed

## Development

### Adding New Features

The app uses Provider for state management. To add new features:

1. Create/modify models in `lib/models/`
2. Implement business logic in `lib/services/`
3. Create UI in `lib/screens/` or `lib/widgets/`
4. Register providers in `main.dart`

### Building for Production

**Linux:**
```bash
flutter build linux --release
```

**Web:**
```bash
flutter build web --release
```

## License

This project is open source and available for personal and commercial use.

## Credits

- Radio station data provided by [Radio Browser](https://www.radio-browser.info/)
- Audio playback powered by [just_audio](https://pub.dev/packages/just_audio)

## Future Enhancements

- [ ] Album artwork display and editing
- [ ] Advanced playlist management (export/import)
- [ ] Equalizer controls
- [ ] Podcast support
- [ ] Cloud music integration (Spotify, etc.)
- [ ] Last.fm scrobbling
- [ ] Sleep timer
- [ ] Lyrics display
- [ ] Voice control integration

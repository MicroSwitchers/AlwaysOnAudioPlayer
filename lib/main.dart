import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/audio_player_service.dart';
import 'services/music_library_service.dart';
import 'services/radio_service.dart';
import 'services/curated_radio_service.dart';
import 'services/playlist_service.dart';
import 'services/storage_service.dart';
import 'services/settings_service.dart';
import 'services/window_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('=== App Starting ===');
    
    // Initialize storage service
    debugPrint('Initializing storage service...');
    final storageService = StorageService();
    await storageService.init();
    debugPrint('Storage service initialized successfully');

    // Initialize window manager for desktop platforms
    debugPrint('Initializing window service...');
    await WindowService.initialize();
    debugPrint('Window service initialized successfully');

    debugPrint('Starting app...');
    runApp(MyApp(storageService: storageService));
  } catch (e, stack) {
    debugPrint('FATAL ERROR in main: $e');
    debugPrint('Stack trace: $stack');
    // Run a minimal error app
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => MusicLibraryService()),
        ChangeNotifierProvider(create: (_) => RadioService()),
        ChangeNotifierProvider(create: (_) => CuratedRadioService()),
        ChangeNotifierProvider(
          create: (_) => PlaylistService(widget.storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsService(widget.storageService),
        ),
        Provider.value(value: widget.storageService),
      ],
      child: Consumer<AudioPlayerService>(
        builder: (context, audioPlayer, _) {
          // Initialize services after providers are created
          _initializeServices(context);

          return MaterialApp(
            title: 'RPI Media Interface',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: const HomeScreen(),
            // Optimize for performance on Raspberry Pi
            showPerformanceOverlay: false,
            checkerboardRasterCacheImages: false,
            checkerboardOffscreenLayers: false,
            builder: (context, child) {
              // Apply text scaling for small screens
              final mediaQuery = MediaQuery.of(context);
              final size = mediaQuery.size;
              final isSmallScreen = size.shortestSide < 500;
              
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaleFactor: isSmallScreen ? 0.9 : 1.0,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  void _initializeServices(BuildContext context) {
    if (_initialized) return;
    _initialized = true;

    // Load saved data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final musicLibrary = context.read<MusicLibraryService>();
      final radioService = context.read<RadioService>();
      final curatedRadioService = context.read<CuratedRadioService>();
      final audioPlayer = context.read<AudioPlayerService>();

      // Initialize music library (loads folders and tracks from database)
      await musicLibrary.init();

      // Initialize curated radio stations
      await curatedRadioService.initialize();

      // Load favorite radio stations
      final favoriteRadios = await widget.storageService.loadFavoriteRadios();
      radioService.loadFavorites(favoriteRadios);

      // Load and set volume
      final volume = await widget.storageService.loadVolume();
      audioPlayer.setVolume(volume);

      radioService.addListener(() {
        widget.storageService.saveFavoriteRadios(radioService.favoriteStations);
      });
    });
  }
}

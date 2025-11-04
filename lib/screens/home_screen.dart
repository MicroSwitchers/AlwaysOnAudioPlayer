import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../utils/layout_config.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/glass_container.dart';
import 'library_screen.dart';
import 'radio_screen.dart';
import 'curated_radio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(), // Contains Tracks & Playlists tabs
    const RadioScreen(),
    const CuratedRadioScreen(), // Curated internet radio stations
  ];

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final hasCurrentMedia = playerService.currentMedia != null;

    final isCompact = LayoutConfig.isCompact(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(_selectedIndex),
                  child: _screens[_selectedIndex],
                ),
              ),
            ),
            if (hasCurrentMedia) const NowPlayingBar(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          LayoutConfig.horizontalPadding(context),
          0,
          LayoutConfig.horizontalPadding(context),
          LayoutConfig.verticalPadding(context),
        ),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            height: LayoutConfig.navigationBarHeight(context),
            labelBehavior: isCompact
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.library_music_rounded),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.radio_rounded),
                label: 'Radio',
              ),
              NavigationDestination(
                icon: Icon(Icons.stars_rounded),
                label: 'Curated',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

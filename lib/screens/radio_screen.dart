import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/radio_service.dart';
import '../services/audio_player_service.dart';
import '../models/radio_station.dart';
import '../models/media_item.dart';
import '../utils/layout_config.dart';
import '../widgets/radio_station_item.dart';
import '../services/window_service.dart';
import '../widgets/glass_container.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load popular stations on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioService>().getPopularStations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioService = Provider.of<RadioService>(context);
    final isCompact = LayoutConfig.isCompact(context);
    final horizontalPadding = LayoutConfig.horizontalPadding(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: horizontalPadding,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withValues(alpha: 0.7),
                colorScheme.surface.withValues(alpha: 0.24),
                colorScheme.surface.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.secondary,
                    colorScheme.primary,
                  ],
                ),
              ),
              child: const Icon(Icons.radio_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Internet Radio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.onSurface,
            ),
            onSelected: (value) async {
              if (value == 'fullscreen') {
                await WindowService.toggleFullscreen(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'fullscreen',
                child: Row(
                  children: [
                    Icon(Icons.fullscreen),
                    SizedBox(width: 8),
                    Text('Toggle Fullscreen'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: LayoutConfig.verticalPadding(context),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: colorScheme.surface.withValues(alpha: 0.55),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isCompact,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.95),
                      colorScheme.primary.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor:
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                tabs: const [
                  Tab(icon: Icon(Icons.explore_rounded), text: 'Browse'),
                  Tab(icon: Icon(Icons.favorite_rounded), text: 'Favorites'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          LayoutConfig.verticalPadding(context),
          horizontalPadding,
          LayoutConfig.verticalPadding(context) * 1.2,
        ),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(28),
          padding: EdgeInsets.symmetric(
            horizontal: LayoutConfig.isCompact(context) ? 12 : 20,
            vertical: LayoutConfig.isCompact(context) ? 12 : 20,
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBrowseTab(radioService),
              _buildFavoritesTab(radioService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseTab(RadioService radioService) {
    final playerService = Provider.of<AudioPlayerService>(context);

    return Column(
      children: [
        Padding(
          padding: LayoutConfig.pagePadding(context).copyWith(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search stations...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              radioService.clearSearchResults();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      radioService.searchByName(value);
                    }
                  },
                ),
              ),
              SizedBox(width: LayoutConfig.horizontalPadding(context) * 0.5),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                iconSize: 22,
                tooltip: 'Quick filters',
                onSelected: (value) {
                  switch (value) {
                    case 'popular':
                      radioService.getPopularStations();
                      break;
                    case 'genre_rock':
                      radioService.searchByTag('rock');
                      break;
                    case 'genre_pop':
                      radioService.searchByTag('pop');
                      break;
                    case 'genre_jazz':
                      radioService.searchByTag('jazz');
                      break;
                    case 'genre_classical':
                      radioService.searchByTag('classical');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'popular',
                    child: Text('Popular Stations'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'genre_rock',
                    child: Text('Rock'),
                  ),
                  const PopupMenuItem(
                    value: 'genre_pop',
                    child: Text('Pop'),
                  ),
                  const PopupMenuItem(
                    value: 'genre_jazz',
                    child: Text('Jazz'),
                  ),
                  const PopupMenuItem(
                    value: 'genre_classical',
                    child: Text('Classical'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Stats bar
        if (radioService.searchResults.isNotEmpty && !radioService.isSearching)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: LayoutConfig.horizontalPadding(context),
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.radio_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${radioService.searchResults.length} stations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        if (radioService.isSearching)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (radioService.errorMessage != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: LayoutConfig.pagePadding(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connection Error',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      radioService.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => radioService.getPopularStations(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (radioService.searchResults.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.radio_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Discover Radio Stations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for stations or browse by genre',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: LayoutConfig.verticalPadding(context) * 2,
              ),
              itemCount: radioService.searchResults.length,
              itemBuilder: (context, index) {
                final station = radioService.searchResults[index];
                final isPlaying =
                    playerService.currentMedia?.id == station.id &&
                        playerService.playerState == PlayerState.playing;
                return RadioStationItem(
                  station: station,
                  isPlaying: isPlaying,
                  onTap: () => _playStation(station),
                  onFavoriteTap: () => radioService.toggleFavorite(station),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesTab(RadioService radioService) {
    final playerService = Provider.of<AudioPlayerService>(context);

    if (radioService.favoriteStations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse and tap the heart icon to save your\nfavorite radio stations',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Browse Stations'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats bar for favorites
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutConfig.horizontalPadding(context),
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${radioService.favoriteStations.length} favorite${radioService.favoriteStations.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: LayoutConfig.verticalPadding(context),
              bottom: LayoutConfig.verticalPadding(context) * 2,
            ),
            itemCount: radioService.favoriteStations.length,
            itemBuilder: (context, index) {
              final station = radioService.favoriteStations[index];
              final isPlaying = playerService.currentMedia?.id == station.id &&
                  playerService.playerState == PlayerState.playing;
              return RadioStationItem(
                station: station,
                isPlaying: isPlaying,
                onTap: () => _playStation(station),
                onFavoriteTap: () => radioService.toggleFavorite(station),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playStation(RadioStation station) {
    final playerService = context.read<AudioPlayerService>();

    final mediaItem = MediaItem(
      id: station.id,
      title: station.name,
      artist: station.country ?? 'Internet Radio',
      album: station.genre,
      artworkUrl: station.logoUrl,
      uri: station.streamUrl,
      type: MediaType.radioStation,
      metadata: {
        'homepage': station.homepage,
        'bitrate': station.bitrate,
        'language': station.language,
      },
    );

    playerService.play(mediaItem);
  }
}

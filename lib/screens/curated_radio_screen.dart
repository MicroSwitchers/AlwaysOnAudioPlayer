import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curated_radio_station.dart';
import '../models/media_item.dart';
import '../services/curated_radio_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/glass_container.dart';
import '../utils/layout_config.dart';

// Import PlayerState enum
export '../services/audio_player_service.dart' show PlayerState;

class CuratedRadioScreen extends StatefulWidget {
  const CuratedRadioScreen({super.key});

  @override
  State<CuratedRadioScreen> createState() => _CuratedRadioScreenState();
}

class _CuratedRadioScreenState extends State<CuratedRadioScreen> {
  RadioCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<CuratedRadioService>();
      service.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final curatedService = Provider.of<CuratedRadioService>(context);
    final playerService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Curated Radio',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          LayoutConfig.horizontalPadding(context),
          LayoutConfig.verticalPadding(context),
          LayoutConfig.horizontalPadding(context),
          LayoutConfig.verticalPadding(context) + 80, // Extra padding for now playing bar
        ),
        child: curatedService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(curatedService, playerService),
      ),
    );
  }

  Widget _buildContent(
    CuratedRadioService curatedService,
    AudioPlayerService playerService,
  ) {
    final categories = curatedService.availableCategories;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.radio_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No curated stations available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category sidebar
        SizedBox(
          width: 200,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      final stationCount = curatedService
                          .getStationsByCategory(category)
                          .length;

                      return _buildCategoryItem(
                        category,
                        stationCount,
                        isSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Stations list
        Expanded(
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            child: _selectedCategory == null
                ? _buildAllStationsView(curatedService, playerService)
                : _buildCategoryStationsView(
                    curatedService,
                    playerService,
                    _selectedCategory!,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    RadioCategory category,
    int stationCount,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = isSelected ? null : category;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$stationCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllStationsView(
    CuratedRadioService curatedService,
    AudioPlayerService playerService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'All Curated Stations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: curatedService.stations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final station = curatedService.stations[index];
              return _buildStationCard(station, playerService, curatedService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStationsView(
    CuratedRadioService curatedService,
    AudioPlayerService playerService,
    RadioCategory category,
  ) {
    final stations = curatedService.getStationsByCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final station = stations[index];
              return _buildStationCard(station, playerService, curatedService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard(
    CuratedRadioStation station,
    AudioPlayerService playerService,
    CuratedRadioService curatedService,
  ) {
    final isPlaying = playerService.currentMedia?.id == station.id &&
        playerService.playerState == PlayerState.playing;

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playStation(station, playerService),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Play button / Now playing indicator
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: isPlaying
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Station info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            station.officialName,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                          if (station.frequency != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              station.frequency!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        station.category.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  station.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                // Metadata row
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (station.country != null)
                      _buildMetadataChip(
                        Icons.flag_rounded,
                        station.country!,
                      ),
                    if (station.genre != null)
                      _buildMetadataChip(
                        Icons.music_note_rounded,
                        station.genre!,
                      ),
                    if (station.homepage != null)
                      _buildMetadataChip(
                        Icons.language_rounded,
                        'Website',
                        onTap: () {
                          // TODO: Open in browser
                        },
                      ),
                  ],
                ),
                // Notes
                if (station.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final note in station.notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  void _playStation(
    CuratedRadioStation station,
    AudioPlayerService playerService,
  ) {
    final mediaItem = MediaItem(
      id: station.id,
      title: station.name,
      artist: station.country ?? 'Internet Radio',
      album: station.genre,
      artworkUrl: station.logoUrl,
      uri: station.streamUrl,
      type: MediaType.radioStation,
      metadata: {
        'officialName': station.officialName,
        'description': station.description,
        'homepage': station.homepage,
        'bitrate': station.bitrate,
        'frequency': station.frequency,
        'category': station.category.displayName,
      },
    );

    if (playerService.currentMedia?.id == station.id) {
      if (playerService.playerState == PlayerState.playing) {
        playerService.pause();
      } else {
        playerService.resume();
      }
    } else {
      playerService.play(mediaItem);
    }
  }
}

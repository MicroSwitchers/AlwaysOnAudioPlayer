import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/playlist_service.dart';
import '../models/media_item.dart';
import '../utils/layout_config.dart';
import 'player_controls.dart';
import 'audio_visualizer.dart';
import 'animated_progress_bar.dart';
import 'glass_container.dart';

class NowPlayingBar extends StatelessWidget {
  final Axis orientation;
  
  const NowPlayingBar({
    super.key,
    this.orientation = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final media = playerService.currentMedia;

    if (media == null) return const SizedBox.shrink();

    final isCompact = LayoutConfig.isCompact(context);
    final progress = playerService.duration.inSeconds > 0
        ? playerService.position.inSeconds / playerService.duration.inSeconds
        : 0.0;

    if (orientation == Axis.vertical) {
      return _buildVerticalBar(context, playerService, media, progress, isCompact);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        LayoutConfig.horizontalPadding(context),
        LayoutConfig.verticalPadding(context),
        LayoutConfig.horizontalPadding(context),
        LayoutConfig.verticalPadding(context) * 0.5,
      ),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(28),
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _showFullPlayer(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedProgressBar(
                  progress: progress,
                  isPlaying: playerService.playerState == PlayerState.playing,
                  isLoading: playerService.playerState == PlayerState.loading,
                  primaryColor: Theme.of(context).colorScheme.secondary,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.18),
                  height: 3,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: LayoutConfig.horizontalPadding(context),
                    vertical: LayoutConfig.verticalPadding(context),
                  ),
                  child: Row(
                    children: [
                      // Animated artwork with playing indicator and visualizer
                      Hero(
                        tag: 'now_playing_artwork',
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isCompact ? 52 : 56,
                              height: isCompact ? 52 : 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(context).colorScheme.tertiary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(
                                            alpha: playerService.playerState ==
                                                    PlayerState.playing
                                                ? 0.5
                                                : 0.3),
                                    blurRadius: playerService.playerState ==
                                            PlayerState.playing
                                        ? 12
                                        : 8,
                                    spreadRadius: playerService.playerState ==
                                            PlayerState.playing
                                        ? 2
                                        : 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon at top
                                  Icon(
                                    _getMediaIcon(media.type),
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  // Visualizer below icon
                                  if (playerService.playerState ==
                                      PlayerState.playing)
                                    AudioVisualizer(
                                      isPlaying: true,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withValues(alpha: 0.8),
                                        Colors.cyan.shade200,
                                        Colors.purple.shade200,
                                      ],
                                      barCount: 5,
                                      width: 32,
                                      height: 14,
                                      animateColors: true,
                                    )
                                  else
                                    const SizedBox(height: 14),
                                ],
                              ),
                            ),
                            if (playerService.playerState ==
                                PlayerState.playing)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Track info with better typography
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              media.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (media.artist != null)
                                  Flexible(
                                    child: Text(
                                      media.artist!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withValues(alpha: 0.75),
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (media.artist != null &&
                                    playerService.duration.inSeconds > 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ),
                                if (playerService.duration.inSeconds > 0)
                                  Text(
                                    _formatDuration(playerService.duration),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Playback controls with better touch targets
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Add to playlist button
                          IconButton(
                            iconSize: 24,
                            icon: const Icon(Icons.playlist_add_rounded),
                            onPressed: () => _showAddToPlaylist(context, media),
                            tooltip: 'Add to playlist',
                          ),
                          if (playerService.hasPrevious && !isCompact)
                            IconButton(
                              iconSize: 24,
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: () => playerService.previous(),
                              tooltip: 'Previous',
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 30,
                              icon: Icon(
                                playerService.playerState == PlayerState.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (playerService.playerState ==
                                    PlayerState.playing) {
                                  playerService.pause();
                                } else {
                                  playerService.resume();
                                }
                              },
                              tooltip: playerService.playerState ==
                                      PlayerState.playing
                                  ? 'Pause'
                                  : 'Play',
                            ),
                          ),
                          if (playerService.hasNext && !isCompact)
                            IconButton(
                              iconSize: 24,
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: () => playerService.next(),
                              tooltip: 'Next',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, MediaItem media) {
    // Import the playlist service to access it
    final playlistService =
        Provider.of<PlaylistService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded),
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog(
                          context, playlistService, media);
                    },
                    tooltip: 'Create new playlist',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: playlistService.playlists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.queue_music_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No playlists yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCreatePlaylistDialog(
                                  context, playlistService, media);
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Playlist'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: playlistService.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistService.playlists[index];
                        final alreadyAdded =
                            playlist.items.any((item) => item.id == media.id);

                        return ListTile(
                          leading: const Icon(Icons.queue_music_rounded),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.items.length} tracks'),
                          trailing: alreadyAdded
                              ? Icon(Icons.check_circle_rounded,
                                  color: Theme.of(context).colorScheme.primary)
                              : const Icon(Icons.add_circle_outline_rounded),
                          onTap: alreadyAdded
                              ? null
                              : () {
                                  playlistService.addTrackToPlaylist(
                                      playlist.id, media);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Added to "${playlist.name}"'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, PlaylistService playlistService, MediaItem media) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            hintText: 'My Playlist',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final playlist = await playlistService
                    .createPlaylist(controller.text.trim());
                await playlistService.addTrackToPlaylist(playlist.id, media);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created playlist "${playlist.name}"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.localFile:
        return Icons.music_note_rounded;
      case MediaType.radioStation:
        return Icons.radio_rounded;
      case MediaType.cdTrack:
        return Icons.album_rounded;
    }
  }

  Widget _buildVerticalBar(
    BuildContext context,
    AudioPlayerService playerService,
    MediaItem media,
    double progress,
    bool isCompact,
  ) {
    return Container(
      width: 80,
      padding: EdgeInsets.symmetric(
        vertical: LayoutConfig.verticalPadding(context),
        horizontal: LayoutConfig.horizontalPadding(context) * 0.5,
      ),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(28),
        padding: EdgeInsets.symmetric(
          vertical: LayoutConfig.verticalPadding(context),
          horizontal: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _showFullPlayer(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Artwork
                Hero(
                  tag: 'now_playing_artwork',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(
                                  alpha: playerService.playerState ==
                                          PlayerState.playing
                                      ? 0.5
                                      : 0.3),
                          blurRadius:
                              playerService.playerState == PlayerState.playing
                                  ? 12
                                  : 8,
                          spreadRadius:
                              playerService.playerState == PlayerState.playing
                                  ? 2
                                  : 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getMediaIcon(media.type),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        if (playerService.playerState == PlayerState.playing)
                          AudioVisualizer(
                            isPlaying: true,
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.8),
                              Colors.cyan.shade200,
                              Colors.purple.shade200,
                            ],
                            barCount: 5,
                            width: 32,
                            height: 14,
                            animateColors: true,
                          )
                        else
                          const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Play/Pause button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    iconSize: 28,
                    icon: Icon(
                      playerService.playerState == PlayerState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (playerService.playerState == PlayerState.playing) {
                        playerService.pause();
                      } else {
                        playerService.resume();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Previous button
                if (playerService.hasPrevious)
                  IconButton(
                    iconSize: 22,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => playerService.previous(),
                  ),
                // Next button
                if (playerService.hasNext)
                  IconButton(
                    iconSize: 22,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => playerService.next(),
                  ),
                const Spacer(),
                // Vertical progress indicator
                RotatedBox(
                  quarterTurns: 0,
                  child: SizedBox(
                    width: 56,
                    height: 4,
                    child: AnimatedProgressBar(
                      progress: progress,
                      isPlaying:
                          playerService.playerState == PlayerState.playing,
                      isLoading:
                          playerService.playerState == PlayerState.loading,
                      primaryColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.18),
                      height: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const FullScreenPlayer(),
      ),
    );
  }
}

class FullScreenPlayer extends StatelessWidget {
  const FullScreenPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlayerControls();
  }
}

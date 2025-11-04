import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../services/audio_player_service.dart';
import '../services/window_service.dart';
import '../utils/layout_config.dart';
import 'audio_visualizer.dart';
import 'glass_container.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});
  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final media = playerService.currentMedia;
    final isCompact = LayoutConfig.isCompact(context);
    final controlsDiameter = LayoutConfig.controlButtonDiameter(context);
    if (media == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No track playing',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to list',
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _showMoreOptions(context, playerService, media),
            tooltip: 'More options',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutConfig.horizontalPadding(context) * 1.2,
            vertical: LayoutConfig.verticalPadding(context) * 1.2,
          ),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(isCompact ? 28 : 36),
            padding: EdgeInsets.symmetric(
              horizontal: LayoutConfig.horizontalPadding(context) *
                  (isCompact ? 1.1 : 1.4),
              vertical: LayoutConfig.verticalPadding(context) * 1.4,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildArtwork(context, playerService, media, isCompact),
                  SizedBox(height: isCompact ? 24 : 32),
                  _buildTrackInfo(context, media, isCompact),
                  SizedBox(height: isCompact ? 24 : 32),
                  _buildProgressSection(context, playerService),
                  SizedBox(height: isCompact ? 24 : 32),
                  _buildControlsRow(
                    context: context,
                    playerService: playerService,
                    media: media,
                    controlsDiameter: controlsDiameter,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(
    BuildContext context,
    AudioPlayerService playerService,
    MediaItem media,
    bool isCompact,
  ) {
    final isPlaying = playerService.playerState == PlayerState.playing;
    return Hero(
      tag: 'now_playing_artwork',
      child: Container(
        width: double.infinity,
        height: isCompact ? 240 : 320,
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: isPlaying ? 0.5 : 0.35),
              blurRadius: isPlaying ? 32 : 24,
              spreadRadius: isPlaying ? 6 : 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getMediaIcon(media.type),
                  size: isCompact ? 80 : 100,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 20),
                if (isPlaying)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AudioVisualizer(
                      isPlaying: true,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.75),
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      barCount: isCompact ? 24 : 34,
                      width: isCompact ? 200 : 280,
                      height: isCompact ? 48 : 70,
                      animateColors: true,
                    ),
                  ),
              ],
            ),
            if (isPlaying)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo(
    BuildContext context,
    MediaItem media,
    bool isCompact,
  ) {
    return Column(
      children: [
        Text(
          media.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: isCompact ? 22 : 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 6),
        if (media.artist != null)
          Text(
            media.artist!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        if (media.album != null) ...[
          const SizedBox(height: 4),
          Text(
            media.album!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    AudioPlayerService playerService,
  ) {
    final totalSeconds = math.max(playerService.duration.inSeconds, 1);
    final positionSeconds =
        playerService.position.inSeconds.clamp(0, totalSeconds);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutConfig.horizontalPadding(context) * 0.6,
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: Theme.of(context).colorScheme.secondary,
              inactiveTrackColor: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.2),
            ),
            child: Slider(
              value: positionSeconds.toDouble(),
              max: totalSeconds.toDouble(),
              onChanged: (value) {
                playerService.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(playerService.position),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                _formatDuration(playerService.duration),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow({
    required BuildContext context,
    required AudioPlayerService playerService,
    required MediaItem media,
    required double controlsDiameter,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularIconButton(
          context: context,
          isActive: playerService.isShuffleEnabled,
          icon: Icons.shuffle_rounded,
          tooltip: 'Shuffle',
          onPressed: () => playerService.toggleShuffle(),
        ),
        const SizedBox(width: 16),
        _buildSimpleIconButton(
          context: context,
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous',
          onPressed:
              playerService.hasPrevious ? () => playerService.previous() : null,
        ),
        const SizedBox(width: 20),
        _buildPlayPauseButton(
          context: context,
          playerService: playerService,
          media: media,
          diameter: controlsDiameter,
        ),
        const SizedBox(width: 20),
        _buildSimpleIconButton(
          context: context,
          icon: Icons.skip_next_rounded,
          tooltip: 'Next',
          onPressed: playerService.hasNext ? () => playerService.next() : null,
        ),
        const SizedBox(width: 16),
        _buildLoopButton(context: context, playerService: playerService),
      ],
    );
  }

  Widget _buildCircularIconButton({
    required BuildContext context,
    required bool isActive,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.primary,
                ],
              )
            : null,
        color: isActive
            ? null
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 24,
        icon: Icon(
          icon,
          color: isActive
              ? Colors.white
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.7),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildSimpleIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 32,
        icon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildPlayPauseButton({
    required BuildContext context,
    required AudioPlayerService playerService,
    required MediaItem media,
    required double diameter,
  }) {
    return Container(
      width: diameter + 12,
      height: diameter + 12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: IconButton(
        iconSize: diameter * 0.55,
        icon: Icon(
          playerService.playerState == PlayerState.playing
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          if (playerService.playerState == PlayerState.playing) {
            playerService.pause();
          } else if (playerService.playerState == PlayerState.paused) {
            playerService.resume();
          } else {
            playerService.play(media);
          }
        },
        tooltip:
            playerService.playerState == PlayerState.playing ? 'Pause' : 'Play',
      ),
    );
  }

  Widget _buildLoopButton({
    required BuildContext context,
    required AudioPlayerService playerService,
  }) {
    final isActive = playerService.loopMode != LoopMode.off;
    return Container(
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.tertiary,
                  Theme.of(context).colorScheme.secondary,
                ],
              )
            : null,
        color: isActive
            ? null
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 24,
        icon: Icon(
          _getLoopIcon(playerService.loopMode),
          color: isActive
              ? Colors.white
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.7),
        ),
        onPressed: () {
          final nextMode = _getNextLoopMode(playerService.loopMode);
          playerService.setLoopMode(nextMode);
        },
        tooltip: _getLoopTooltip(playerService.loopMode),
      ),
    );
  }

  void _showMoreOptions(
    BuildContext context,
    AudioPlayerService playerService,
    MediaItem media,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: hook into playlist management once implemented.
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: integrate sharing flow.
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Track details'),
              onTap: () {
                Navigator.pop(context);
                _showTrackDetails(context, media);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fullscreen_rounded),
              title: const Text('Toggle Fullscreen'),
              onTap: () async {
                Navigator.of(context).pop();
                await WindowService.toggleFullscreen(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackDetails(BuildContext context, MediaItem media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Title', media.title),
            if (media.artist != null) _detailRow('Artist', media.artist!),
            if (media.album != null) _detailRow('Album', media.album!),
            _detailRow('Type', _getMediaTypeName(media.type)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _getMediaTypeName(MediaType type) {
    switch (type) {
      case MediaType.localFile:
        return 'Local File';
      case MediaType.radioStation:
        return 'Radio Station';
      case MediaType.cdTrack:
        return 'CD Track';
    }
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

  String _getLoopTooltip(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return 'Loop: Off';
      case LoopMode.all:
        return 'Loop: All';
      case LoopMode.one:
        return 'Loop: One';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
  }

  IconData _getLoopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.all:
        return Icons.repeat_on;
      case LoopMode.one:
        return Icons.repeat_one_on;
    }
  }

  LoopMode _getNextLoopMode(LoopMode current) {
    switch (current) {
      case LoopMode.off:
        return LoopMode.all;
      case LoopMode.all:
        return LoopMode.one;
      case LoopMode.one:
        return LoopMode.off;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cd_player_service.dart';
import '../services/audio_player_service.dart';
import '../utils/layout_config.dart';
import '../widgets/media_list_item.dart';

class CdPlayerScreen extends StatefulWidget {
  const CdPlayerScreen({super.key});

  @override
  State<CdPlayerScreen> createState() => _CdPlayerScreenState();
}

class _CdPlayerScreenState extends State<CdPlayerScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-detect CD on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CdPlayerService>().detectCd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cdService = Provider.of<CdPlayerService>(context);
    final playerService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.album_rounded, size: 24),
            SizedBox(width: 8),
            Text('CD Player'),
          ],
        ),
        actions: [
          if (cdService.isScanning)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else
            IconButton(
              iconSize: 24,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => cdService.detectCd(),
              tooltip: 'Detect CD',
            ),
          if (cdService.isCdLoaded)
            IconButton(
              iconSize: 24,
              icon: const Icon(Icons.eject_rounded),
              onPressed: () => _confirmEject(context, cdService),
              tooltip: 'Eject CD',
            ),
          IconButton(
            iconSize: 24,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _showSettings(context, cdService),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _buildBody(cdService, playerService),
    );
  }

  Widget _buildBody(
      CdPlayerService cdService, AudioPlayerService playerService) {
    if (cdService.isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning CD...'),
          ],
        ),
      );
    }

    if (cdService.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                cdService.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                cdService.clearError();
                cdService.detectCd();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (!cdService.isCdLoaded || cdService.cdTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.album, size: 96, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'No CD detected',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Insert an audio CD and tap refresh',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => cdService.detectCd(),
              icon: const Icon(Icons.refresh),
              label: const Text('Detect CD'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutConfig.horizontalPadding(context),
            vertical: LayoutConfig.verticalPadding(context) * 1.5,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.album_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: LayoutConfig.horizontalPadding(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio CD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cdService.cdTracks.length} tracks',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              FloatingActionButton.extended(
                heroTag: 'cd_play_all',
                onPressed: () {
                  if (cdService.cdTracks.isNotEmpty) {
                    playerService.playPlaylist(cdService.cdTracks, 0);
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Play All'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: LayoutConfig.verticalPadding(context) * 0.5,
              bottom: LayoutConfig.verticalPadding(context) * 2,
            ),
            itemCount: cdService.cdTracks.length,
            itemBuilder: (context, index) {
              final track = cdService.cdTracks[index];
              final isPlaying = playerService.currentMedia?.id == track.id &&
                  playerService.playerState == PlayerState.playing;

              return MediaListItem(
                media: track,
                isPlaying: isPlaying,
                onTap: () {
                  playerService.playPlaylist(cdService.cdTracks, index);
                },
                showTrackNumber: true,
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmEject(BuildContext context, CdPlayerService cdService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eject CD?'),
        content: const Text('Are you sure you want to eject the CD?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cdService.ejectCd();
            },
            child: const Text('Eject'),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, CdPlayerService cdService) {
    final controller = TextEditingController(text: cdService.cdDrivePath);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CD Player Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'CD Drive Path',
                hintText: '/dev/cdrom',
                helperText: 'Path to your CD drive device',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Windows: Set drive letter (e.g., D:\\). Audio CDs are played using Windows MCI. Data CDs with audio files are also supported.\n\nLinux: Use device path and install cdparanoia for audio CD support.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cdService.setCdDrivePath(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CD drive path updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

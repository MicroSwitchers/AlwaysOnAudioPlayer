import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/playlist_service.dart';
import '../services/audio_player_service.dart';
import '../models/playlist.dart';
import '../utils/layout_config.dart';
import '../widgets/media_list_item.dart';

enum _PlaylistAction { rename, delete }

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final playlistService = Provider.of<PlaylistService>(context);
    final playerService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.queue_music_rounded, size: 24),
            SizedBox(width: 8),
            Text('Playlists'),
          ],
        ),
      ),
      body: playlistService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playlistService.playlists.isEmpty
              ? _buildEmptyState(context, playlistService)
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: LayoutConfig.verticalPadding(context),
                    bottom: LayoutConfig.verticalPadding(context) * 2 + 80,
                  ),
                  itemCount: playlistService.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlistService.playlists[index];
                    return _buildPlaylistCard(
                        context, playlist, playerService, playlistService);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlaylistDialog(context, playlistService),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Playlist'),
        tooltip: 'Create new playlist',
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, PlaylistService playlistService) {
    return Center(
      child: Padding(
        padding: LayoutConfig.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.queue_music_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No playlists yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create playlists to organize your favorite tracks',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _showCreatePlaylistDialog(context, playlistService),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Playlist'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist,
      AudioPlayerService playerService, PlaylistService playlistService) {
    final isCompact = LayoutConfig.isCompact(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: LayoutConfig.horizontalPadding(context),
        vertical: LayoutConfig.verticalPadding(context) * 0.5,
      ),
      child: InkWell(
        onTap: () => _openPlaylist(context, playlist, playerService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(LayoutConfig.horizontalPadding(context)),
          child: Row(
            children: [
              // Playlist icon
              Container(
                width: isCompact ? 56 : 64,
                height: isCompact ? 56 : 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  size: isCompact ? 28 : 32,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: LayoutConfig.horizontalPadding(context)),
              // Playlist info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.items.length} ${playlist.items.length == 1 ? 'track' : 'tracks'}',
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playlist.items.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      onPressed: () {
                        playerService.playPlaylist(playlist.items, 0);
                      },
                      tooltip: 'Play',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  PopupMenuButton<_PlaylistAction>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case _PlaylistAction.rename:
                          if (!mounted) return;
                          _showRenameDialog(context, playlistService, playlist);
                          break;
                        case _PlaylistAction.delete:
                          if (!mounted) return;
                          _confirmDelete(context, playlistService, playlist);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_PlaylistAction>(
                        value: _PlaylistAction.rename,
                        child: _PlaylistMenuRow(
                          icon: Icons.edit_rounded,
                          label: 'Rename',
                        ),
                      ),
                      PopupMenuItem<_PlaylistAction>(
                        value: _PlaylistAction.delete,
                        child: _PlaylistMenuRow(
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          iconColor: Colors.red,
                          labelColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, PlaylistService playlistService) {
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                playlistService.createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, PlaylistService playlistService,
      Playlist playlist) {
    final controller = TextEditingController(text: playlist.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Playlist name',
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                playlistService.renamePlaylist(
                    playlist.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlaylistService playlistService,
      Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
            'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              playlistService.deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist,
      AudioPlayerService playerService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final playlistService = Provider.of<PlaylistService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (playlist.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () {
                playerService.toggleShuffle();
                playerService.playPlaylist(playlist.items, 0);
              },
              tooltip: 'Shuffle play',
            ),
        ],
      ),
      body: playlist.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tracks in this playlist',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add tracks using the + button',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: EdgeInsets.only(
                bottom: LayoutConfig.verticalPadding(context) * 2,
              ),
              itemCount: playlist.items.length,
              onReorder: (oldIndex, newIndex) {
                playlistService.reorderTracksInPlaylist(
                    playlist.id, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final track = playlist.items[index];
                final isPlaying = playerService.currentMedia?.id == track.id &&
                    playerService.playerState == PlayerState.playing;

                return Dismissible(
                  key: Key(track.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child:
                        const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    playlistService.removeTrackFromPlaylist(
                        playlist.id, track.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Removed from playlist'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            playlistService.addTrackToPlaylist(
                                playlist.id, track);
                          },
                        ),
                      ),
                    );
                  },
                  child: MediaListItem(
                    media: track,
                    isPlaying: isPlaying,
                    onTap: () {
                      playerService.playPlaylist(playlist.items, index);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          playerService.playPlaylist(playlist.items, 0);
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Play All'),
      ),
    );
  }
}

class _PlaylistMenuRow extends StatelessWidget {
  const _PlaylistMenuRow({
    required this.icon,
    required this.label,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

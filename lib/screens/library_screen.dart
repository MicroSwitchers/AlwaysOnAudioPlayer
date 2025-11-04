import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/music_library_service.dart';
import '../services/playlist_service.dart';
import '../services/audio_player_service.dart';
import '../models/media_item.dart';
import '../models/playlist.dart';
import '../utils/layout_config.dart';
import '../widgets/media_list_item.dart';
import '../widgets/glass_container.dart';
import '../services/window_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<MusicLibraryService>(context);
    final playlistService = Provider.of<PlaylistService>(context);

    if (!library.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                colorScheme.surface.withValues(alpha: 0.72),
                colorScheme.surface.withValues(alpha: 0.28),
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
                    colorScheme.primary,
                    colorScheme.tertiary,
                  ],
                ),
              ),
              child: const Icon(Icons.library_music_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Library',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
        actions: [
          if (library.isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.onSurface,
            ),
            onSelected: (value) async {
              switch (value) {
                case 'fullscreen':
                  await WindowService.toggleFullscreen(context);
                  break;
                case 'rescan':
                  await library.rescanAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Library rescanned')),
                    );
                  }
                  break;
                case 'cleanup':
                  await library.cleanupMissingFiles();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed missing files')),
                    );
                  }
                  break;
                case 'manage':
                  _showManageFolders(context, library);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.folder_open),
                    SizedBox(width: 8),
                    Text('Manage Folders'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rescan',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Rescan Library'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services),
                    SizedBox(width: 8),
                    Text('Clean Up Missing Files'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'fullscreen',
                child: Row(
                  children: [
                    Icon(Icons.fullscreen_rounded),
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
                      colorScheme.primary.withValues(alpha: 0.95),
                      colorScheme.tertiary.withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
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
                  Tab(icon: Icon(Icons.music_note_rounded), text: 'Tracks'),
                  Tab(icon: Icon(Icons.queue_music_rounded), text: 'Playlists'),
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
              _buildTracksTab(library),
              _buildPlaylistsTab(playlistService),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(library, playlistService),
    );
  }

  Widget _buildTracksTab(MusicLibraryService library) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final displayTracks = _searchQuery.isEmpty
        ? library.libraryTracks
        : library.searchTracks(_searchQuery);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: LayoutConfig.pagePadding(context).copyWith(bottom: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search music...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Stats bar
        if (library.libraryTracks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(
                  Icons.library_music,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${library.libraryTracks.length} tracks in ${library.libraryFolders.length} ${library.libraryFolders.length == 1 ? 'folder' : 'folders'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        // Empty state or track list
        if (library.libraryFolders.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Library is Empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add folders to build your music library',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _addFolder(context, library),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Music Folder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (displayTracks.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty ? Icons.music_note : Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No music files found'
                        : 'No results for "$_searchQuery"',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => library.rescanAll(),
                      child: const Text('Rescan Library'),
                    ),
                  ],
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
              itemCount: displayTracks.length,
              itemBuilder: (context, index) {
                final track = displayTracks[index];
                final isPlaying = playerService.currentMedia?.id == track.id &&
                    playerService.playerState == PlayerState.playing;

                return MediaListItem(
                  media: track,
                  isPlaying: isPlaying,
                  onTap: () {
                    playerService.playPlaylist(displayTracks, index);
                  },
                  onMoreTap: () => _showTrackOptions(context, track, library),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlaylistsTab(PlaylistService playlistService) {
    final playerService = Provider.of<AudioPlayerService>(context);

    if (playlistService.playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Playlists Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create playlists to organize your music',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  _showCreatePlaylistDialog(context, playlistService),
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: LayoutConfig.pagePadding(context),
      itemCount: playlistService.playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlistService.playlists[index];
        return Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.queue_music_rounded),
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${playlist.items.length} tracks'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  _showPlaylistOptions(context, playlist, playlistService),
            ),
            onTap: () => _viewPlaylist(
                context, playlist, playlistService, playerService),
          ),
        );
      },
    );
  }

  Widget? _buildFAB(
      MusicLibraryService library, PlaylistService playlistService) {
    if (_tabController.index == 0) {
      // Tracks tab
      if (library.libraryTracks.isEmpty) {
        return FloatingActionButton(
          onPressed: () => _addFolder(context, library),
          tooltip: 'Add music folder',
          child: const Icon(Icons.add),
        );
      } else {
        return FloatingActionButton(
          onPressed: () {
            final playerService = context.read<AudioPlayerService>();
            final tracks = _searchQuery.isEmpty
                ? library.libraryTracks
                : library.searchTracks(_searchQuery);
            if (tracks.isNotEmpty) {
              playerService.playPlaylist(tracks, 0);
            }
          },
          tooltip: 'Play all',
          child: const Icon(Icons.play_arrow),
        );
      }
    } else {
      // Playlists tab
      return FloatingActionButton(
        onPressed: () => _showCreatePlaylistDialog(context, playlistService),
        tooltip: 'Create playlist',
        child: const Icon(Icons.add),
      );
    }
  }

  // Helper methods
  Future<void> _addFolder(
      BuildContext context, MusicLibraryService library) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        await library.addFolder(selectedDirectory);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added folder: $selectedDirectory'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => library.removeFolder(selectedDirectory),
              ),
            ),
          );
        }
      }
        } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding folder: $e')),
        );
      }
    }
  }

  void _showManageFolders(BuildContext context, MusicLibraryService library) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Library Folders'),
        content: SizedBox(
          width: double.maxFinite,
          child: library.libraryFolders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No folders added yet'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: library.libraryFolders.length,
                  itemBuilder: (context, index) {
                    final folder = library.libraryFolders[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(
                        folder,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          library.removeFolder(folder);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed: $folder')),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _addFolder(context, library);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Folder'),
          ),
        ],
      ),
    );
  }

  void _showTrackOptions(
      BuildContext context, MediaItem track, MusicLibraryService library) {
    final playlistService = context.read<PlaylistService>();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                context.read<AudioPlayerService>().play(track);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, track, playlistService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context);
                _showTrackDetails(context, track);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
      BuildContext context, MediaItem track, PlaylistService playlistService) {
    if (playlistService.playlists.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Playlists'),
          content: const Text('Create a playlist first to add tracks.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, playlistService,
                    initialTrack: track);
              },
              child: const Text('Create Playlist'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlistService.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistService.playlists[index];
              final alreadyAdded =
                  playlist.items.any((item) => item.id == track.id);

              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(playlist.name),
                subtitle: Text('${playlist.items.length} tracks'),
                trailing: alreadyAdded
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                enabled: !alreadyAdded,
                onTap: alreadyAdded
                    ? null
                    : () async {
                        await playlistService.addTrackToPlaylist(
                            playlist.id, track);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Added to "${playlist.name}"')),
                          );
                        }
                      },
              );
            },
          ),
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

  void _showCreatePlaylistDialog(
      BuildContext context, PlaylistService playlistService,
      {MediaItem? initialTrack}) {
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
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final playlist = await playlistService
                    .createPlaylist(controller.text.trim());
                if (initialTrack != null) {
                  await playlistService.addTrackToPlaylist(
                      playlist.id, initialTrack);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Created playlist "${playlist.name}"')),
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

  void _showPlaylistOptions(BuildContext context, Playlist playlist,
      PlaylistService playlistService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                final playerService = context.read<AudioPlayerService>();
                if (playlist.items.isNotEmpty) {
                  playerService.playPlaylist(playlist.items, 0);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenamePlaylistDialog(context, playlist, playlistService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Playlist?'),
                    content: Text(
                        'Are you sure you want to delete "${playlist.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await playlistService.deletePlaylist(playlist.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "${playlist.name}"')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, Playlist playlist,
      PlaylistService playlistService) {
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
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty &&
                  controller.text != playlist.name) {
                await playlistService.renamePlaylist(
                    playlist.id, controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist renamed')),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _viewPlaylist(BuildContext context, Playlist playlist,
      PlaylistService playlistService, AudioPlayerService playerService) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(playlist.name),
            actions: [
              if (playlist.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () =>
                      playerService.playPlaylist(playlist.items, 0),
                  tooltip: 'Play all',
                ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    _showPlaylistOptions(context, playlist, playlistService),
              ),
            ],
          ),
          body: playlist.items.isEmpty
              ? const Center(
                  child: Text('This playlist is empty'),
                )
              : ListView.builder(
                  itemCount: playlist.items.length,
                  itemBuilder: (context, index) {
                    final track = playlist.items[index];
                    final isPlaying =
                        playerService.currentMedia?.id == track.id &&
                            playerService.playerState == PlayerState.playing;

                    return MediaListItem(
                      media: track,
                      isPlaying: isPlaying,
                      onTap: () =>
                          playerService.playPlaylist(playlist.items, index),
                      onMoreTap: () => _showPlaylistTrackOptions(
                          context, track, playlist, playlistService),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showPlaylistTrackOptions(BuildContext context, MediaItem track,
      Playlist playlist, PlaylistService playlistService) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                context.read<AudioPlayerService>().play(track);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Remove from Playlist',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                await playlistService.removeTrackFromPlaylist(
                    playlist.id, track.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from playlist')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTrackDetails(BuildContext context, MediaItem track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Title', track.title),
              if (track.artist != null) _detailRow('Artist', track.artist!),
              if (track.album != null) _detailRow('Album', track.album!),
              _detailRow('Path', track.uri),
              if (track.metadata?['fileSize'] != null)
                _detailRow(
                  'Size',
                  '${((track.metadata!['fileSize'] as int) / 1024 / 1024).toStringAsFixed(2)} MB',
                ),
              if (track.metadata?['addedDate'] != null)
                _detailRow(
                  'Added',
                  DateTime.parse(track.metadata!['addedDate'] as String)
                      .toLocal()
                      .toString()
                      .split('.')[0],
                ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

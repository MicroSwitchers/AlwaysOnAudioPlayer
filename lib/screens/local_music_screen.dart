import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/music_library_service.dart';
import '../services/audio_player_service.dart';
import '../models/media_item.dart';
import '../widgets/media_list_item.dart';
import '../services/window_service.dart';

class LocalMusicScreen extends StatefulWidget {
  const LocalMusicScreen({super.key});

  @override
  State<LocalMusicScreen> createState() => _LocalMusicScreenState();
}

class _LocalMusicScreenState extends State<LocalMusicScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<MusicLibraryService>(context);
    final playerService = Provider.of<AudioPlayerService>(context);

    if (!library.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayTracks = _searchQuery.isEmpty
        ? library.libraryTracks
        : library.searchTracks(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
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
            icon: const Icon(Icons.more_vert),
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
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                      'Your Music Library is Empty',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      _searchQuery.isEmpty
                          ? Icons.music_note
                          : Icons.search_off,
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
                itemCount: displayTracks.length,
                itemBuilder: (context, index) {
                  final track = displayTracks[index];
                  final isPlaying =
                      playerService.currentMedia?.id == track.id &&
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
      ),
      floatingActionButton: library.libraryTracks.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                if (library.libraryTracks.isNotEmpty) {
                  final tracks = _searchQuery.isEmpty
                      ? library.libraryTracks
                      : displayTracks;
                  playerService.playPlaylist(tracks, 0);
                }
              },
              child: const Icon(Icons.play_arrow),
            )
          : FloatingActionButton(
              onPressed: () => _addFolder(context, library),
              child: const Icon(Icons.add),
            ),
    );
  }

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
                onPressed: () {
                  library.removeFolder(selectedDirectory);
                },
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

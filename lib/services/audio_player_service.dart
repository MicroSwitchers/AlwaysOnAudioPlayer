import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../models/media_item.dart';
import 'mci_player_service.dart';

enum PlayerState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MciPlayerService _mciPlayer = MciPlayerService();
  bool _usingMci = false;

  MediaItem? _currentMedia;
  PlayerState _playerState = PlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  List<MediaItem> _playlist = [];
  int _currentIndex = -1;

  // Getters
  MediaItem? get currentMedia => _currentMedia;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;
  List<MediaItem> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  AudioPlayerService() {
    _init();
  }

  Future<void> _init() async {
    // Initialize audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      } else if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        _updatePlayerState(PlayerState.loading);
      } else if (state.playing) {
        _updatePlayerState(PlayerState.playing);
      } else {
        _updatePlayerState(PlayerState.paused);
      }
    });

    // Listen to position updates
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration updates
    _audioPlayer.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    // Listen to errors
    _audioPlayer.playbackEventStream.listen(
      null,
      onError: (Object e, StackTrace st) {
        _handleError('Playback error: $e');
      },
    );
  }

  void _updatePlayerState(PlayerState state) {
    _playerState = state;
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    _playerState = PlayerState.error;
    notifyListeners();
  }

  Future<void> play(MediaItem media) async {
    try {
      _errorMessage = null;
      _updatePlayerState(PlayerState.loading);
      _currentMedia = media;

      // Check if this is an MCI CD track
      final useMci = media.metadata?['useMci'] == true;
      if (useMci && Platform.isWindows) {
        await _playWithMci(media);
        _usingMci = true;
        return;
      }

      _usingMci = false;
      final source = _createAudioSource(media);
      if (source == null) {
        _handleError('Unsupported media source');
        return;
      }

      await _audioPlayer.setAudioSource(source);
      await _audioPlayer.play();

      final playlistIndex = _playlist.indexWhere((item) => item.id == media.id);
      if (playlistIndex != -1) {
        _currentIndex = playlistIndex;
      }
    } catch (e) {
      _handleError('Failed to play media: $e');
    }
  }

  Future<void> _playWithMci(MediaItem media) async {
    final driveLetter = media.metadata?['driveLetter'] as String?;
    final trackNumber = media.metadata?['trackNumber'] as int?;

    if (driveLetter == null || trackNumber == null) {
      _handleError('Invalid MCI track information');
      return;
    }

    // Stop regular audio player
    await _audioPlayer.stop();

    // Play with MCI
    final success = await _mciPlayer.playTrack(driveLetter, trackNumber);
    if (success) {
      _updatePlayerState(PlayerState.playing);
      _startMciPositionSync();
    } else {
      _handleError(_mciPlayer.errorMessage ?? 'Failed to play CD track');
    }
  }

  void _startMciPositionSync() {
    // Sync position and duration from MCI player
    _mciPlayer.addListener(_syncMciState);
  }

  void _stopMciPositionSync() {
    _mciPlayer.removeListener(_syncMciState);
  }

  void _syncMciState() {
    if (_usingMci) {
      _position = _mciPlayer.position;
      _duration = _mciPlayer.duration;

      if (_mciPlayer.isPlaying) {
        _updatePlayerState(PlayerState.playing);
      } else if (_mciPlayer.isPaused) {
        _updatePlayerState(PlayerState.paused);
      } else {
        _updatePlayerState(PlayerState.stopped);
        _stopMciPositionSync();
        _handleTrackCompleted();
      }
    }
  }

  AudioSource? _createAudioSource(MediaItem media) {
    final uriString = media.uri.trim();
    if (uriString.isEmpty) {
      final fallbackPath = media.metadata?['filePath'] as String?;
      if (fallbackPath == null || fallbackPath.isEmpty) {
        return null;
      }
      return AudioSource.uri(
          Uri.file(fallbackPath, windows: Platform.isWindows));
    }

    final parsedUri = Uri.tryParse(uriString);
    if (parsedUri != null && parsedUri.hasScheme) {
      if (Platform.isWindows && parsedUri.scheme.length == 1) {
        // Likely a Windows drive letter path (e.g. C:\)
        return AudioSource.uri(Uri.file(uriString, windows: true));
      }
      return AudioSource.uri(parsedUri);
    }

    // Treat as a local file path if no usable scheme is present
    return AudioSource.uri(Uri.file(uriString, windows: Platform.isWindows));
  }

  Future<void> playPlaylist(List<MediaItem> items, int startIndex) async {
    if (items.isEmpty) return;

    _playlist = items;
    _currentIndex = startIndex.clamp(0, items.length - 1);
    await play(items[_currentIndex]);
  }

  Future<void> pause() async {
    if (_usingMci) {
      await _mciPlayer.pause();
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> resume() async {
    if (_usingMci) {
      await _mciPlayer.resume();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    _stopMciPositionSync();
    if (_usingMci) {
      await _mciPlayer.stop();
      _usingMci = false;
    } else {
      await _audioPlayer.stop();
    }
    _updatePlayerState(PlayerState.stopped);
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (_usingMci) {
      await _mciPlayer.seek(position);
    } else {
      await _audioPlayer.seek(position);
    }
  }

  Future<void> next() async {
    if (hasNext) {
      _currentIndex++;
      await play(_playlist[_currentIndex]);
    }
  }

  Future<void> previous() async {
    if (_position.inSeconds > 3) {
      // If more than 3 seconds into track, restart it
      await seek(Duration.zero);
    } else if (hasPrevious) {
      _currentIndex--;
      await play(_playlist[_currentIndex]);
    }
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await _audioPlayer.setShuffleModeEnabled(_isShuffleEnabled);
    notifyListeners();
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    await _audioPlayer.setLoopMode(mode);
    notifyListeners();
  }

  void _handleTrackCompleted() {
    if (_loopMode == LoopMode.one) {
      // Track will automatically replay
      return;
    }

    if (hasNext) {
      next();
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
      play(_playlist[_currentIndex]);
    } else {
      _updatePlayerState(PlayerState.stopped);
    }
  }

  @override
  void dispose() {
    _stopMciPositionSync();
    _audioPlayer.dispose();
    _mciPlayer.dispose();
    super.dispose();
  }
}

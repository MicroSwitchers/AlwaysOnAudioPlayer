import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/media_item.dart';

class CdPlayerService extends ChangeNotifier {
  static String get defaultCdPath {
    if (Platform.isWindows) {
      return 'D:\\'; // Default CD drive on Windows
    }
    return '/dev/cdrom'; // Default on Linux
  }

  static const String cdMountPoint = '/media/cdrom';

  final List<MediaItem> _cdTracks = [];
  bool _isCdLoaded = false;
  bool _isScanning = false;
  String? _errorMessage;
  late String _cdDrivePath;

  CdPlayerService() {
    _cdDrivePath = _normalizeCdDrivePath(defaultCdPath);
  }

  List<MediaItem> get cdTracks => List.unmodifiable(_cdTracks);
  bool get isCdLoaded => _isCdLoaded;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  String get cdDrivePath => _cdDrivePath;

  void setCdDrivePath(String path) {
    _cdDrivePath = _normalizeCdDrivePath(path);
    notifyListeners();
  }

  Future<void> detectCd() async {
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (Platform.isWindows) {
        await _detectWindowsCd();
      } else if (Platform.isLinux) {
        await _detectLinuxCd();
      } else {
        _errorMessage = 'CD playback is not supported on this platform';
      }
    } catch (e) {
      _errorMessage = 'Error detecting CD: $e';
      _isCdLoaded = false;
      _cdTracks.clear();
      debugPrint('Error detecting CD: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _detectWindowsCd() async {
    _cdTracks.clear();

    try {
      // Check if the CD drive exists and is accessible
      final cdDir = Directory(_cdDrivePath);
      if (!await cdDir.exists()) {
        _errorMessage = 'CD drive not found at $_cdDrivePath';
        _isCdLoaded = false;
        return;
      }

      // First, try to detect audio CD tracks using MCI
      final mciTracks = await _detectAudioCdTracksWithMci();
      if (mciTracks.isNotEmpty) {
        _cdTracks.addAll(mciTracks);
        _isCdLoaded = true;
        return;
      }

      // Fallback: Scan for audio files on data CDs
      final entities = await cdDir.list().toList();
      int trackNumber = 1;

      for (final entity in entities) {
        if (entity is File) {
          final ext = _getFileExtension(entity.path);

          if (ext == null) {
            continue;
          }

          // Support actual audio files from data CDs
          if (['.wav', '.mp3', '.flac', '.wma'].contains(ext)) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            final nameSeparatorIndex = fileName.lastIndexOf('.');
            final trackName = nameSeparatorIndex > 0
                ? fileName.substring(0, nameSeparatorIndex)
                : fileName;
            final fileUri = entity.uri.toString();

            _cdTracks.add(MediaItem(
              id: const Uuid().v4(),
              title: trackName,
              artist: 'Audio CD',
              album: 'Audio CD',
              uri: fileUri,
              type: MediaType.cdTrack,
              metadata: {
                'trackNumber': trackNumber,
                'filePath': entity.path,
                'drivePath': _cdDrivePath,
                'isCda': false,
              },
            ));
            trackNumber++;
          }
        }
      }

      if (_cdTracks.isNotEmpty) {
        _isCdLoaded = true;
      } else {
        _errorMessage =
            'No audio tracks found on CD. Please insert an audio CD or data CD with audio files.';
        _isCdLoaded = false;
      }
    } catch (e) {
      debugPrint('Error scanning Windows CD: $e');
      _errorMessage = 'Cannot access CD drive. Make sure a CD is inserted.';
      _isCdLoaded = false;
    }
  }

  Future<List<MediaItem>> _detectAudioCdTracksWithMci() async {
    final tracks = <MediaItem>[];

    try {
      // Get drive letter without backslash (e.g., "D:")
      final driveLetter = _cdDrivePath.replaceAll('\\', '').replaceAll('/', '');

      // Get track count using MCI status command
      final statusResult = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          '''
          Add-Type -TypeDefinition @"
          using System;
          using System.Text;
          using System.Runtime.InteropServices;
          public class MCI {
              [DllImport("winmm.dll")]
              public static extern int mciSendString(string command, StringBuilder returnValue, int returnLength, IntPtr hwndCallback);
          }
"@
          \$sb = New-Object System.Text.StringBuilder 256
          [MCI]::mciSendString("open $driveLetter type cdaudio alias cd", \$null, 0, [IntPtr]::Zero) | Out-Null
          [MCI]::mciSendString("status cd number of tracks", \$sb, 256, [IntPtr]::Zero) | Out-Null
          \$trackCount = \$sb.ToString().Trim()
          [MCI]::mciSendString("close cd", \$null, 0, [IntPtr]::Zero) | Out-Null
          Write-Output \$trackCount
          '''
        ],
      );

      if (statusResult.exitCode == 0) {
        final trackCountStr = statusResult.stdout.toString().trim();
        final trackCount = int.tryParse(trackCountStr);

        if (trackCount != null && trackCount > 0) {
          debugPrint('Found $trackCount audio CD tracks via MCI');

          for (int i = 1; i <= trackCount; i++) {
            tracks.add(MediaItem(
              id: const Uuid().v4(),
              title: 'Track $i',
              artist: 'Audio CD',
              album: 'Audio CD',
              uri: 'mci://$driveLetter/track/$i',
              type: MediaType.cdTrack,
              metadata: {
                'trackNumber': i,
                'drivePath': _cdDrivePath,
                'driveLetter': driveLetter,
                'isCda': true,
                'useMci': true,
              },
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('MCI detection failed: $e');
    }

    return tracks;
  }

  String? _getFileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return null;
    }
    return path.substring(dotIndex).toLowerCase();
  }

  Future<void> _detectLinuxCd() async {
    // Check if CD drive exists
    final cdDrive = File(_cdDrivePath);
    if (!await cdDrive.exists()) {
      _errorMessage = 'CD drive not found at $_cdDrivePath';
      _isCdLoaded = false;
      _cdTracks.clear();
      return;
    }

    // Try to mount the CD
    await _mountCd();

    // Scan for audio tracks
    await _scanCdTracksLinux();

    if (_cdTracks.isNotEmpty) {
      _isCdLoaded = true;
    } else {
      _errorMessage = 'No audio tracks found on CD';
      _isCdLoaded = false;
    }
  }

  Future<void> _mountCd() async {
    try {
      // Create mount point if it doesn't exist
      final mountDir = Directory(cdMountPoint);
      if (!await mountDir.exists()) {
        await Process.run('sudo', ['mkdir', '-p', cdMountPoint]);
      }

      // Check if already mounted
      final mountCheckResult = await Process.run('mount', []);
      if (mountCheckResult.stdout.toString().contains(cdMountPoint)) {
        debugPrint('CD already mounted');
        return;
      }

      // Try to mount
      final mountResult = await Process.run(
        'sudo',
        ['mount', '-t', 'iso9660', _cdDrivePath, cdMountPoint],
      );

      if (mountResult.exitCode != 0) {
        debugPrint('Mount warning: ${mountResult.stderr}');
      }
    } catch (e) {
      debugPrint('Error mounting CD: $e');
    }
  }

  Future<void> _scanCdTracksLinux() async {
    _cdTracks.clear();

    try {
      // Use cdparanoia or similar tool to detect audio tracks
      final result =
          await Process.run('cdparanoia', ['-Q'], workingDirectory: '/');

      if (result.exitCode == 0 || result.stderr.toString().contains('track')) {
        // Parse cdparanoia output
        final output = result.stderr.toString();
        final trackLines = output
            .split('\n')
            .where((line) => line.trim().startsWith(RegExp(r'\d+\.')));

        int trackNumber = 1;
        for (final _ in trackLines) {
          _cdTracks.add(MediaItem(
            id: const Uuid().v4(),
            title: 'Track $trackNumber',
            artist: 'Audio CD',
            album: 'Audio CD',
            uri: 'cdda://$trackNumber',
            type: MediaType.cdTrack,
            metadata: {
              'trackNumber': trackNumber,
              'cdDevice': _cdDrivePath,
            },
          ));
          trackNumber++;
        }
      } else {
        // Fallback: try to read from mounted filesystem
        await _scanMountedCdLinux();
      }
    } catch (e) {
      debugPrint('cdparanoia not available, trying alternative method: $e');
      await _scanMountedCdLinux();
    }
  }

  Future<void> _scanMountedCdLinux() async {
    try {
      final mountDir = Directory(cdMountPoint);
      if (await mountDir.exists()) {
        final entities = await mountDir.list().toList();
        int trackNumber = 1;

        for (final entity in entities) {
          if (entity is File) {
            final ext = entity.path
                .substring(entity.path.lastIndexOf('.'))
                .toLowerCase();
            if (['.wav', '.mp3', '.flac', '.cda'].contains(ext)) {
              final fileName = entity.path.split('/').last;
              _cdTracks.add(MediaItem(
                id: const Uuid().v4(),
                title: fileName.substring(0, fileName.lastIndexOf('.')),
                artist: 'Audio CD',
                album: 'Audio CD',
                uri: entity.path,
                type: MediaType.cdTrack,
                metadata: {
                  'trackNumber': trackNumber,
                  'filePath': entity.path,
                },
              ));
              trackNumber++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning mounted CD: $e');
    }
  }

  Future<void> ejectCd() async {
    if (Platform.isWindows) {
      await _ejectWindowsCd();
    } else if (Platform.isLinux) {
      await _ejectLinuxCd();
    }
  }

  Future<void> _ejectWindowsCd() async {
    try {
      // Use PowerShell to eject CD on Windows
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          '(New-Object -ComObject Shell.Application).Namespace(17).ParseName("$_cdDrivePath").InvokeVerb("Eject")'
        ],
      );

      if (result.exitCode == 0) {
        _isCdLoaded = false;
        _cdTracks.clear();
        notifyListeners();
      } else {
        _errorMessage = 'Failed to eject CD';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error ejecting CD: $e';
      debugPrint('Error ejecting CD: $e');
      notifyListeners();
    }
  }

  Future<void> _ejectLinuxCd() async {
    try {
      // Unmount first
      await Process.run('sudo', ['umount', cdMountPoint]);

      // Eject
      await Process.run('eject', [_cdDrivePath]);

      _isCdLoaded = false;
      _cdTracks.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error ejecting CD: $e';
      debugPrint('Error ejecting CD: $e');
      notifyListeners();
    }
  }

  Future<String?> ripTrack(MediaItem track, String outputPath) async {
    if (!Platform.isLinux) return null;

    try {
      final trackNumber = track.metadata?['trackNumber'] ?? 1;
      final outputFile = '$outputPath/track_$trackNumber.wav';

      final result = await Process.run(
        'cdparanoia',
        [trackNumber.toString(), outputFile],
      );

      if (result.exitCode == 0) {
        return outputFile;
      } else {
        debugPrint('Error ripping track: ${result.stderr}');
        return null;
      }
    } catch (e) {
      debugPrint('Error ripping track: $e');
      return null;
    }
  }

  String _normalizeCdDrivePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return defaultCdPath;
    }

    if (Platform.isWindows) {
      var normalized = trimmed.replaceAll('/', '\\');
      if (!normalized.endsWith('\\')) {
        normalized = '$normalized\\';
      }
      return normalized;
    }

    return trimmed;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

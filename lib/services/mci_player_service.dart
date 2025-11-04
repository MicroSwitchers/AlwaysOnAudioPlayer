import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Windows MCI (Media Control Interface) CD Audio Player
/// This service provides direct CD audio playback on Windows using MCI commands
class MciPlayerService extends ChangeNotifier {
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentTrack = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _positionTimer;
  String? _errorMessage;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int get currentTrack => _currentTrack;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;

  Future<bool> playTrack(String driveLetter, int trackNumber) async {
    if (!Platform.isWindows) {
      _errorMessage = 'MCI is only supported on Windows';
      notifyListeners();
      return false;
    }

    try {
      debugPrint(
          'MCI: Attempting to play track $trackNumber on drive $driveLetter');
      _errorMessage = null;
      _currentTrack = trackNumber;

      // Stop any currently playing track
      await stop();

      // Single PowerShell command to open, configure, and play
      debugPrint('MCI: Opening CD and starting playback...');
      final result = await Process.run(
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
              [DllImport("winmm.dll", CharSet = CharSet.Auto)]
              public static extern int mciSendString(string command, StringBuilder returnValue, int returnLength, IntPtr hwndCallback);
              
              [DllImport("winmm.dll")]
              public static extern int mciGetErrorString(int errorCode, StringBuilder errorText, int errorTextSize);
          }
"@
          \$errorText = New-Object System.Text.StringBuilder 256
          
          # Open CD
          \$result = [MCI]::mciSendString("open $driveLetter type cdaudio alias cdplayer", \$null, 0, [IntPtr]::Zero)
          if (\$result -ne 0) {
              [MCI]::mciGetErrorString(\$result, \$errorText, 256) | Out-Null
              Write-Output "open_error|\$(\$errorText.ToString())"
              exit 1
          }
          
          # Set time format
          \$result = [MCI]::mciSendString("set cdplayer time format milliseconds", \$null, 0, [IntPtr]::Zero)
          if (\$result -ne 0) {
              [MCI]::mciGetErrorString(\$result, \$errorText, 256) | Out-Null
              Write-Output "set_error|\$(\$errorText.ToString())"
              [MCI]::mciSendString("close cdplayer", \$null, 0, [IntPtr]::Zero) | Out-Null
              exit 1
          }
          
          # Get track length
          \$sb = New-Object System.Text.StringBuilder 256
          \$result = [MCI]::mciSendString("status cdplayer length track $trackNumber", \$sb, 256, [IntPtr]::Zero)
          \$trackLength = \$sb.ToString().Trim()
          
          # Play the track
          \$result = [MCI]::mciSendString("play cdplayer from $trackNumber", \$null, 0, [IntPtr]::Zero)
          if (\$result -ne 0) {
              [MCI]::mciGetErrorString(\$result, \$errorText, 256) | Out-Null
              Write-Output "play_error|\$(\$errorText.ToString())"
              [MCI]::mciSendString("close cdplayer", \$null, 0, [IntPtr]::Zero) | Out-Null
              exit 1
          }
          
          Write-Output "success|\$trackLength"
          '''
        ],
      );

      if (result.exitCode != 0) {
        final output = result.stdout.toString().trim();
        final parts = output.split('|');
        if (parts.length > 1) {
          _errorMessage = 'MCI Error: ${parts[1]}';
          debugPrint('MCI: ${parts[0]}: ${parts[1]}');
        } else {
          _errorMessage = 'Failed to play track';
          debugPrint('MCI: Command failed');
        }
        notifyListeners();
        return false;
      }

      final output = result.stdout.toString().trim();
      final parts = output.split('|');
      if (parts[0] == 'success') {
        _isPlaying = true;
        _isPaused = false;

        // Parse track length
        if (parts.length > 1) {
          final milliseconds = int.tryParse(parts[1]);
          if (milliseconds != null) {
            _duration = Duration(milliseconds: milliseconds);
            debugPrint('MCI: Track duration: $_duration');
          }
        }

        _startPositionUpdates();
        debugPrint('MCI: Playback started successfully');
        notifyListeners();
        return true;
      }

      _errorMessage = 'Unexpected response from MCI';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error playing track: $e';
      debugPrint('MCI play error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> pause() async {
    if (!_isPlaying || _isPaused) return;

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        '[MCI]::mciSendString("pause cdplayer", \$null, 0, [IntPtr]::Zero)'
      ]);
      if (result.exitCode == 0) {
        _isPaused = true;
        _positionTimer?.cancel();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MCI pause error: $e');
    }
  }

  Future<void> resume() async {
    if (!_isPaused) return;

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        '[MCI]::mciSendString("resume cdplayer", \$null, 0, [IntPtr]::Zero)'
      ]);
      if (result.exitCode == 0) {
        _isPaused = false;
        _startPositionUpdates();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MCI resume error: $e');
    }
  }

  Future<void> stop() async {
    _positionTimer?.cancel();

    if (_isPlaying || _isPaused) {
      try {
        await Process.run('powershell', [
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
              [DllImport("winmm.dll", CharSet = CharSet.Auto)]
              public static extern int mciSendString(string command, StringBuilder returnValue, int returnLength, IntPtr hwndCallback);
          }
"@
          [MCI]::mciSendString("stop cdplayer", \$null, 0, [IntPtr]::Zero) | Out-Null
          [MCI]::mciSendString("close cdplayer", \$null, 0, [IntPtr]::Zero) | Out-Null
        '''
        ]);
      } catch (e) {
        debugPrint('MCI stop error: $e');
      }
    }

    _isPlaying = false;
    _isPaused = false;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    if (!_isPlaying && !_isPaused) return;

    try {
      final milliseconds = position.inMilliseconds;
      await _sendMciCommand('seek cd to $milliseconds');
      _position = position;

      if (_isPlaying && !_isPaused) {
        await _sendMciCommand('play cd');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('MCI seek error: $e');
    }
  }

  Future<bool> _sendMciCommand(String command) async {
    try {
      debugPrint('MCI: Sending command: $command');
      final result = await Process.run(
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
              [DllImport("winmm.dll", CharSet = CharSet.Auto)]
              public static extern int mciSendString(string command, StringBuilder returnValue, int returnLength, IntPtr hwndCallback);
              
              [DllImport("winmm.dll")]
              public static extern int mciGetErrorString(int errorCode, StringBuilder errorText, int errorTextSize);
          }
"@
          \$errorText = New-Object System.Text.StringBuilder 256
          \$result = [MCI]::mciSendString("$command", \$null, 0, [IntPtr]::Zero)
          if (\$result -ne 0) {
              [MCI]::mciGetErrorString(\$result, \$errorText, 256) | Out-Null
              Write-Output "\$result|\$(\$errorText.ToString())"
          } else {
              Write-Output "0"
          }
          '''
        ],
      );

      if (result.exitCode != 0) {
        debugPrint(
            'MCI: PowerShell process failed with exit code: ${result.exitCode}');
        debugPrint('MCI: stderr: ${result.stderr}');
        return false;
      }

      final output = result.stdout.toString().trim();
      final parts = output.split('|');
      final exitCode = parts[0];
      final success = exitCode == '0';

      if (!success && parts.length > 1) {
        debugPrint(
            'MCI: Command "$command" failed with MCI error: ${parts[1]}');
      } else if (success) {
        debugPrint('MCI: Command "$command" succeeded');
      }

      return success;
    } catch (e) {
      debugPrint('MCI command error: $e');
      return false;
    }
  }

  Future<String?> _getMciStatus(String statusQuery) async {
    try {
      final result = await Process.run(
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
              [DllImport("winmm.dll", CharSet = CharSet.Auto)]
              public static extern int mciSendString(string command, StringBuilder returnValue, int returnLength, IntPtr hwndCallback);
          }
"@
          \$sb = New-Object System.Text.StringBuilder 256
          \$result = [MCI]::mciSendString("status cdplayer $statusQuery", \$sb, 256, [IntPtr]::Zero)
          if (\$result -eq 0) {
              Write-Output \$sb.ToString().Trim()
          }
          '''
        ],
      );

      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('MCI status error: $e');
    }
    return null;
  }

  void _startPositionUpdates() {
    _positionTimer?.cancel();
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isPlaying || _isPaused) {
        timer.cancel();
        return;
      }

      final positionStr = await _getMciStatus('position');
      if (positionStr != null) {
        final milliseconds = int.tryParse(positionStr);
        if (milliseconds != null) {
          _position = Duration(milliseconds: milliseconds);
          notifyListeners();

          // Check if track has finished
          if (_position >= _duration && _duration.inMilliseconds > 0) {
            await stop();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    stop();
    super.dispose();
  }
}

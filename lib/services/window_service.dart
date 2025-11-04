import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Centralized helpers for window management across desktop builds.
class WindowService {
  WindowService._();

  static const Size _defaultWindowSize = Size(1024, 600);
  static const Size _minimumWindowSize = Size(800, 480);
  static bool _isTransitioning = false;

  /// Ensures the window manager is ready and shows the window.
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: _defaultWindowSize,
      minimumSize: _minimumWindowSize,
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setResizable(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// Toggles between fullscreen and windowed modes with guards to prevent freezes.
  static Future<void> toggleFullscreen(BuildContext context) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      final isFullScreen = await windowManager.isFullScreen();

      if (isFullScreen) {
        await windowManager.setFullScreen(false);
        await windowManager.setTitleBarStyle(
          TitleBarStyle.normal,
          windowButtonVisibility: true,
        );
        await windowManager.setResizable(true);
        await windowManager.setMinimumSize(_minimumWindowSize);
        await windowManager.setSize(_defaultWindowSize);
        await windowManager.center();
      } else {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
        await windowManager.setFullScreen(true);
      }

      await windowManager.focus();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to toggle fullscreen')),
        );
      }
    } finally {
      _isTransitioning = false;
    }
  }
}

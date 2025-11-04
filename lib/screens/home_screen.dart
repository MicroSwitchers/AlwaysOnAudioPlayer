import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/settings_service.dart';
import '../utils/layout_config.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/glass_container.dart';
import 'library_screen.dart';
import 'radio_screen.dart';
import 'curated_radio_screen.dart';

export '../services/settings_service.dart' show NavigationBarPosition;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(), // Contains Tracks & Playlists tabs
    const RadioScreen(),
    const CuratedRadioScreen(), // Curated internet radio stations
  ];

  void _onDestinationSelected(int index) {
    if (index == 3) {
      // Settings button
      _showPositionSettings(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showPositionSettings(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => _PositionSettingsDialog(
        currentPosition: settingsService.navigationBarPosition,
        onPositionSelected: (position) {
          settingsService.setNavigationBarPosition(position);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<AudioPlayerService>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final hasCurrentMedia = playerService.currentMedia != null;
    final isCompact = LayoutConfig.isCompact(context);
    final navPosition = settingsService.navigationBarPosition;

    Widget mainContent = Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.02),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: _screens[_selectedIndex],
            ),
          ),
        ),
        if (hasCurrentMedia) const NowPlayingBar(orientation: Axis.horizontal),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: SafeArea(
        child: _buildLayoutForNavPosition(
          context,
          navPosition,
          mainContent,
          isCompact,
        ),
      ),
      bottomNavigationBar: navPosition == NavigationBarPosition.bottom
          ? _buildNavigationBar(context, isCompact, navPosition)
          : null,
    );
  }

  Widget _buildLayoutForNavPosition(
    BuildContext context,
    NavigationBarPosition position,
    Widget mainContent,
    bool isCompact,
  ) {
    Widget navBar = _buildNavigationBar(context, isCompact, position);

    switch (position) {
      case NavigationBarPosition.bottom:
        return Column(
          children: [
            Expanded(child: mainContent),
          ],
        );
      case NavigationBarPosition.top:
        return Column(
          children: [
            navBar,
            Expanded(child: mainContent),
          ],
        );
      case NavigationBarPosition.left:
        return Row(
          children: [
            navBar,
            Expanded(child: mainContent),
          ],
        );
      case NavigationBarPosition.right:
        return Row(
          children: [
            Expanded(child: mainContent),
            navBar,
          ],
        );
    }
  }

  Widget _buildNavigationBar(BuildContext context, bool isCompact, NavigationBarPosition position) {
    bool isVertical = position == NavigationBarPosition.left || position == NavigationBarPosition.right;

    if (isVertical) {
      // Vertical navigation rail - optimized for small screens
      final railWidth = LayoutConfig.isExtraCompact(context) ? 70.0 : 90.0;
      final fontSize = LayoutConfig.isExtraCompact(context) ? 9.0 : 10.0;
      final iconSize = LayoutConfig.isExtraCompact(context) ? 20.0 : 24.0;
      
      return Container(
        width: railWidth,
        padding: EdgeInsets.symmetric(
          vertical: LayoutConfig.verticalPadding(context),
          horizontal: LayoutConfig.horizontalPadding(context) * 0.5,
        ),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(LayoutConfig.isExtraCompact(context) ? 20 : 28),
          padding: EdgeInsets.symmetric(
            vertical: LayoutConfig.isExtraCompact(context) ? 8 : 12,
            horizontal: 4,
          ),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LayoutConfig.isExtraCompact(context) ? 12 : 16),
            ),
            minWidth: railWidth,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.library_music_outlined, size: iconSize),
                selectedIcon: Icon(Icons.library_music_rounded, size: iconSize),
                label: Text('Library', style: TextStyle(fontSize: fontSize), overflow: TextOverflow.ellipsis),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.radio_outlined, size: iconSize),
                selectedIcon: Icon(Icons.radio_rounded, size: iconSize),
                label: Text('Radio', style: TextStyle(fontSize: fontSize), overflow: TextOverflow.ellipsis),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.stars_outlined, size: iconSize),
                selectedIcon: Icon(Icons.stars_rounded, size: iconSize),
                label: Text('Curated', style: TextStyle(fontSize: fontSize), overflow: TextOverflow.ellipsis),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined, size: iconSize),
                selectedIcon: Icon(Icons.settings_rounded, size: iconSize),
                label: Text('Settings', style: TextStyle(fontSize: fontSize), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );
    }

    // Horizontal navigation bar
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LayoutConfig.horizontalPadding(context),
        position == NavigationBarPosition.top ? LayoutConfig.verticalPadding(context) : 0,
        LayoutConfig.horizontalPadding(context),
        position == NavigationBarPosition.bottom ? LayoutConfig.verticalPadding(context) : 0,
      ),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          height: LayoutConfig.navigationBarHeight(context),
          labelBehavior: isCompact
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          animationDuration: const Duration(milliseconds: 400),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music_rounded),
              label: 'Library',
              tooltip: 'Browse your music library',
            ),
            NavigationDestination(
              icon: Icon(Icons.radio_outlined),
              selectedIcon: Icon(Icons.radio_rounded),
              label: 'Radio',
              tooltip: 'Listen to radio stations',
            ),
            NavigationDestination(
              icon: Icon(Icons.stars_outlined),
              selectedIcon: Icon(Icons.stars_rounded),
              label: 'Curated',
              tooltip: 'Discover curated stations',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
              tooltip: 'App settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionSettingsDialog extends StatefulWidget {
  final NavigationBarPosition currentPosition;
  final ValueChanged<NavigationBarPosition> onPositionSelected;

  const _PositionSettingsDialog({
    required this.currentPosition,
    required this.onPositionSelected,
  });

  @override
  State<_PositionSettingsDialog> createState() => _PositionSettingsDialogState();
}

class _PositionSettingsDialogState extends State<_PositionSettingsDialog> {
  late NavigationBarPosition _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.display_settings_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Navigation Bar Position'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose where to display the navigation bar for more screen space',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ...NavigationBarPosition.values.map((position) {
              final isSelected = _selectedPosition == position;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  color: isSelected 
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedPosition = position;
                      });
                      widget.onPositionSelected(position);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          _buildPositionPreview(position, isSelected, colorScheme),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPositionLabel(position),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? colorScheme.primary : null,
                                  ),
                                ),
                                Text(
                                  _getPositionDescription(position),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }

  Widget _buildPositionPreview(NavigationBarPosition position, bool isSelected, ColorScheme colorScheme) {
    final primaryColor = isSelected ? colorScheme.primary : colorScheme.outline;
    final secondaryColor = isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest;
    
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _PositionPreviewPainter(position, primaryColor, secondaryColor),
      ),
    );
  }

  String _getPositionLabel(NavigationBarPosition position) {
    switch (position) {
      case NavigationBarPosition.bottom:
        return 'Bottom';
      case NavigationBarPosition.top:
        return 'Top';
      case NavigationBarPosition.left:
        return 'Left Sidebar';
      case NavigationBarPosition.right:
        return 'Right Sidebar';
    }
  }

  String _getPositionDescription(NavigationBarPosition position) {
    switch (position) {
      case NavigationBarPosition.bottom:
        return 'Traditional layout';
      case NavigationBarPosition.top:
        return 'Desktop-style navigation';
      case NavigationBarPosition.left:
        return 'More vertical space';
      case NavigationBarPosition.right:
        return 'Alternate sidebar';
    }
  }
}

class _PositionPreviewPainter extends CustomPainter {
  final NavigationBarPosition position;
  final Color primaryColor;
  final Color secondaryColor;

  _PositionPreviewPainter(this.position, this.primaryColor, this.secondaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final navPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Draw background (app area)
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw navigation bar based on position
    RRect navRect;
    switch (position) {
      case NavigationBarPosition.bottom:
        navRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height - 8, size.width, 8),
          const Radius.circular(2),
        );
        break;
      case NavigationBarPosition.top:
        navRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, 8),
          const Radius.circular(2),
        );
        break;
      case NavigationBarPosition.left:
        navRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, 8, size.height),
          const Radius.circular(2),
        );
        break;
      case NavigationBarPosition.right:
        navRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - 8, 0, 8, size.height),
          const Radius.circular(2),
        );
        break;
    }
    canvas.drawRRect(navRect, navPaint);
  }

  @override
  bool shouldRepaint(_PositionPreviewPainter oldDelegate) =>
      position != oldDelegate.position ||
      primaryColor != oldDelegate.primaryColor ||
      secondaryColor != oldDelegate.secondaryColor;
}

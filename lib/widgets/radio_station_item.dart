import 'package:flutter/material.dart';
import '../models/radio_station.dart';
import '../utils/layout_config.dart';

class RadioStationItem extends StatelessWidget {
  final RadioStation station;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isPlaying;

  const RadioStationItem({
    super.key,
    required this.station,
    required this.onTap,
    required this.onFavoriteTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final leadingSize = LayoutConfig.mediaTileLeadingSize(context);
    final isCompact = LayoutConfig.isCompact(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutConfig.horizontalPadding(context),
            vertical: LayoutConfig.verticalPadding(context) * 0.5,
          ),
          decoration: BoxDecoration(
            color: isPlaying
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Logo with animation
              Hero(
                tag: 'station_${station.id}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: leadingSize,
                  height: leadingSize,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    border: isPlaying
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child:
                        station.logoUrl != null && station.logoUrl!.isNotEmpty
                            ? Image.network(
                                station.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultIcon(context, isPlaying),
                              )
                            : _buildDefaultIcon(context, isPlaying),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      station.name,
                      style: TextStyle(
                        fontWeight:
                            isPlaying ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isCompact ? 14 : 15,
                        color: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_buildSubtitle() != null) ...[
                      const SizedBox(height: 2),
                      _buildSubtitle()!,
                    ],
                  ],
                ),
              ),
              // Playing indicator or favorite button
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                iconSize: 22,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    station.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(station.isFavorite),
                    color: station.isFavorite ? Colors.red : null,
                  ),
                ),
                onPressed: onFavoriteTap,
                tooltip: station.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context, bool isPlaying) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        isPlaying ? Icons.graphic_eq_rounded : Icons.radio_rounded,
        color: isPlaying
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];

    if (station.country != null && station.country!.isNotEmpty) {
      parts.add(station.country!);
    }

    if (station.genre != null && station.genre!.isNotEmpty) {
      parts.add(station.genre!);
    }

    if (station.bitrate != null && station.bitrate! > 0) {
      parts.add('${station.bitrate} kbps');
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    );
  }
}

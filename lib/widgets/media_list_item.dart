import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../utils/layout_config.dart';

class MediaListItem extends StatelessWidget {
  final MediaItem media;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final bool showTrackNumber;

  const MediaListItem({
    super.key,
    required this.media,
    required this.isPlaying,
    required this.onTap,
    this.onMoreTap,
    this.showTrackNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final leadingSize = LayoutConfig.mediaTileLeadingSize(context);
    final isCompact = LayoutConfig.isCompact(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: LayoutConfig.horizontalPadding(context),
            vertical: LayoutConfig.verticalPadding(context) * 0.5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isPlaying
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.85),
                      colorScheme.secondary.withValues(alpha: 0.65),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.55),
                      colorScheme.surface.withValues(alpha: 0.35),
                    ],
                  ),
            border: Border.all(
              color: isPlaying
                  ? colorScheme.onPrimary.withValues(alpha: 0.25)
                  : colorScheme.onSurface.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isPlaying
                    ? colorScheme.primary.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isPlaying ? 24 : 14,
                spreadRadius: isPlaying ? 2 : -4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Leading with animation
              Hero(
                tag: 'media_${media.id}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: leadingSize,
                  height: leadingSize,
                  decoration: BoxDecoration(
                    gradient: isPlaying
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.92),
                              Colors.white.withValues(alpha: 0.65),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.9),
                              colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPlaying
                          ? Colors.white.withValues(alpha: 0.45)
                          : colorScheme.onSurface.withValues(alpha: 0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isPlaying
                            ? colorScheme.primary.withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: isPlaying ? 22 : 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showTrackNumber &&
                          media.metadata?['trackNumber'] != null &&
                          !isPlaying)
                        Text(
                          media.metadata!['trackNumber'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 15 : 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Icon(
                          isPlaying
                              ? Icons.graphic_eq_rounded
                              : _getMediaTypeIcon(),
                          color: isPlaying
                              ? colorScheme.primary.withValues(alpha: 0.85)
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                          size: isCompact ? 22 : 24,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isPlaying ? FontWeight.w700 : FontWeight.w600,
                            fontSize: isCompact ? 14 : 16,
                            color: isPlaying
                                ? Colors.white
                                : colorScheme.onSurface,
                            letterSpacing: 0.1,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (media.artist != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        media.artist!,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 13.5,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing - play indicator or more menu
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      if (onMoreTap != null)
                        IconButton(
                          iconSize: 22,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          onPressed: onMoreTap,
                        ),
                    ],
                  ),
                )
              else if (onMoreTap != null)
                IconButton(
                  iconSize: 22,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                  onPressed: onMoreTap,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMediaTypeIcon() {
    switch (media.type) {
      case MediaType.localFile:
        return Icons.music_note_rounded;
      case MediaType.radioStation:
        return Icons.radio_rounded;
      case MediaType.cdTrack:
        return Icons.album_rounded;
    }
  }
}

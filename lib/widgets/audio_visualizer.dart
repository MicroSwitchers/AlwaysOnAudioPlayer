import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final List<Color>? colors; // Multiple colors for gradient effect
  final int barCount;
  final double width;
  final double height;
  final bool animateColors;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.colors,
    this.barCount = 5,
    this.width = 40,
    this.height = 24,
    this.animateColors = true,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _colorController;
  Timer? _updateTimer;
  final List<double> _barHeights = [];
  final List<Color> _barColors = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize bar heights and colors
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(0.3 + _random.nextDouble() * 0.4);
      _barColors.add(_getColorForIndex(i));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  Color _getColorForIndex(int index) {
    if (widget.colors == null || widget.colors!.isEmpty) {
      return Colors.white;
    }
    if (widget.colors!.length == 1) {
      return widget.colors!.first;
    }
    // Distribute colors across bars
    final colorIndex =
        (index * widget.colors!.length / widget.barCount).floor();
    return widget.colors![colorIndex.clamp(0, widget.colors!.length - 1)];
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);

    if (widget.animateColors) {
      _colorController.repeat(reverse: true);
    }

    _updateTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _barHeights.length; i++) {
            // More dramatic height variations
            final baseHeight = 0.15 + _random.nextDouble() * 0.85;
            // Add some correlation between adjacent bars for more natural look
            if (i > 0 && _random.nextDouble() > 0.5) {
              _barHeights[i] = (_barHeights[i - 1] + baseHeight) / 2;
            } else {
              _barHeights[i] = baseHeight;
            }

            // Animate colors if enabled
            if (widget.animateColors &&
                widget.colors != null &&
                widget.colors!.length > 1) {
              final nextColorIndex = (_random.nextInt(widget.colors!.length));
              _barColors[i] = Color.lerp(
                _barColors[i],
                widget.colors![nextColorIndex],
                0.3,
              )!;
            }
          }
        });
      }
    });
  }

  void _stopAnimation() {
    _updateTimer?.cancel();
    _controller.stop();
    _colorController.stop();
    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = 0.2;
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _controller.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate safe bar count based on available width
          const spacing = 2.0;
          const minBarWidth = 3.0;
          final maxBars =
              ((constraints.maxWidth + spacing) / (minBarWidth + spacing))
                  .floor();
          final actualBarCount = widget.barCount.clamp(1, maxBars);

          // Calculate bar width
          final totalSpacing = (actualBarCount - 1) * spacing;
          final barWidth =
              ((constraints.maxWidth - totalSpacing) / actualBarCount)
                  .clamp(minBarWidth, double.infinity);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              actualBarCount,
              (index) {
                // Use modulo to wrap around if we have fewer bars than expected
                final heightIndex = index % _barHeights.length;
                final colorIndex = index % _barColors.length;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeInOut,
                  width: barWidth,
                  height: widget.height * _barHeights[heightIndex],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _barColors[colorIndex],
                        _barColors[colorIndex].withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: widget.isPlaying
                        ? [
                            BoxShadow(
                              color:
                                  _barColors[colorIndex].withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final bool isPlaying;
  final bool isLoading;
  final Color primaryColor;
  final Color backgroundColor;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.isPlaying,
    required this.isLoading,
    required this.primaryColor,
    required this.backgroundColor,
    this.height = 3,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.3;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background with pulsing glow
            if (widget.isPlaying)
              Container(
                height: widget.height,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor
                          .withValues(alpha: _pulseAnimation.value * 0.5),
                      blurRadius: 8 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                    ),
                  ],
                ),
              ),
            // Main progress bar
            LinearProgressIndicator(
              value: widget.progress,
              minHeight: widget.height,
              backgroundColor: widget.backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
            ),
            // Loading indicator overlay
            if (widget.isLoading)
              LinearProgressIndicator(
                minHeight: widget.height,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.primaryColor.withValues(alpha: 0.5),
                ),
              ),
          ],
        );
      },
    );
  }
}

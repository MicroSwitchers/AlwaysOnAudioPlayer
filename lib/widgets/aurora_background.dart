import 'dart:ui';

import 'package:flutter/material.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;

  const AuroraBackground({super.key, required this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final baseGradient = brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF05060F),
              Color(0xFF0E1530),
              Color(0xFF151B2F),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7F5FF),
              Color(0xFFE6F4FF),
              Color(0xFFFDF5FF),
            ],
          );

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(gradient: baseGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAuroraBlob(
                brightness: brightness,
                animationValue: t,
                offsetTween: const Offset(-180, -140),
                targetOffset: const Offset(80, -60),
                baseSize: 420,
                targetSize: 360,
                colors: brightness == Brightness.dark
                    ? const [Color(0xFF2A81FF), Color(0xFF9255FF)]
                    : const [Color(0xFF7FE9FF), Color(0xFFB47CFF)],
              ),
              _buildAuroraBlob(
                brightness: brightness,
                animationValue: t,
                offsetTween: const Offset(220, 380),
                targetOffset: const Offset(160, 320),
                baseSize: 340,
                targetSize: 420,
                colors: brightness == Brightness.dark
                    ? const [Color(0xFF00FFC6), Color(0xFF3C5CFF)]
                    : const [Color(0xFF4DFFD6), Color(0xFF44A0FF)],
              ),
              _buildAuroraBlob(
                brightness: brightness,
                animationValue: 1 - t,
                offsetTween: const Offset(-120, 320),
                targetOffset: const Offset(-40, 400),
                baseSize: 280,
                targetSize: 340,
                opacity: 0.7,
                colors: brightness == Brightness.dark
                    ? const [Color(0xFFFF5DA2), Color(0xFF9C3EFF)]
                    : const [Color(0xFFFF8CCD), Color(0xFF9C75FF)],
              ),
              if (child != null) child,
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: brightness == Brightness.dark
                          ? [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.4),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.4),
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuroraBlob({
    required Brightness brightness,
    required double animationValue,
    required Offset offsetTween,
    required Offset targetOffset,
    required double baseSize,
    required double targetSize,
    required List<Color> colors,
    double opacity = 0.85,
  }) {
    final dx = lerpDouble(offsetTween.dx, targetOffset.dx, animationValue)!;
    final dy = lerpDouble(offsetTween.dy, targetOffset.dy, animationValue)!;
    final size = lerpDouble(baseSize, targetSize, animationValue)!;

    return Positioned(
      left: dx,
      top: dy,
      child: Transform.rotate(
        angle: animationValue * 0.6,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors:
                      colors.map((c) => c.withValues(alpha: opacity)).toList(),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: 0.18),
                    blurRadius: 88,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

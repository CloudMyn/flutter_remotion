import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:laminar/laminar.dart';

/// Typed configuration props passed to [ComprehensiveFeatureComposition].
class DemoProps {
  const DemoProps({
    this.title = 'FLUTTER REMOTION',
    this.subtitle = 'Programmatic Video & Motion Graphics Engine',
    this.accentColor = const Color(0xFF6C63FF),
    this.showGrid = true,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final bool showGrid;

  DemoProps copyWith({
    String? title,
    String? subtitle,
    Color? accentColor,
    bool? showGrid,
  }) {
    return DemoProps(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      accentColor: accentColor ?? this.accentColor,
      showGrid: showGrid ?? this.showGrid,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'accentColor': accentColor.toARGB32(),
        'showGrid': showGrid,
      };
}

/// A comprehensive composition demonstrating:
/// - `useCurrentFrame(context)` and `useVideoConfig(context)`
/// - `Series` (Scene 1: Intro -> Scene 2: Layered Sequences -> Scene 3: Outro)
/// - `Sequence` (with frame offset and isolated relative frame numbers)
/// - `interpolate()` with various [LaminarEasing] curves and extrapolation rules
/// - Dynamic typed props from [DemoProps]
class ComprehensiveFeatureComposition extends StatelessWidget {
  const ComprehensiveFeatureComposition({
    super.key,
    this.props = const DemoProps(),
  });

  final DemoProps props;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Series(
        sequences: [
          // Scene 1: Kinetic Intro & Title (Frames 0 - 50)
          SeriesSequence(
            durationInFrames: 50,
            child: _SceneIntro(props: props),
          ),
          // Scene 2: Layered Sequences & Kinetic Equalizer (Frames 50 - 110)
          SeriesSequence(
            durationInFrames: 60,
            child: _SceneLayeredSequences(props: props),
          ),
          // Scene 3: Outro & Completion Badge (Frames 110 - 150)
          SeriesSequence(
            durationInFrames: 40,
            child: _SceneOutro(props: props),
          ),
        ],
      ),
    );
  }
}

// ── Scene 1: Kinetic Intro ───────────────────────────────────────────────────

class _SceneIntro extends StatelessWidget {
  const _SceneIntro({required this.props});
  final DemoProps props;

  @override
  Widget build(BuildContext context) {
    final frame = useCurrentFrame(context);
    final config = useVideoConfig(context);

    // Title entrance: scale 0.6 -> 1.0, opacity 0 -> 1 over 25 frames
    final titleScale = interpolate(
      frame,
      [0, 25],
      [0.6, 1.0],
      easing: LaminarEasing.easeOutCubic,
      extrapolateRight: Extrapolate.clamp,
    );

    final titleOpacity = interpolate(
      frame,
      [0, 20],
      [0.0, 1.0],
      easing: LaminarEasing.easeOutCubic,
      extrapolateRight: Extrapolate.clamp,
    );

    // Subtitle entrance: slide up 30px -> 0px between frames 15 - 35
    final subtitleY = interpolate(
      frame,
      [15, 35],
      [30.0, 0.0],
      easing: LaminarEasing.easeOutCubic,
      extrapolateLeft: Extrapolate.clamp,
      extrapolateRight: Extrapolate.clamp,
    );

    final subtitleOpacity = interpolate(
      frame,
      [15, 35],
      [0.0, 1.0],
      easing: LaminarEasing.easeOutCubic,
      extrapolateLeft: Extrapolate.clamp,
      extrapolateRight: Extrapolate.clamp,
    );

    // Scene transition exit: fade out on frames 40 - 50
    final exitOpacity = interpolate(
      frame,
      [40, 50],
      [1.0, 0.0],
      extrapolateLeft: Extrapolate.clamp,
      extrapolateRight: Extrapolate.clamp,
    );

    final combinedOpacity = (titleOpacity * exitOpacity).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D15),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (props.showGrid) CustomPaint(painter: _GridPatternPainter()),
          // Ambient glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    props.accentColor.withValues(alpha: 0.25 * titleOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Opacity(
                opacity: combinedOpacity,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: props.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: props.accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'SCENE 1: INTRO • ${config.width}x${config.height} @ ${config.fps}fps',
                          style: TextStyle(
                            color: props.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Transform.scale(
                        scale: titleScale,
                        child: Text(
                          props.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subtitle
                      Transform.translate(
                        offset: Offset(0, subtitleY),
                        child: Opacity(
                          opacity: subtitleOpacity,
                          child: Text(
                            props.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Progress pill
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timeline, color: props.accentColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Relative Frame: $frame / 50',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene 2: Layered Sequences ───────────────────────────────────────────────

class _SceneLayeredSequences extends StatelessWidget {
  const _SceneLayeredSequences({required this.props});
  final DemoProps props;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF09090F),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Sequence from frame 0
          Sequence(
            from: 0,
            durationInFrames: 60,
            child: _AnimatedBackground(accent: props.accentColor),
          ),
          // Layered Feature Badges: Sequence from frame 10 (duration 50)
          Sequence(
            from: 10,
            durationInFrames: 50,
            child: _FeatureBadgesSequence(accent: props.accentColor),
          ),
          // Kinetic Wave Equalizer: Sequence from frame 15 (duration 45)
          Sequence(
            from: 15,
            durationInFrames: 45,
            child: _EqualizerSequence(accent: props.accentColor),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final frame = useCurrentFrame(context);
    final rotation = (frame * 1.5) * math.pi / 180;

    return Center(
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 380,
          height: 380,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureBadgesSequence extends StatelessWidget {
  const _FeatureBadgesSequence({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final frame = useCurrentFrame(context);

    final badges = [
      ('Composition<T>', Icons.dashboard_customize, const Color(0xFF6C63FF)),
      ('Sequence & Series', Icons.view_timeline, const Color(0xFFFF6584)),
      ('interpolate()', Icons.auto_graph, const Color(0xFF00C9A7)),
      ('MediaRenderer', Icons.movie_creation, const Color(0xFFFFBE0B)),
    ];

    return Positioned(
      top: 36,
      left: 0,
      right: 0,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                'SCENE 2: PARALLEL SEQUENCES',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(badges.length, (i) {
                  // Staggered entrance: each badge enters 6 frames after the previous
                  final start = i * 6;
                  final scale = interpolate(
                    frame,
                    [start, start + 15],
                    [0.0, 1.0],
                    easing: LaminarEasing.bezier(0.34, 1.56, 0.64, 1.0),
                    extrapolateLeft: Extrapolate.clamp,
                    extrapolateRight: Extrapolate.clamp,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161626),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: badges[i].$3.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badges[i].$2, color: badges[i].$3, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              badges[i].$1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EqualizerSequence extends StatelessWidget {
  const _EqualizerSequence({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final frame = useCurrentFrame(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(24, (i) {
            // Procedural sine bar height
            final freq = (frame * 0.15) + (i * 0.35);
            final h = 20.0 + (math.sin(freq).abs() * 70.0);
            final color = HSLColor.fromAHSL(
              1.0,
              (180 + (i * 7)) % 360,
              0.8,
              0.55,
            ).toColor();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Scene 3: Outro ───────────────────────────────────────────────────────────

class _SceneOutro extends StatelessWidget {
  const _SceneOutro({required this.props});
  final DemoProps props;

  @override
  Widget build(BuildContext context) {
    final frame = useCurrentFrame(context);

    // Pulse scale: 0.8 -> 1.05 -> 1.0
    final scale = interpolate(
      frame,
      [0, 20, 30],
      [0.8, 1.05, 1.0],
      easing: LaminarEasing.easeOutCubic,
      extrapolateRight: Extrapolate.clamp,
    );

    final opacity = interpolate(
      frame,
      [0, 15],
      [0.0, 1.0],
      easing: LaminarEasing.easeOutCubic,
      extrapolateRight: Extrapolate.clamp,
    );

    return Container(
      color: const Color(0xFF0B0914),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [props.accentColor, const Color(0xFFFF6584)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: props.accentColor.withValues(alpha: 0.4),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'COMPREHENSIVE DEMO COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ready for real-time playback & off-screen export',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Background Painter ───────────────────────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

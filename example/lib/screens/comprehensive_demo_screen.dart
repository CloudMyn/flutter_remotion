import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:laminar/laminar.dart';

import '../compositions/comprehensive_feature_composition.dart';

/// Master interactive laboratory screen demonstrating all Laminar / Flutter Remotion features:
/// 1. `Composition<T>` with typed dynamic props
/// 2. `LaminarController` transport & frame scrubbing (`seekTo`, `play`, `pause`, etc.)
/// 3. `Sequence` & `Series` visual timeline inspector
/// 4. `interpolate()` and `LaminarEasing` interactive curve studio
/// 5. `MediaRenderer` & `FrameRenderer` offline parallel rasterizer
class ComprehensiveDemoScreen extends StatefulWidget {
  const ComprehensiveDemoScreen({super.key});

  @override
  State<ComprehensiveDemoScreen> createState() =>
      _ComprehensiveDemoScreenState();
}

class _ComprehensiveDemoScreenState extends State<ComprehensiveDemoScreen>
    with SingleTickerProviderStateMixin {
  late final LaminarController _ctrl;
  late final TabController _tabCtrl;

  // Dynamic props for the composition
  DemoProps _props = const DemoProps();

  // Playback options
  bool _loop = true;
  double _playbackSpeed = 1.0;
  Timer? _ticker;

  // Viewport aspect ratio options
  double _aspectRatio = 16 / 9;

  // Easing studio state
  String _selectedEasingName = 'easeOutCubic';
  final Map<String, double Function(double)> _easingPresets = {
    'linear': LaminarEasing.linear,
    'easeInQuad': LaminarEasing.easeIn,
    'easeOutCubic': LaminarEasing.easeOutCubic,
    'easeInOutSine': LaminarEasing.easeInOutSine,
    'easeOutQuart': LaminarEasing.easeOutQuart,
    'easeOutExpo': LaminarEasing.easeOutExpo,
    'elasticBack (bezier)': LaminarEasing.bezier(0.34, 1.56, 0.64, 1.0),
  };

  // Offline rendering state
  bool _isRendering = false;
  double _renderProgress = 0.0;
  String? _renderStatusMessage;
  Uint8List? _renderedThumbnailBytes;

  static const int _totalFrames = 150;
  static const int _fps = 30;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _ctrl = LaminarController();
    _ctrl.addListener(_onControllerUpdate);

    // Start auto playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPlaybackTicker();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabCtrl.dispose();
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startPlaybackTicker() {
    _ticker?.cancel();
    _ctrl.play();
    final intervalMs = ((1000 / _fps) / _playbackSpeed).round();

    _ticker = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_ctrl.isPlaying) return;

      if (_ctrl.frame >= _totalFrames - 1) {
        if (_loop) {
          _ctrl.seekTo(0);
        } else {
          _ctrl.pause();
        }
      } else {
        _ctrl.seekTo(_ctrl.frame + 1);
      }
    });
  }

  void _togglePlayPause() {
    if (_ctrl.isPlaying) {
      _ctrl.pause();
    } else {
      _ctrl.play();
      _startPlaybackTicker();
    }
    setState(() {});
  }

  void _stepFrame(int delta) {
    _ctrl.pause();
    final target = (_ctrl.frame + delta).clamp(0, _totalFrames - 1);
    _ctrl.seekTo(target);
    setState(() {});
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      if (_ctrl.isPlaying) {
        _startPlaybackTicker();
      }
    });
  }

  // ── Offline Rendering Demo ─────────────────────────────────────────────────

  Future<void> _runOfflineRenderDemo() async {
    if (_isRendering) return;

    setState(() {
      _isRendering = true;
      _renderProgress = 0.0;
      _renderStatusMessage = 'Initializing MediaRenderer...';
    });

    const config = VideoConfig(
      id: 'comprehensive-export',
      width: 1280,
      height: 720,
      fps: 30,
      durationInFrames: 30, // 30 frames test export
    );

    const options = RenderMediaOptions(
      composition: config,
      outputLocation: 'export_preview',
      concurrency: 2,
    );

    final renderer = MediaRenderer(options: options);
    final sub = renderer.onProgress.listen((p) {
      if (mounted) {
        setState(() {
          _renderProgress = p.progress;
          _renderStatusMessage =
              'Rasterising: ${p.renderedFrames}/${p.totalFrames} frames (${(p.progress * 100).toStringAsFixed(1)}%)';
        });
      }
    });

    try {
      final result = await renderer.render(
        widgetFactory: (frame) => ComprehensiveFeatureComposition(props: _props),
      );

      // Extract a thumbnail snapshot using FrameRenderer
      final snapshot = await FrameRenderer.renderFrame(
        frame: 15,
        widget: ComprehensiveFeatureComposition(props: _props),
        config: config,
      );
      final byteData = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      snapshot.dispose();

      if (mounted) {
        setState(() {
          _isRendering = false;
          _renderedThumbnailBytes = byteData?.buffer.asUint8List();
          _renderStatusMessage =
              'Complete! Rendered ${result.totalFrames} frames in ${result.durationMs}ms.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRendering = false;
          _renderStatusMessage = 'Render error: $e';
        });
      }
    } finally {
      await sub.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = _ctrl.frame;
    final progress = _totalFrames > 1 ? frame / (_totalFrames - 1) : 0.0;
    final timeSeconds = (frame / _fps).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131320),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_props.accentColor, const Color(0xFFFF6584)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie_creation, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laminar Lab',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Comprehensive Remotion Feature Showcase',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Aspect Ratio Switcher
          DropdownButton<double>(
            value: _aspectRatio,
            dropdownColor: const Color(0xFF1A1A2E),
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 16 / 9, child: Text('16:9 Landscape')),
              DropdownMenuItem(value: 1.0, child: Text('1:1 Square')),
              DropdownMenuItem(value: 9 / 16, child: Text('9:16 Vertical')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _aspectRatio = val);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Video Viewport & Playback Controls
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildVideoCanvas(frame, timeSeconds),
                        const SizedBox(height: 16),
                        _buildTransportCard(frame, progress, timeSeconds),
                        const SizedBox(height: 16),
                        _buildTimelineTracks(frame),
                      ],
                    ),
                  ),
                ),
                // Right Column: Interactive Lab Tabs
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.white10)),
                    ),
                    child: _buildControlTabs(),
                  ),
                ),
              ],
            );
          } else {
            // Mobile / Narrow Layout
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildVideoCanvas(frame, timeSeconds),
                  const SizedBox(height: 16),
                  _buildTransportCard(frame, progress, timeSeconds),
                  const SizedBox(height: 16),
                  _buildTimelineTracks(frame),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 500,
                    child: _buildControlTabs(),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // ── Video Canvas ───────────────────────────────────────────────────────────

  Widget _buildVideoCanvas(int frame, String timeSeconds) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _aspectRatio,
            child: Composition<DemoProps>(
              config: const VideoConfig(
                id: 'comprehensive-demo',
                width: 1920,
                height: 1080,
                fps: _fps,
                durationInFrames: _totalFrames,
              ),
              defaultProps: _props,
              serialize: (p) => p.toJson(),
              component: (ctx, p) => ComprehensiveFeatureComposition(props: _props),
              controller: _ctrl,
              loop: _loop,
            ),
          ),
          // Frame & Info HUD Overlay
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ctrl.isPlaying ? Colors.greenAccent : Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FRAME: $frame / $_totalFrames  •  ${timeSeconds}s  •  $_fps FPS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transport Controls Deck ────────────────────────────────────────────────

  Widget _buildTransportCard(int frame, double progress, String timeSeconds) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Scrubber Bar
          Row(
            children: [
              const Text(
                '00:00',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _props.accentColor,
                    thumbColor: _props.accentColor,
                    inactiveTrackColor: Colors.white12,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: frame.toDouble(),
                    min: 0,
                    max: (_totalFrames - 1).toDouble(),
                    onChanged: (val) {
                      _ctrl.pause();
                      _ctrl.seekTo(val.toInt());
                      setState(() {});
                    },
                  ),
                ),
              ),
              Text(
                '${timeSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action Buttons
          Row(
            children: [
              // Rewind
              IconButton(
                icon: const Icon(Icons.fast_rewind_rounded),
                color: Colors.white70,
                tooltip: 'Rewind to start (Frame 0)',
                onPressed: () {
                  _ctrl.seekTo(0);
                  setState(() {});
                },
              ),
              // Step -1
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                color: Colors.white70,
                tooltip: 'Step -1 Frame',
                onPressed: () => _stepFrame(-1),
              ),
              // Play / Pause
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_props.accentColor, const Color(0xFFFF6584)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(_ctrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: _togglePlayPause,
                ),
              ),
              // Step +1
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                color: Colors.white70,
                tooltip: 'Step +1 Frame',
                onPressed: () => _stepFrame(1),
              ),
              // Loop Toggle
              IconButton(
                icon: Icon(Icons.repeat_rounded, color: _loop ? _props.accentColor : Colors.white30),
                tooltip: _loop ? 'Loop Enabled' : 'Loop Disabled',
                onPressed: () => setState(() => _loop = !_loop),
              ),
              const Spacer(),
              // Speed selector chips
              ...[0.5, 1.0, 2.0].map((s) {
                final isSelected = _playbackSpeed == s;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text('${s}x', style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: _props.accentColor.withValues(alpha: 0.3),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: isSelected ? _props.accentColor : Colors.white24,
                    ),
                    onSelected: (_) => _changeSpeed(s),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline Inspector ─────────────────────────────────────────────────────

  Widget _buildTimelineTracks(int frame) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.view_timeline_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text(
                'Series & Sequence Track Inspector',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Track 1: Series
          _buildTrackBar(
            title: 'Series Chaining',
            frame: frame,
            segments: [
              _TrackSegment(start: 0, end: 50, color: const Color(0xFF6C63FF), label: 'Scene 1: Intro'),
              _TrackSegment(start: 50, end: 110, color: const Color(0xFF00C9A7), label: 'Scene 2: Multi-Track'),
              _TrackSegment(start: 110, end: 150, color: const Color(0xFFFF6584), label: 'Scene 3: Outro'),
            ],
          ),
          const SizedBox(height: 8),
          // Track 2: Nested Sequences inside Scene 2
          _buildTrackBar(
            title: 'Scene 2 Sequences',
            frame: frame,
            segments: [
              _TrackSegment(start: 50, end: 110, color: Colors.blueGrey, label: 'Bg Radar [0..60]'),
              _TrackSegment(start: 60, end: 110, color: const Color(0xFFFFBE0B), label: 'Badges [10..60]'),
              _TrackSegment(start: 65, end: 110, color: const Color(0xFF9C27B0), label: 'Equalizer [15..60]'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackBar({
    required String title,
    required int frame,
    required List<_TrackSegment> segments,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 26,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: segments.map((seg) {
                  final flex = (seg.end - seg.start).clamp(1, _totalFrames);
                  final isActive = frame >= seg.start && frame < seg.end;

                  return Expanded(
                    flex: flex,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: seg.color.withValues(alpha: isActive ? 0.75 : 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive ? Colors.white : seg.color.withValues(alpha: 0.5),
                          width: isActive ? 1.5 : 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        seg.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white60,
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Playhead indicator needle
            Positioned(
              left: (frame / _totalFrames) * (MediaQuery.of(context).size.width * 0.45),
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Tabbed Control Lab ─────────────────────────────────────────────────────

  Widget _buildControlTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          indicatorColor: _props.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.tune, size: 18), text: 'Dynamic Props'),
            Tab(icon: Icon(Icons.show_chart, size: 18), text: 'Easing & Interpolate'),
            Tab(icon: Icon(Icons.layers, size: 18), text: 'Sequence Inspector'),
            Tab(icon: Icon(Icons.download, size: 18), text: 'MediaRenderer'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildPropsEditorTab(),
              _buildEasingStudioTab(),
              _buildSequenceInspectorTab(),
              _buildMediaRendererTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Props Editor ────────────────────────────────────────────────────

  Widget _buildPropsEditorTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Live Composition<T> Props Editor',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Edit props below in real-time. Notice how the composition updates instantly without re-mounting the timeline.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 20),
        // Title Input
        TextFormField(
          initialValue: _props.title,
          decoration: const InputDecoration(
            labelText: 'Title Prop',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFF1A1A2E),
          ),
          onChanged: (val) {
            setState(() {
              _props = _props.copyWith(title: val);
            });
          },
        ),
        const SizedBox(height: 16),
        // Subtitle Input
        TextFormField(
          initialValue: _props.subtitle,
          decoration: const InputDecoration(
            labelText: 'Subtitle Prop',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFF1A1A2E),
          ),
          onChanged: (val) {
            setState(() {
              _props = _props.copyWith(subtitle: val);
            });
          },
        ),
        const SizedBox(height: 20),
        // Accent Color Swatches
        const Text('Accent Theme Color', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: [
            const Color(0xFF6C63FF),
            const Color(0xFFFF6584),
            const Color(0xFF00C9A7),
            const Color(0xFFFFBE0B),
            const Color(0xFF3A86FF),
          ].map((color) {
            final isSelected = _props.accentColor == color;
            return GestureDetector(
              onTap: () => setState(() => _props = _props.copyWith(accentColor: color)),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        // Background Grid Switch
        SwitchListTile(
          title: const Text('Background Grid', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Toggle custom background painter', style: TextStyle(color: Colors.white54, fontSize: 11)),
          value: _props.showGrid,
          activeTrackColor: _props.accentColor,
          onChanged: (val) => setState(() => _props = _props.copyWith(showGrid: val)),
        ),
      ],
    );
  }

  // ── Tab 2: Easing Studio ───────────────────────────────────────────────────

  Widget _buildEasingStudioTab() {
    final easingFn = _easingPresets[_selectedEasingName] ?? LaminarEasing.easeOutCubic;
    final progress = (_ctrl.frame / _totalFrames).clamp(0.0, 1.0);
    final easedVal = easingFn(progress);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'interpolate() & LaminarEasing Studio',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select an easing curve to view its mathematical curve and observe real-time value progression.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 16),
        // Easing Selector Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedEasingName,
          decoration: const InputDecoration(
            labelText: 'Easing Curve',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFF1A1A2E),
          ),
          dropdownColor: const Color(0xFF1A1A2E),
          items: _easingPresets.keys.map((name) {
            return DropdownMenuItem(value: name, child: Text(name));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedEasingName = val);
          },
        ),
        const SizedBox(height: 20),
        // Graph Canvas
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF11111E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: CustomPaint(
            painter: _EasingGraphPainter(
              easing: easingFn,
              currentProgress: progress,
              accentColor: _props.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Live Animated Kinetic Puck
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161626),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    't = ${progress.toStringAsFixed(2)}  ->  eased(t) = ${easedVal.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Track
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: LayoutBuilder(
                  builder: (context, trackConstraints) {
                    final maxW = trackConstraints.maxWidth - 36;
                    final puckX = (easedVal.clamp(0.0, 1.0) * maxW);

                    return Stack(
                      children: [
                        Positioned(
                          left: puckX,
                          top: 2,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _props.accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _props.accentColor.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Sequence Inspector ──────────────────────────────────────────────

  Widget _buildSequenceInspectorTab() {
    final frame = _ctrl.frame;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Active Sequence State Inspector',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Remotion automatically manages relative frames for nested sequences. Compare master frame vs sequence relative frame:',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 16),
        _buildSequenceInfoCard(
          name: 'Scene 1: Intro (SeriesSequence)',
          masterStart: 0,
          masterDuration: 50,
          currentMasterFrame: frame,
          color: const Color(0xFF6C63FF),
        ),
        const SizedBox(height: 10),
        _buildSequenceInfoCard(
          name: 'Scene 2: Layered Tracks (SeriesSequence)',
          masterStart: 50,
          masterDuration: 60,
          currentMasterFrame: frame,
          color: const Color(0xFF00C9A7),
        ),
        const SizedBox(height: 10),
        _buildSequenceInfoCard(
          name: 'Scene 3: Outro (SeriesSequence)',
          masterStart: 110,
          masterDuration: 40,
          currentMasterFrame: frame,
          color: const Color(0xFFFF6584),
        ),
      ],
    );
  }

  Widget _buildSequenceInfoCard({
    required String name,
    required int masterStart,
    required int masterDuration,
    required int currentMasterFrame,
    required Color color,
  }) {
    final isActive = currentMasterFrame >= masterStart &&
        currentMasterFrame < (masterStart + masterDuration);
    final relativeFrame = (currentMasterFrame - masterStart).clamp(0, masterDuration - 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.white12,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : Colors.white24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Range: [$masterStart .. ${masterStart + masterDuration}] frames',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.2) : Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'Active (Rel: $relativeFrame)' : 'Inactive',
              style: TextStyle(
                color: isActive ? color : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: MediaRenderer Tab ───────────────────────────────────────────────

  Widget _buildMediaRendererTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'MediaRenderer & FrameRenderer Pipeline',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Executes Flutter off-screen rasterisation across parallel batches to render raw frames programmatically.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: _isRendering
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.rocket_launch_rounded),
          label: Text(_isRendering ? 'Rendering in Progress...' : 'Start 30-Frame Off-screen Render'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _props.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isRendering ? null : _runOfflineRenderDemo,
        ),
        if (_renderStatusMessage != null) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _renderProgress,
            color: _props.accentColor,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 8),
          Text(
            _renderStatusMessage!,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
        if (_renderedThumbnailBytes != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Exported Frame Snapshot Preview (Frame 15):',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _renderedThumbnailBytes!,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Track Segment Model ──────────────────────────────────────────────────────

class _TrackSegment {
  _TrackSegment({
    required this.start,
    required this.end,
    required this.color,
    required this.label,
  });

  final int start;
  final int end;
  final Color color;
  final String label;
}

// ── Graph Painter ────────────────────────────────────────────────────────────

class _EasingGraphPainter extends CustomPainter {
  _EasingGraphPainter({
    required this.easing,
    required this.currentProgress,
    required this.accentColor,
  });

  final double Function(double) easing;
  final double currentProgress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 24.0;
    final w = size.width - (pad * 2);
    final h = size.height - (pad * 2);

    // Grid & Axis
    final axisPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1.0;

    canvas.drawRect(Rect.fromLTWH(pad, pad, w, h), axisPaint..style = PaintingStyle.stroke);

    // Curve Path
    final path = Path();
    final curvePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 100; i++) {
      final t = i / 100.0;
      final yVal = easing(t).clamp(-0.2, 1.2);
      final px = pad + (t * w);
      final py = pad + h - (yVal * h);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(path, curvePaint);

    // Current point dot
    final currY = easing(currentProgress).clamp(-0.2, 1.2);
    final dotX = pad + (currentProgress * w);
    final dotY = pad + h - (currY * h);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(dotX, dotY), 5.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _EasingGraphPainter oldDelegate) {
    return oldDelegate.currentProgress != currentProgress ||
        oldDelegate.easing != easing ||
        oldDelegate.accentColor != accentColor;
  }
}

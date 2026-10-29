import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/composition_provider.dart';
import '../models/video_config.dart';

/// Responsible for rasterising a single frame of a composition into a
/// [ui.Image].
///
/// Equivalent to a single iteration of Remotion's `render-frames.ts` loop.
/// Instead of using a headless Chromium (Puppeteer), Laminar uses Flutter's
/// off-screen [RenderRepaintBoundary] + [ui.SceneBuilder] pipeline to extract
/// raw pixels directly — no browser required.
///
/// ### Implementation notes
/// - The widget tree is pumped off-screen using a [RenderView] attached to a
///   detached [PipelineOwner]. This avoids touching the live UI thread.
/// - The resulting [ui.Image] is a reference-counted GPU texture. Callers
///   **must** call [ui.Image.dispose] after converting to bytes.
abstract final class FrameRenderer {
  FrameRenderer._();

  /// Renders [widget] at the given [frame] index and returns a [ui.Image].
  ///
  /// The [config] provides output dimensions and is injected into the widget
  /// tree via a [CompositionProvider].
  ///
  /// This method is designed to be called from a background [Isolate] via
  /// `Isolate.run()` for true parallel frame rendering.
  static Future<ui.Image> renderFrame({
    required int frame,
    required Widget widget,
    required VideoConfig config,
  }) async {
    // Wrap widget in Directionality so widgets like Stack, Text, and Row
    // can resolve directional alignments without needing an ambient MaterialApp.
    final framedWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: CompositionProvider(
        config: config,
        frame: frame,
        child: widget,
      ),
    );

    // Build an off-screen render tree.
    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(
          Size(config.width.toDouble(), config.height.toDouble()),
        ),
      ),
    );

    final pipelineOwner = PipelineOwner();
    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());

    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: framedWidget,
    ).attachToRenderTree(buildOwner);

    // Pump the build & layout pipelines.
    buildOwner.buildScope(element);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Extract the pixel data as a ui.Image.
    final image = await repaintBoundary.toImage(pixelRatio: 1.0);

    // Clean up.
    buildOwner.finalizeTree();

    return image;
  }
}

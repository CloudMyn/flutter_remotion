import 'package:flutter/widgets.dart';

import 'sequence.dart';

/// A descriptor for a child within a [Series].
class SeriesSequence {
  const SeriesSequence({required this.durationInFrames, required this.child});

  /// Duration in frames.
  final int durationInFrames;

  /// The child widget.
  final Widget child;
}

/// Lays out multiple [SeriesSequence] children one after another, each
/// starting where the previous one ended.
///
/// Equivalent to Remotion's `<Series>` component — a convenience wrapper
/// around chained `<Sequence>` elements.
///
/// ```dart
/// Series(
///   sequences: [
///     SeriesSequence(durationInFrames: 30, child: IntroWidget()),
///     SeriesSequence(durationInFrames: 60, child: MainWidget()),
///     SeriesSequence(durationInFrames: 30, child: OutroWidget()),
///   ],
/// )
/// ```
class Series extends StatelessWidget {
  const Series({super.key, required this.sequences});
  final List<SeriesSequence> sequences;

  @override
  Widget build(BuildContext context) {
    int offset = 0;
    final children = <Widget>[];

    for (final seq in sequences) {
      children.add(
        Sequence(
          from: offset,
          durationInFrames: seq.durationInFrames,
          child: seq.child,
        ),
      );
      offset += seq.durationInFrames;
    }

    return Stack(
      alignment: Alignment.topLeft,
      children: children,
    );
  }
}

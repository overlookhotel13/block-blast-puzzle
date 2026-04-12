/// block.dart
/// Represents a single coloured cell (block) on the grid.
/// Used both as part of a [TrayPiece] and as the dragged ghost piece.
/// Rendering is pure Canvas — no widget overhead.

import 'dart:ui';
import 'package:flame/components.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// A single coloured square block cell.
/// Can be rendered standalone or composited inside a larger shape.
class Block extends PositionComponent {
  // ── Configuration ────────────────────────────────────────────

  /// The colour of this block cell
  final Color color;

  /// The rendered cell size in logical pixels
  final double cellSize;

  // ── Paints (created once per instance) ───────────────────────

  late final Paint _facePaint;
  late final Paint _shadowPaint;
  late final Paint _shinePaint;

  Block({
    required this.color,
    required this.cellSize,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all(cellSize),
        );

  @override
  Future<void> onLoad() async {
    _facePaint = Paint()..color = color;
    _shadowPaint = Paint()..color = darken(color, 0.25);
    _shinePaint = Paint()
      ..color = lighten(color, 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }

  @override
  void render(Canvas canvas) {
    final gap = kCellGap;
    final rect = Rect.fromLTWH(gap / 2, gap / 2, cellSize - gap, cellSize - gap);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(kCellRadius));

    // 1. Shadow layer (shifted 2px down)
    canvas.drawRRect(rRect.shift(const Offset(0, 2)), _shadowPaint);

    // 2. Face
    canvas.drawRRect(rRect, _facePaint);

    // 3. Shine / highlight outline
    canvas.drawRRect(rRect, _shinePaint);
  }
}

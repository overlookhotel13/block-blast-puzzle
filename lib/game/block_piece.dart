/// block_piece.dart
/// A multi-cell block piece as shown in the bottom tray.
/// Manages the compact visual representation of a [BlockShape] + colour.
/// Also provides the data contract used by the drag system in [BlockPuzzleGame].

import 'dart:ui';
import 'package:flame/components.dart';
import '../models/block_shape.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart' as h;

// ─────────────────────────────────────────────
//  TRAY PIECE COMPONENT
// ─────────────────────────────────────────────

/// Renders a single block shape inside the tray at a reduced cell size.
/// When selected for dragging the game renders a larger ghost separately.
class TrayPieceComponent extends PositionComponent {
  // ── Data ─────────────────────────────────────────────────────

  /// The shape layout (row/col offsets)
  final BlockShape shape;

  /// The block colour
  final Color color;

  /// Index of [color] in [kBlockColors] (0-4)
  final int colorIndex;

  /// Cell size used when drawing this piece in the tray
  final double cellSize;

  // ── State ────────────────────────────────────────────────────

  /// When true, the piece is being dragged and should render dimmed / invisible
  bool isDragging = false;

  /// When true, the piece has been used (slot is empty) — renders nothing
  bool isUsed = false;

  // ── Paints ───────────────────────────────────────────────────

  late final Paint _facePaint;
  late final Paint _shadowPaint;
  late final Paint _dimPaint;

  TrayPieceComponent({
    required this.shape,
    required this.color,
    required this.colorIndex,
    required this.cellSize,
    Vector2? position,
  }) : super(position: position ?? Vector2.zero()) {
    // Compute bounding size from shape extents
    size = Vector2(
      shape.cols * cellSize,
      shape.rows * cellSize,
    );
  }

  @override
  Future<void> onLoad() async {
    _facePaint = Paint()..color = color;
    _shadowPaint = Paint()..color = h.darken(color, 0.25);
    _dimPaint = Paint()
      ..color = const Color(0x40000000); // semi-transparent overlay when dragging
  }

  @override
  void render(Canvas canvas) {
    if (isUsed) return; // Empty slot — nothing to draw

    for (final cell in shape.cells) {
      final x = cell[1] * cellSize;
      final y = cell[0] * cellSize;
      _renderCell(canvas, x, y);
    }

    // Dim overlay when being dragged
    if (isDragging) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        _dimPaint,
      );
    }
  }

  void _renderCell(Canvas canvas, double x, double y) {
    const gap = kCellGap;
    final rect = Rect.fromLTWH(
      x + gap / 2,
      y + gap / 2,
      cellSize - gap,
      cellSize - gap,
    );
    final rRect =
        RRect.fromRectAndRadius(rect, const Radius.circular(kCellRadius));

    // Shadow
    canvas.drawRRect(rRect.shift(const Offset(0, 2)), _shadowPaint);
    // Face
    canvas.drawRRect(rRect, _facePaint);
  }

  // ── Helpers ───────────────────────────────────────────────────

  /// Returns true if [localPoint] falls within any cell of this piece.
  @override
  bool containsLocalPoint(Vector2 point) {
    if (isUsed) return false;
    // Check if point is within overall bounding box
    if (point.x < 0 || point.y < 0 || point.x > size.x || point.y > size.y) {
      return false;
    }
    // Check if point falls on an actual cell
    final col = (point.x / cellSize).floor();
    final row = (point.y / cellSize).floor();
    return shape.cells.any((c) => c[0] == row && c[1] == col);
  }
}

// ─────────────────────────────────────────────
//  DRAGGED PIECE RENDERER
// ─────────────────────────────────────────────

/// Utility class that renders the "ghost" piece following the user's finger.
/// Not a Flame component — drawn directly via [BlockPuzzleGame.render()].
class DraggedPieceRenderer {
  final BlockShape shape;
  final Color color;
  final double cellSize;

  late final Paint _facePaint;
  late final Paint _shadowPaint;
  late final Paint _shinePaint;

  DraggedPieceRenderer({
    required this.shape,
    required this.color,
    required this.cellSize,
  }) {
    _facePaint = Paint()..color = color;
    _shadowPaint = Paint()..color = h.darken(color, 0.25);
    _shinePaint = Paint()
      ..color = h.lighten(color, 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }

  /// Draws the piece centred at [centerX], [centerY] (canvas coordinates).
  void render(Canvas canvas, double centerX, double centerY) {
    // Compute top-left so the bounding box is centred
    final offsetX = centerX - (shape.cols * cellSize) / 2;
    final offsetY = centerY - (shape.rows * cellSize) / 2;

    for (final cell in shape.cells) {
      final x = offsetX + cell[1] * cellSize;
      final y = offsetY + cell[0] * cellSize;

      const gap = kCellGap;
      final rect = Rect.fromLTWH(
        x + gap / 2,
        y + gap / 2,
        cellSize - gap,
        cellSize - gap,
      );
      final rRect =
          RRect.fromRectAndRadius(rect, const Radius.circular(kCellRadius));

      canvas.drawRRect(rRect.shift(const Offset(0, 2)), _shadowPaint);
      canvas.drawRRect(rRect, _facePaint);
      canvas.drawRRect(rRect, _shinePaint);
    }
  }
}

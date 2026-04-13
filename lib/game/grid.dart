/// grid.dart
/// Flame PositionComponent that owns and renders the 9×9 puzzle grid.
/// Responsibilities:
///   - Store per-cell colour state (null = empty)
///   - Paint cells, borders and highlights
///   - Validate and apply piece placements
///   - Detect 3+ consecutive same-colour runs and clear them
///   - Return the number of cleared cells and lines for scoring

import 'dart:ui';
import 'package:flutter/painting.dart' show HSLColor;
import 'package:flame/components.dart';
import '../models/block_shape.dart';
import '../utils/constants.dart';

// ─────────────────────────────────────────────
//  HIGHLIGHT STATE
// ─────────────────────────────────────────────

/// Describes how a cell should be highlighted during a drag operation.
enum HighlightMode { none, valid, invalid }

// ─────────────────────────────────────────────
//  GRID COMPONENT
// ─────────────────────────────────────────────

/// The 9×9 interactive game grid rendered inside the Flame scene.
class GridComponent extends PositionComponent {
  // ── Configuration ────────────────────────────────────────────

  /// Pixel size of each cell (set by [BlockPuzzleGame] based on screen size)
  final double cellSize;

  // ── State ────────────────────────────────────────────────────

  /// Grid contents: null = empty, non-null = block colour
  final List<List<Color?>> _cells =
      List.generate(kGridSize, (_) => List.filled(kGridSize, null));

  /// Highlight overlay for each cell during drag
  final List<List<HighlightMode>> _highlight = List.generate(
    kGridSize,
    (_) => List.filled(kGridSize, HighlightMode.none),
  );

  // ── Paints ───────────────────────────────────────────────────

  /// Background / border paint
  final Paint _bgPaint = Paint()..color = kColorGridLine;

  /// Empty cell paint
  final Paint _emptyPaint = Paint()..color = kColorCellEmpty;

  /// Valid highlight paint
  final Paint _validPaint = Paint()..color = kColorHighlightValid;

  /// Invalid highlight paint
  final Paint _invalidPaint = Paint()..color = kColorHighlightInvalid;

  // ── Constructor ───────────────────────────────────────────────

  GridComponent({required this.cellSize}) {
    // The component's bounding box equals the full grid + padding on all sides
    final totalSize = cellSize * kGridSize + kGridPadding * 2;
    size = Vector2(totalSize, totalSize);
  }

  // ── Rendering ─────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    // Draw grid background panel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        size.toRect(),
        const Radius.circular(12),
      ),
      _bgPaint,
    );

    // Draw individual cells
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        _drawCell(canvas, r, c);
      }
    }
  }

  /// Paints a single cell at grid position [r], [c].
  void _drawCell(Canvas canvas, int r, int c) {
    final cellRect = _cellRect(r, c);
    final rRect = RRect.fromRectAndRadius(cellRect, const Radius.circular(kCellRadius));

    final cellColor = _cells[r][c];
    if (cellColor != null) {
      // Filled cell — 3-layer shaded look
      _drawFilledCell(canvas, rRect, cellColor);
    } else {
      // Empty cell
      canvas.drawRRect(rRect, _emptyPaint);
    }

    // Draw highlight overlay on top
    final mode = _highlight[r][c];
    if (mode == HighlightMode.valid) {
      canvas.drawRRect(rRect, _validPaint);
    } else if (mode == HighlightMode.invalid) {
      canvas.drawRRect(rRect, _invalidPaint);
    }
  }

  /// Draws a filled cell with top-highlight and bottom-shadow for a 3-D feel.
  void _drawFilledCell(Canvas canvas, RRect rRect, Color color) {
    // Shadow (slightly offset downward rectangle)
    final shadowPaint = Paint()
      ..color = _darken(color, 0.25);
    canvas.drawRRect(rRect.shift(const Offset(0, 2)), shadowPaint);

    // Main face
    canvas.drawRRect(rRect, Paint()..color = color);

    // Highlight (top-left gleam)
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = _lighten(color, 0.25)
        ..blendMode = BlendMode.screen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Hit-testing helpers ───────────────────────────────────────

  /// Returns the [Rect] for the cell at grid position [r], [c].
  Rect _cellRect(int r, int c) {
    final x = kGridPadding + c * cellSize + kCellGap / 2;
    final y = kGridPadding + r * cellSize + kCellGap / 2;
    final w = cellSize - kCellGap;
    return Rect.fromLTWH(x, y, w, w);
  }

  /// Converts a canvas-space [localPos] (relative to this component's origin)
  /// to a grid [row, col] pair, or null if outside the grid.
  List<int>? localPosToCell(Vector2 localPos) {
    final x = localPos.x - kGridPadding;
    final y = localPos.y - kGridPadding;
    if (x < 0 || y < 0) return null;
    final col = (x / cellSize).floor();
    final row = (y / cellSize).floor();
    if (col < 0 || col >= kGridSize || row < 0 || row >= kGridSize) return null;
    return [row, col];
  }

  // ── Piece validation & placement ──────────────────────────────

  /// Returns true if [piece] can be placed at grid [row], [col] without
  /// going out of bounds or overlapping existing cells.
  bool canPlace(BlockShape shape, int row, int col) {
    for (final cell in shape.cells) {
      final r = row + cell[0];
      final c = col + cell[1];
      if (r < 0 || r >= kGridSize || c < 0 || c >= kGridSize) return false;
      if (_cells[r][c] != null) return false;
    }
    return true;
  }

  /// Places [shape] with [color] at grid [row], [col].
  /// Caller must verify [canPlace] returns true first.
  void place(BlockShape shape, Color color, int row, int col) {
    for (final cell in shape.cells) {
      _cells[row + cell[0]][col + cell[1]] = color;
    }
  }

  // ── Match detection & clearing ────────────────────────────────

  /// Scans the grid for runs of 3+ same-coloured cells in any row or column.
  /// Clears all matching cells and returns a record of the results.
  ClearResult clearMatches() {
    final toRemove = <String>{}; // "r,c" keys to avoid duplicates
    int linesFound = 0;

    // ── Check rows ──────────────────────────────────────────────
    for (int r = 0; r < kGridSize; r++) {
      int runStart = 0;
      Color? runColor = _cells[r][0];
      int runLen = 1;

      for (int c = 1; c < kGridSize; c++) {
        final cellColor = _cells[r][c];
        if (cellColor != null && cellColor == runColor) {
          runLen++;
        } else {
          if (runColor != null && runLen >= kMatchLength) {
            linesFound++;
            for (int k = runStart; k < runStart + runLen; k++) {
              toRemove.add('$r,$k');
            }
          }
          runStart = c;
          runColor = cellColor;
          runLen = 1;
        }
      }
      // Check the final run in this row
      if (runColor != null && runLen >= kMatchLength) {
        linesFound++;
        for (int k = runStart; k < runStart + runLen; k++) {
          toRemove.add('$r,$k');
        }
      }
    }

    // ── Check columns ───────────────────────────────────────────
    for (int c = 0; c < kGridSize; c++) {
      int runStart = 0;
      Color? runColor = _cells[0][c];
      int runLen = 1;

      for (int r = 1; r < kGridSize; r++) {
        final cellColor = _cells[r][c];
        if (cellColor != null && cellColor == runColor) {
          runLen++;
        } else {
          if (runColor != null && runLen >= kMatchLength) {
            linesFound++;
            for (int k = runStart; k < runStart + runLen; k++) {
              toRemove.add('$k,$c');
            }
          }
          runStart = r;
          runColor = cellColor;
          runLen = 1;
        }
      }
      // Check the final run in this column
      if (runColor != null && runLen >= kMatchLength) {
        linesFound++;
        for (int k = runStart; k < runStart + runLen; k++) {
          toRemove.add('$k,$c');
        }
      }
    }

    // ── Remove matched cells ─────────────────────────────────────
    int cleared = 0;
    for (final key in toRemove) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      _cells[r][c] = null;
      cleared++;
    }

    return ClearResult(clearedCells: cleared, linesCleared: linesFound);
  }

  // ── Grid-query helpers used for game-over detection ───────────

  /// Returns true if [shape] fits anywhere on the current grid state.
  bool shapeFitsAnywhere(BlockShape shape) {
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }

  /// Returns true if at least one of the given [shapes] fits on the grid.
  bool anyShapeFits(List<BlockShape?> shapes) {
    for (final shape in shapes) {
      if (shape != null && shapeFitsAnywhere(shape)) return true;
    }
    return false;
  }

  // ── Power-up effects ──────────────────────────────────────────

  /// Clears a 3×3 area centred on [centreRow], [centreCol].
  /// Returns the number of cells cleared.
  int applyBomb(int centreRow, int centreCol) {
    int cleared = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final r = centreRow + dr;
        final c = centreCol + dc;
        if (r >= 0 && r < kGridSize && c >= 0 && c < kGridSize) {
          if (_cells[r][c] != null) {
            _cells[r][c] = null;
            cleared++;
          }
        }
      }
    }
    return cleared;
  }

  /// Clears all cells in [row].  Returns the number of cells cleared.
  int applyRowClear(int row) {
    int cleared = 0;
    for (int c = 0; c < kGridSize; c++) {
      if (_cells[row][c] != null) {
        _cells[row][c] = null;
        cleared++;
      }
    }
    return cleared;
  }

  /// Removes all cells that match [color].  Returns the number of cells cleared.
  int applyColorClear(Color color) {
    int cleared = 0;
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        if (_cells[r][c] == color) {
          _cells[r][c] = null;
          cleared++;
        }
      }
    }
    return cleared;
  }

  // ── Highlight management ──────────────────────────────────────

  /// Sets the highlight overlay for all cells of [shape] at [row], [col].
  /// Pass [valid] = true for a green preview, false for red.
  void setHighlight(BlockShape shape, int row, int col, {required bool valid}) {
    clearHighlight();
    final mode = valid ? HighlightMode.valid : HighlightMode.invalid;
    for (final cell in shape.cells) {
      final r = row + cell[0];
      final c = col + cell[1];
      if (r >= 0 && r < kGridSize && c >= 0 && c < kGridSize) {
        _highlight[r][c] = mode;
      }
    }
  }

  /// Clears all cell highlights.
  void clearHighlight() {
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        _highlight[r][c] = HighlightMode.none;
      }
    }
  }

  /// Resets the entire grid to empty (used for new game).
  void reset() {
    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        _cells[r][c] = null;
        _highlight[r][c] = HighlightMode.none;
      }
    }
  }

  /// Returns the colour at [row], [col] or null if empty.
  Color? cellColor(int row, int col) => _cells[row][col];

  // ── Private colour utilities ─────────────────────────────────

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// ─────────────────────────────────────────────
//  CLEAR RESULT
// ─────────────────────────────────────────────

/// Value returned by [GridComponent.clearMatches()].
class ClearResult {
  /// Total number of individual cells cleared
  final int clearedCells;

  /// Number of distinct 3+ streaks (rows or columns) cleared
  final int linesCleared;

  const ClearResult({
    required this.clearedCells,
    required this.linesCleared,
  });

  bool get hadClear => clearedCells > 0;
}

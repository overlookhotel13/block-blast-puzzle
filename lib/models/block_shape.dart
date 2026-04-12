/// block_shape.dart
/// Defines every block shape available in the game.
/// A shape is described as a list of [row, col] cell offsets
/// from its top-left anchor point (0, 0).
/// Shapes are grouped by difficulty tier so the game can
/// restrict which shapes appear at lower levels.

import '../utils/constants.dart';

// ─────────────────────────────────────────────
//  SHAPE ID CONSTANTS
// ─────────────────────────────────────────────

const String kShapeSingle = 'single';
const String kShapeH2 = 'h2';
const String kShapeH3 = 'h3';
const String kShapeV2 = 'v2';
const String kShapeV3 = 'v3';
const String kShapeSquare = 'sq';
const String kShapeLRight = 'l_right';
const String kShapeLLeft = 'l_left';
const String kShapeJRight = 'j_right';
const String kShapeJLeft = 'j_left';
const String kShapeTDown = 't_down';
const String kShapeTUp = 't_up';
const String kShapeTLeft = 't_left';
const String kShapeTRight = 't_right';
const String kShapeSShape = 's_shape';
const String kShapeZShape = 'z_shape';
const String kShapeBigSq = 'big_sq';

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────

/// Represents a single block shape with its cell layout and level constraint.
class BlockShape {
  /// Unique identifier for this shape
  final String id;

  /// List of [row, col] offsets relative to anchor (0,0).
  /// (0,0) is always included and represents the top-left of the bounding box.
  final List<List<int>> cells;

  /// Minimum game level at which this shape may appear in the tray.
  final int minLevel;

  const BlockShape({
    required this.id,
    required this.cells,
    required this.minLevel,
  });

  /// Bounding box height (number of rows)
  int get rows {
    int max = 0;
    for (final c in cells) {
      if (c[0] > max) max = c[0];
    }
    return max + 1;
  }

  /// Bounding box width (number of columns)
  int get cols {
    int max = 0;
    for (final c in cells) {
      if (c[1] > max) max = c[1];
    }
    return max + 1;
  }

  /// Returns a new [BlockShape] shifted so the top-left of its bounding box
  /// is at [startRow], [startCol] on the grid.
  List<List<int>> cellsAt(int startRow, int startCol) {
    return cells.map((c) => [c[0] + startRow, c[1] + startCol]).toList();
  }

  @override
  String toString() => 'BlockShape($id, minLevel: $minLevel)';
}

// ─────────────────────────────────────────────
//  SHAPE LIBRARY
// ─────────────────────────────────────────────

/// Complete catalogue of all block shapes in the game.
/// They are ordered by rough complexity; minLevel controls which
/// levels they can appear at.
const List<BlockShape> kAllShapes = [
  // ── Tier 1: levels 1–5 (small / simple) ──────────────────────

  /// Single cell 1×1
  BlockShape(
    id: kShapeSingle,
    cells: [
      [0, 0]
    ],
    minLevel: 1,
  ),

  /// Two cells horizontal  ██
  BlockShape(
    id: kShapeH2,
    cells: [
      [0, 0],
      [0, 1]
    ],
    minLevel: 1,
  ),

  /// Two cells vertical
  /// █
  /// █
  BlockShape(
    id: kShapeV2,
    cells: [
      [0, 0],
      [1, 0]
    ],
    minLevel: 1,
  ),

  /// Three cells horizontal  ███
  BlockShape(
    id: kShapeH3,
    cells: [
      [0, 0],
      [0, 1],
      [0, 2]
    ],
    minLevel: 1,
  ),

  /// Three cells vertical
  /// █
  /// █
  /// █
  BlockShape(
    id: kShapeV3,
    cells: [
      [0, 0],
      [1, 0],
      [2, 0]
    ],
    minLevel: 1,
  ),

  // ── Tier 2: levels 6–15 (medium) ─────────────────────────────

  /// 2×2 square
  /// ██
  /// ██
  BlockShape(
    id: kShapeSquare,
    cells: [
      [0, 0],
      [0, 1],
      [1, 0],
      [1, 1]
    ],
    minLevel: kLevelMediumShapes,
  ),

  /// L-shape (right foot)
  /// █
  /// █
  /// ██
  BlockShape(
    id: kShapeLRight,
    cells: [
      [0, 0],
      [1, 0],
      [2, 0],
      [2, 1]
    ],
    minLevel: kLevelMediumShapes,
  ),

  /// L-shape (left foot)
  ///  █
  ///  █
  /// ██
  BlockShape(
    id: kShapeLLeft,
    cells: [
      [0, 1],
      [1, 1],
      [2, 0],
      [2, 1]
    ],
    minLevel: kLevelMediumShapes,
  ),

  /// J-shape (right)
  /// ██
  /// █
  /// █
  BlockShape(
    id: kShapeJRight,
    cells: [
      [0, 0],
      [0, 1],
      [1, 0],
      [2, 0]
    ],
    minLevel: kLevelMediumShapes,
  ),

  /// J-shape (left)
  /// ██
  ///  █
  ///  █
  BlockShape(
    id: kShapeJLeft,
    cells: [
      [0, 0],
      [0, 1],
      [1, 1],
      [2, 1]
    ],
    minLevel: kLevelMediumShapes,
  ),

  // ── Tier 3: levels 16–30 (complex) ───────────────────────────

  /// T-shape pointing down
  /// ███
  ///  █
  BlockShape(
    id: kShapeTDown,
    cells: [
      [0, 0],
      [0, 1],
      [0, 2],
      [1, 1]
    ],
    minLevel: kLevelComplexShapes,
  ),

  /// T-shape pointing up
  ///  █
  /// ███
  BlockShape(
    id: kShapeTUp,
    cells: [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, 2]
    ],
    minLevel: kLevelComplexShapes,
  ),

  /// T-shape pointing left
  /// █
  /// ██
  /// █
  BlockShape(
    id: kShapeTLeft,
    cells: [
      [0, 0],
      [1, 0],
      [1, 1],
      [2, 0]
    ],
    minLevel: kLevelComplexShapes,
  ),

  /// T-shape pointing right
  ///  █
  /// ██
  ///  █
  BlockShape(
    id: kShapeTRight,
    cells: [
      [0, 1],
      [1, 0],
      [1, 1],
      [2, 1]
    ],
    minLevel: kLevelComplexShapes,
  ),

  /// S-shape
  ///  ██
  /// ██
  BlockShape(
    id: kShapeSShape,
    cells: [
      [0, 1],
      [0, 2],
      [1, 0],
      [1, 1]
    ],
    minLevel: kLevelComplexShapes,
  ),

  /// Z-shape
  /// ██
  ///  ██
  BlockShape(
    id: kShapeZShape,
    cells: [
      [0, 0],
      [0, 1],
      [1, 1],
      [1, 2]
    ],
    minLevel: kLevelComplexShapes,
  ),

  // ── Tier 4: levels 31+ (all shapes) ──────────────────────────

  /// 3×3 big square (only at high levels)
  BlockShape(
    id: kShapeBigSq,
    cells: [
      [0, 0],
      [0, 1],
      [0, 2],
      [1, 0],
      [1, 1],
      [1, 2],
      [2, 0],
      [2, 1],
      [2, 2]
    ],
    minLevel: kLevelAllShapes,
  ),
];

/// Returns the subset of shapes available at [level].
List<BlockShape> shapesForLevel(int level) {
  return kAllShapes.where((s) => s.minLevel <= level).toList();
}

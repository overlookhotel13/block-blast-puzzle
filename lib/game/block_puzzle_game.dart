/// block_puzzle_game.dart
/// Main Flame game class.  Handles:
///   - Scene layout (grid + tray)
///   - Drag-and-drop from tray to grid with ghost preview
///   - Power-up tap interactions
///   - Communicating results (score, game-over) back to Flutter via GameState
///
/// The game fills the entire GameWidget area.  Flutter overlays (HUD, tray UI)
/// sit on top and are managed by [GameScreen].

import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSLColor;
import '../models/block_shape.dart';
import '../models/player_data.dart';
import '../utils/constants.dart';
import 'game_state.dart';
import 'grid.dart';
import 'block_piece.dart';

// ─────────────────────────────────────────────
//  MAIN GAME CLASS
// ─────────────────────────────────────────────

/// [BlockPuzzleGame] is the root Flame scene.
/// It contains [GridComponent] and coordinates drag-and-drop interactions.
class BlockPuzzleGame extends FlameGame with DragCallbacks {
  // ── External state ────────────────────────────────────────────

  /// Shared game state (also used by Flutter widgets via Provider)
  final GameState gameState;

  // ── Flame components ─────────────────────────────────────────

  late GridComponent _grid;

  // ── Layout ───────────────────────────────────────────────────

  /// Computed cell size based on available width
  late double _cellSize;

  /// Pixel position of the grid component's top-left corner
  late Vector2 _gridPosition;

  // ── Drag state ────────────────────────────────────────────────

  /// Index (0-2) of the tray piece currently being dragged, or null
  int? _draggedIndex;

  /// The shape + colour data of the dragged piece
  TrayPiece? _draggedPiece;

  /// Current drag canvas position (tracks the finger)
  Vector2 _dragPos = Vector2.zero();

  /// Renderer for the ghost piece following the finger
  DraggedPieceRenderer? _dragRenderer;

  /// Grid row/col that the ghost piece is snapped to, or null if outside grid
  List<int>? _snapCell; // [row, col]

  /// Whether the current snap position is a valid placement
  bool _snapValid = false;

  // ── Tray slot layout ─────────────────────────────────────────

  /// Canvas rects for the three tray slots (used for hit-testing)
  late List<Rect> _traySlotRects;

  // ── Background tint (shifts subtly per level tier) ────────────

  Color _bgColor = kColorBackground;

  // ── Constructor ───────────────────────────────────────────────

  BlockPuzzleGame({required this.gameState});

  // ── Flame lifecycle ───────────────────────────────────────────

  @override
  Color backgroundColor() => _bgColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _layout();
    _updateBgColor();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    // Recompute layout whenever the canvas size changes
    _layout();
  }

  // ── Layout calculation ────────────────────────────────────────

  /// Computes all size/position values from the current canvas dimensions.
  void _layout() {
    final w = size.x;
    final h = size.y;

    // Grid occupies roughly 65 % of screen height and up to full width
    final gridCanvasSize = min(w - 16, h * 0.60);
    _cellSize = (gridCanvasSize - kGridPadding * 2) / kGridSize;

    final gridPixelSize = _cellSize * kGridSize + kGridPadding * 2;
    final gridX = (w - gridPixelSize) / 2;
    // Leave 56px at top for HUD overlay and a small margin
    final gridY = 64.0;
    _gridPosition = Vector2(gridX, gridY);

    // Rebuild the grid component (remove old one if present)
    removeAll(children.whereType<GridComponent>().toList());
    _grid = GridComponent(cellSize: _cellSize)
      ..position = _gridPosition;
    add(_grid);

    // Compute tray slot rects
    _computeTrayRects();
  }

  /// Computes the three tray hit-test rects below the grid.
  void _computeTrayRects() {
    final gridBottom = _gridPosition.y + _grid.size.y;
    final trayTop = gridBottom + 20;
    final trayH = size.y - trayTop - 12;
    final trayCell = _cellSize * kTrayPieceScale;
    final slotW = size.x / 3;

    _traySlotRects = List.generate(kTraySize, (i) {
      return Rect.fromLTWH(i * slotW, trayTop, slotW, trayH);
    });
  }

  // ── Background colour ─────────────────────────────────────────

  /// Adjusts the background tint based on the current level tier.
  void _updateBgColor() {
    final level = gameState.level;
    if (level >= 41) {
      _bgColor = const Color(0xFF0D0D2E);
    } else if (level >= 31) {
      _bgColor = const Color(0xFF101030);
    } else if (level >= 21) {
      _bgColor = const Color(0xFF131335);
    } else if (level >= 11) {
      _bgColor = const Color(0xFF161638);
    } else {
      _bgColor = kColorBackground;
    }
  }

  // ── Rendering ─────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    super.render(canvas); // renders GridComponent etc.

    // Draw tray background panel
    _renderTrayBackground(canvas);

    // Draw tray pieces
    _renderTrayPieces(canvas);

    // Draw the dragged ghost piece on top of everything
    if (_dragRenderer != null && _draggedPiece != null) {
      // Offset the piece upward so the finger doesn't cover it
      final ghostY = _dragPos.y - kDragFingerYOffset;
      _dragRenderer!.render(canvas, _dragPos.x, ghostY);
    }
  }

  /// Draws the semi-transparent tray background.
  void _renderTrayBackground(Canvas canvas) {
    for (int i = 0; i < kTraySize; i++) {
      final rect = _traySlotRects[i].deflate(4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()..color = kColorSurface,
      );
    }
  }

  /// Draws each tray piece in its slot.
  void _renderTrayPieces(Canvas canvas) {
    final trayCell = _cellSize * kTrayPieceScale;

    for (int i = 0; i < kTraySize; i++) {
      final piece = gameState.tray[i];
      if (piece == null) continue; // Empty slot

      // If this piece is being dragged, draw it dimmed in its slot
      final alpha = (i == _draggedIndex) ? 0.3 : 1.0;

      final slotRect = _traySlotRects[i];

      // Centre the piece inside its slot
      final pieceW = piece.shape.cols * trayCell;
      final pieceH = piece.shape.rows * trayCell;
      final originX = slotRect.left + (slotRect.width - pieceW) / 2;
      final originY = slotRect.top + (slotRect.height - pieceH) / 2;

      canvas.save();
      canvas.translate(originX, originY);

      final paint = Paint()
        ..color = piece.color.withOpacity(alpha);
      final shadowPaint = Paint()
        ..color = _darkenColor(piece.color, 0.25).withOpacity(alpha);

      for (final cell in piece.shape.cells) {
        final x = cell[1] * trayCell;
        final y = cell[0] * trayCell;
        final rect = Rect.fromLTWH(
          x + kCellGap / 2,
          y + kCellGap / 2,
          trayCell - kCellGap,
          trayCell - kCellGap,
        );
        final rRect =
            RRect.fromRectAndRadius(rect, const Radius.circular(kCellRadius));
        canvas.drawRRect(rRect.shift(const Offset(0, 2)), shadowPaint);
        canvas.drawRRect(rRect, paint);
      }

      canvas.restore();
    }
  }

  // ── Drag handling ─────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final pos = event.canvasPosition;

    // Find which tray slot was touched
    for (int i = 0; i < kTraySize; i++) {
      if (_traySlotRects[i].contains(Offset(pos.x, pos.y))) {
        final piece = gameState.tray[i];
        if (piece == null) return; // Slot is empty

        _draggedIndex = i;
        _draggedPiece = piece;
        _dragPos = pos.clone();

        // Create the ghost renderer at full cell size
        _dragRenderer = DraggedPieceRenderer(
          shape: piece.shape,
          color: piece.color,
          cellSize: _cellSize,
        );
        return;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_draggedPiece == null) return;

    _dragPos.add(event.delta);

    // Convert to grid cell (offset upward from finger)
    final ghostY = _dragPos.y - kDragFingerYOffset;
    final localPos = Vector2(_dragPos.x - _gridPosition.x, ghostY - _gridPosition.y);
    final cell = _grid.localPosToCell(localPos);

    if (cell != null) {
      // Check validity for snapping preview
      final row = cell[0];
      final col = cell[1];
      // Anchor piece so its centre is close to the cell the finger points at
      final anchorRow = (row - _draggedPiece!.shape.rows ~/ 2).clamp(0, kGridSize - 1);
      final anchorCol = (col - _draggedPiece!.shape.cols ~/ 2).clamp(0, kGridSize - 1);
      _snapCell = [anchorRow, anchorCol];
      _snapValid = _grid.canPlace(_draggedPiece!.shape, anchorRow, anchorCol);
      _grid.setHighlight(
        _draggedPiece!.shape,
        anchorRow,
        anchorCol,
        valid: _snapValid,
      );
    } else {
      _snapCell = null;
      _snapValid = false;
      _grid.clearHighlight();
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (_draggedPiece == null) return;

    final snap = _snapCell;
    if (snap != null && _snapValid) {
      // ── Valid placement ─────────────────────────────────────
      _grid.place(_draggedPiece!.shape, _draggedPiece!.color, snap[0], snap[1]);
      _grid.clearHighlight();

      // Consume the tray slot
      gameState.consumeTrayPiece(_draggedIndex!);

      // Detect and clear matches
      final result = _grid.clearMatches();
      if (result.hadClear) {
        gameState.addClearScore(
          clearedCells: result.clearedCells,
          linesCleared: result.linesCleared,
        );
      } else {
        gameState.onPiecePlaced();
      }

      // Update background colour in case level changed
      _updateBgColor();

      // Check for game over
      _checkGameOver();
    } else {
      // ── Invalid placement — piece returns to tray ───────────
      _grid.clearHighlight();
    }

    // Reset drag state
    _draggedIndex = null;
    _draggedPiece = null;
    _dragRenderer = null;
    _snapCell = null;
    _snapValid = false;
  }

  // ── Power-up handling ─────────────────────────────────────────

  /// Called when the user taps the grid while a power-up is active.
  /// Returns true if the tap was handled as a power-up action.
  bool handlePowerUpTap(Vector2 tapCanvasPos) {
    final activePowerUp = gameState.activePowerUp;
    if (activePowerUp == null) return false;

    final localPos = Vector2(
      tapCanvasPos.x - _gridPosition.x,
      tapCanvasPos.y - _gridPosition.y,
    );
    final cell = _grid.localPosToCell(localPos);
    if (cell == null) return false;

    int cleared = 0;
    switch (activePowerUp) {
      case PowerUpType.bomb:
        cleared = _grid.applyBomb(cell[0], cell[1]);
        break;
      case PowerUpType.rowClear:
        cleared = _grid.applyRowClear(cell[0]);
        break;
      case PowerUpType.colorClear:
        final color = _grid.cellColor(cell[0], cell[1]);
        if (color != null) cleared = _grid.applyColorClear(color);
        break;
    }

    if (cleared > 0) {
      gameState.spendCoinsForPowerUp(activePowerUp);
      gameState.addClearScore(clearedCells: cleared, linesCleared: 0);
      _checkGameOver();
    }

    return true;
  }

  // ── Game over detection ───────────────────────────────────────

  /// Checks if any of the current tray pieces can still be placed.
  /// Triggers game-over if none can.
  void _checkGameOver() {
    final shapes = gameState.tray.map((p) => p?.shape).toList();
    if (!_grid.anyShapeFits(shapes)) {
      gameState.triggerGameOver();
    }
  }

  // ── New game ──────────────────────────────────────────────────

  /// Resets the grid for a fresh game. Called by [GameScreen].
  void resetGame() {
    _grid.reset();
    _updateBgColor();
  }

  // ── Colour utility ────────────────────────────────────────────

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

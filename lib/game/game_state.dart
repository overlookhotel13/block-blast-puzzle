/// game_state.dart
/// Central ChangeNotifier that bridges the Flame game world with
/// Flutter widgets.  Holds the live session data (score, level, tray pieces,
/// power-up selection, game-over flag) and exposes mutation methods that
/// Flame can call via callbacks.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import '../models/block_shape.dart';
import '../models/player_data.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

// ─────────────────────────────────────────────
//  TRAY PIECE
// ─────────────────────────────────────────────

/// A single coloured piece in the bottom tray.
class TrayPiece {
  final BlockShape shape;
  final Color color;
  final int colorIndex;

  const TrayPiece({
    required this.shape,
    required this.color,
    required this.colorIndex,
  });
}

// ─────────────────────────────────────────────
//  GAME STATE
// ─────────────────────────────────────────────

/// Manages all live game session state and notifies listeners on changes.
class GameState extends ChangeNotifier {
  // ── Dependencies ────────────────────────────────────────────

  final StorageService _storage = StorageService.instance;
  final AudioService _audio = AudioService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final Random _rng = Random();

  // ── Session data ─────────────────────────────────────────────

  /// Score accumulated in the current game session
  int _sessionScore = 0;

  /// All-time high score (from storage)
  int _highScore = 0;

  /// Current level (1–50)
  int _level = 1;

  /// Coin balance
  int _coins = 0;

  /// The three tray slots; null means "slot is empty"
  final List<TrayPiece?> _tray = [null, null, null];

  /// True when the game-over condition has been triggered
  bool _isGameOver = false;

  /// True if the player has used their free continue this session
  bool _usedContinueThisSession = false;

  /// Consecutive clear-chain for combo multiplier
  int _comboCount = 0;

  /// Currently active power-up type (set when user taps a power-up button)
  PowerUpType? _activePowerUp;

  // ── Getters ──────────────────────────────────────────────────

  int get sessionScore => _sessionScore;
  int get highScore => _highScore;
  int get level => _level;
  int get coins => _coins;
  List<TrayPiece?> get tray => List.unmodifiable(_tray);
  bool get isGameOver => _isGameOver;
  bool get usedContinueThisSession => _usedContinueThisSession;
  int get comboCount => _comboCount;
  PowerUpType? get activePowerUp => _activePowerUp;

  /// True if all three tray slots are empty (time to refill).
  bool get allTrayPiecesUsed => _tray.every((p) => p == null);

  // ── Initialisation ────────────────────────────────────────────

  /// Sets up a fresh game session using persisted player data.
  Future<void> startNewGame() async {
    final data = _storage.loadPlayerData();
    _highScore = data.highScore;
    _level = data.currentLevel;
    _coins = data.coins;
    _sessionScore = 0;
    _isGameOver = false;
    _usedContinueThisSession = false;
    _comboCount = 0;
    _activePowerUp = null;

    // Fill the tray with 3 random pieces
    _refillTray();
    notifyListeners();

    await _analytics.logGameStart(level: _level);
  }

  // ── Tray management ──────────────────────────────────────────

  /// Replaces all three tray slots with newly generated pieces.
  void _refillTray() {
    for (int i = 0; i < kTraySize; i++) {
      _tray[i] = _generateRandomPiece();
    }
  }

  /// Generates one random [TrayPiece] appropriate for the current level.
  TrayPiece _generateRandomPiece() {
    final available = shapesForLevel(_level);
    final shape = available[_rng.nextInt(available.length)];
    final ci = _rng.nextInt(kBlockColors.length);
    return TrayPiece(
      shape: shape,
      color: kBlockColors[ci],
      colorIndex: ci,
    );
  }

  /// Marks slot [index] as used (sets it to null).
  /// Call this after the Flame game successfully places the piece on the grid.
  /// Automatically refills all three slots when all are used.
  void consumeTrayPiece(int index) {
    assert(index >= 0 && index < kTraySize);
    _tray[index] = null;

    // Refill when all three slots are empty
    if (allTrayPiecesUsed) {
      _refillTray();
    }
    notifyListeners();
  }

  // ── Scoring ───────────────────────────────────────────────────

  /// Called by the Flame grid after clearing cells.
  /// [clearedCells] is the total number of cells removed.
  /// [linesCleared] is how many distinct 3+ streaks were cleared.
  void addClearScore({
    required int clearedCells,
    required int linesCleared,
  }) {
    if (clearedCells == 0) {
      // No clear this turn — reset combo
      _comboCount = 0;
      return;
    }

    // Increment combo counter
    _comboCount++;

    // Calculate score with multiplier
    final multiplier = comboMultiplier(_comboCount - 1);
    final cellScore = (clearedCells * kPointsPerCell * multiplier).round();
    final lineBonus = linesCleared * kPointsPerLine;
    final gained = cellScore + lineBonus;

    _sessionScore += gained;

    // Update high score if beaten
    if (_sessionScore > _highScore) {
      _highScore = _sessionScore;
    }

    // Check for level up
    final newLevel = levelFromScore(_sessionScore);
    if (newLevel > _level) {
      _level = newLevel.clamp(1, kMaxLevel);
      _analytics.logLevelUp(_level);
    }

    // Play sounds
    if (_comboCount >= 2) {
      _audio.playCombo();
    } else {
      _audio.playClearLine();
    }

    notifyListeners();
  }

  /// Called after placing a piece (no clear happened this turn).
  void onPiecePlaced() {
    _comboCount = 0; // reset combo since no clear occurred
    _audio.playPlaceBlock();
    _saveProgress();
    notifyListeners();
  }

  // ── Power-ups ─────────────────────────────────────────────────

  /// Sets the active power-up (highlights which button is selected).
  /// Pass null to deselect.
  void selectPowerUp(PowerUpType? type) {
    _activePowerUp = type;
    notifyListeners();
  }

  /// Returns true if the player can afford [type] with coins.
  bool canAffordPowerUp(PowerUpType type) => _coins >= type.coinCost;

  /// Returns true if [type] is unlocked at the current level.
  bool isPowerUpUnlocked(PowerUpType type) => _level >= type.unlockLevel;

  /// Deducts the coin cost for [type] after it has been used.
  /// Called by the Flame game after successful power-up application.
  void spendCoinsForPowerUp(PowerUpType type) {
    _coins = max(0, _coins - type.coinCost);
    _activePowerUp = null;
    _audio.playPowerup();
    _saveProgress();
    notifyListeners();
  }

  /// Grants a power-up for free (used after watching a rewarded ad).
  void activatePowerUpFree(PowerUpType type) {
    _activePowerUp = type;
    _audio.playPowerup();
    notifyListeners();
  }

  // ── Coins ─────────────────────────────────────────────────────

  /// Adds [amount] coins to the player's balance.
  void addCoins(int amount) {
    _coins += amount;
    _saveProgress();
    notifyListeners();
  }

  // ── Game Over / Continue ──────────────────────────────────────

  /// Triggers the game-over state.
  Future<void> triggerGameOver() async {
    _isGameOver = true;
    _audio.playGameOver();
    await _saveProgress();
    await _analytics.logGameOver(
      score: _sessionScore,
      level: _level,
      usedContinue: _usedContinueThisSession,
    );
    notifyListeners();
  }

  /// Continues the current game after watching a rewarded ad.
  /// Resets game-over state and resets the tray.
  void continueAfterAd() {
    _isGameOver = false;
    _usedContinueThisSession = true;
    _comboCount = 0;
    _refillTray();
    notifyListeners();
  }

  /// Whether the "watch ad to continue" option is available this session.
  bool get canUseAdContinue => !_usedContinueThisSession;

  // ── Persistence ───────────────────────────────────────────────

  Future<void> _saveProgress() async {
    try {
      await _storage.saveHighScore(_highScore);
      await _storage.saveCurrentLevel(_level);
      await _storage.saveCoins(_coins);
    } catch (e) {
      print('[GameState] _saveProgress error: $e');
    }
  }
}

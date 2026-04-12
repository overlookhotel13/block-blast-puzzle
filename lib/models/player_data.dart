/// player_data.dart
/// Immutable value object representing a snapshot of the player's
/// persistent data: score, level, coins, and unlocks.
/// Backed by StorageService; never modified in-place — use copyWith.

import '../utils/constants.dart';
import '../utils/helpers.dart';

// ─────────────────────────────────────────────
//  POWER-UP TYPE
// ─────────────────────────────────────────────

/// Identifies a power-up by its role in the game.
enum PowerUpType {
  /// Clears a 3×3 area centred on the tapped cell
  bomb,

  /// Clears an entire selected row
  rowClear,

  /// Removes all cells of one selected colour
  colorClear,
}

/// Maps each [PowerUpType] to its human-readable display name.
extension PowerUpTypeExt on PowerUpType {
  String get displayName {
    switch (this) {
      case PowerUpType.bomb:
        return 'Bomb';
      case PowerUpType.rowClear:
        return 'Row Clear';
      case PowerUpType.colorClear:
        return 'Color Clear';
    }
  }

  /// Coin cost to activate this power-up.
  int get coinCost {
    switch (this) {
      case PowerUpType.bomb:
        return kBombCost;
      case PowerUpType.rowClear:
        return kRowClearCost;
      case PowerUpType.colorClear:
        return kColorClearCost;
    }
  }

  /// Level at which this power-up unlocks.
  int get unlockLevel {
    switch (this) {
      case PowerUpType.bomb:
        return kLevelUnlockBomb;
      case PowerUpType.rowClear:
        return kLevelUnlockRowClear;
      case PowerUpType.colorClear:
        return kLevelUnlockColorClear;
    }
  }

  /// Asset icon name (without extension) for the power-up.
  String get iconAsset {
    switch (this) {
      case PowerUpType.bomb:
        return 'assets/images/powerup_bomb.png';
      case PowerUpType.rowClear:
        return 'assets/images/powerup_row.png';
      case PowerUpType.colorClear:
        return 'assets/images/powerup_color.png';
    }
  }
}

// ─────────────────────────────────────────────
//  PLAYER DATA MODEL
// ─────────────────────────────────────────────

/// Complete snapshot of all data associated with a player.
class PlayerData {
  /// All-time highest score achieved
  final int highScore;

  /// Cumulative score across all sessions (lifetime)
  final int totalScore;

  /// Current game level (derived from totalScore but persisted separately)
  final int currentLevel;

  /// Current coin balance
  final int coins;

  /// Set of power-up types the player has permanently unlocked.
  /// Note: power-ups unlock by level, so this reflects which have been seen/used.
  final Set<PowerUpType> unlockedPowerUps;

  /// Whether the player has purchased the Remove Ads IAP.
  // TODO: Wire up in_app_purchase plugin when implementing real IAP
  final bool hasRemovedAds;

  const PlayerData({
    this.highScore = 0,
    this.totalScore = 0,
    this.currentLevel = 1,
    this.coins = 0,
    this.unlockedPowerUps = const {},
    this.hasRemovedAds = false,
  });

  /// Level derived from [totalScore] using the scoring formula.
  int get derivedLevel => levelFromScore(totalScore);

  /// Progress towards the next level [0.0 – 1.0].
  double get levelProgress => levelProgress(totalScore);

  /// Returns a copy of this [PlayerData] with the given fields replaced.
  PlayerData copyWith({
    int? highScore,
    int? totalScore,
    int? currentLevel,
    int? coins,
    Set<PowerUpType>? unlockedPowerUps,
    bool? hasRemovedAds,
  }) {
    return PlayerData(
      highScore: highScore ?? this.highScore,
      totalScore: totalScore ?? this.totalScore,
      currentLevel: currentLevel ?? this.currentLevel,
      coins: coins ?? this.coins,
      unlockedPowerUps: unlockedPowerUps ?? this.unlockedPowerUps,
      hasRemovedAds: hasRemovedAds ?? this.hasRemovedAds,
    );
  }

  @override
  String toString() =>
      'PlayerData(highScore: $highScore, level: $currentLevel, coins: $coins)';
}

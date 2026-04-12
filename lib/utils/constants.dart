/// constants.dart
/// Central repository for all game constants, colors, sizes,
/// timing values, and configuration strings.
/// No magic numbers or hardcoded strings elsewhere in the codebase.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  BRANDING & PALETTE
// ─────────────────────────────────────────────

/// Application name shown in UI
const String kAppName = 'Block Blast';

/// Deep navy background used across all screens
const Color kColorBackground = Color(0xFF1A1A2E);

/// Slightly lighter surface for cards / panels
const Color kColorSurface = Color(0xFF16213E);

/// Accent colour for buttons and highlights
const Color kColorAccent = Color(0xFF0F3460);

/// Primary text colour
const Color kColorTextPrimary = Colors.white;

/// Secondary / muted text colour
const Color kColorTextSecondary = Color(0xFFB0BEC5);

/// Grid line colour
const Color kColorGridLine = Color(0xFF2A2A4A);

/// Empty cell background
const Color kColorCellEmpty = Color(0xFF0D0D1A);

/// Valid drop-zone highlight (semi-transparent green)
const Color kColorHighlightValid = Color(0x6043A047);

/// Invalid drop-zone highlight (semi-transparent red)
const Color kColorHighlightInvalid = Color(0x60E53935);

// ─────────────────────────────────────────────
//  BLOCK PIECE COLOURS  (5 colours)
// ─────────────────────────────────────────────

/// Five distinct block colours used for pieces
const List<Color> kBlockColors = [
  Color(0xFFE53935), // Red
  Color(0xFF1E88E5), // Blue
  Color(0xFF43A047), // Green
  Color(0xFFFDD835), // Yellow
  Color(0xFF8E24AA), // Purple
];

/// Slightly lighter shade for block face highlight
const List<Color> kBlockHighlightColors = [
  Color(0xFFEF5350),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFFFEE58),
  Color(0xFFAB47BC),
];

/// Darker shade for block shadow / bottom edge
const List<Color> kBlockShadowColors = [
  Color(0xFFC62828),
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFF9A825),
  Color(0xFF6A1B9A),
];

// ─────────────────────────────────────────────
//  GRID CONFIGURATION
// ─────────────────────────────────────────────

/// Number of rows and columns in the puzzle grid
const int kGridSize = 9;

/// Minimum run length required for a match-clear
const int kMatchLength = 3;

/// Padding around the grid (each side, in logical pixels)
const double kGridPadding = 8.0;

/// Corner radius for individual cells
const double kCellRadius = 4.0;

/// Gap between cells (inner border)
const double kCellGap = 2.0;

// ─────────────────────────────────────────────
//  TRAY CONFIGURATION
// ─────────────────────────────────────────────

/// Number of pieces visible in the bottom tray
const int kTraySize = 3;

/// Scale factor for tray pieces relative to grid cells
const double kTrayPieceScale = 0.65;

/// Vertical finger-offset so the dragged piece clears the thumb
const double kDragFingerYOffset = 90.0;

// ─────────────────────────────────────────────
//  SCORING
// ─────────────────────────────────────────────

/// Points per cleared cell
const int kPointsPerCell = 10;

/// Bonus points per cleared line (row or column streak)
const int kPointsPerLine = 50;

/// Combo multipliers indexed by combo count (0-based).
/// combo 0 → 1.0×, combo 1 → 1.5×, combo 2 → 2.0×, combo 3+ → 2.5×
const List<double> kComboMultipliers = [1.0, 1.5, 2.0, 2.5];

/// Points needed per level
const int kPointsPerLevel = 500;

/// Maximum level
const int kMaxLevel = 50;

// ─────────────────────────────────────────────
//  POWER-UP COSTS (in coins)
// ─────────────────────────────────────────────

/// Coin cost to use Bomb power-up (or watch ad)
const int kBombCost = 2;

/// Coin cost to use Row Clear power-up (or watch ad)
const int kRowClearCost = 2;

/// Coin cost to use Color Clear power-up (or watch ad)
const int kColorClearCost = 3;

// ─────────────────────────────────────────────
//  LEVEL UNLOCK THRESHOLDS
// ─────────────────────────────────────────────

/// Level at which Bomb power-up unlocks
const int kLevelUnlockBomb = 1;

/// Level at which Row Clear power-up unlocks
const int kLevelUnlockRowClear = 5;

/// Level at which Color Clear power-up unlocks
const int kLevelUnlockColorClear = 10;

/// Level at which medium shapes (L, 2×2) are introduced
const int kLevelMediumShapes = 6;

/// Level at which complex shapes (T, S, Z) are introduced
const int kLevelComplexShapes = 16;

/// Level at which all shapes are available
const int kLevelAllShapes = 31;

// ─────────────────────────────────────────────
//  DAILY REWARD
// ─────────────────────────────────────────────

/// Coin rewards for each streak day (index = day-1, 0..6)
const List<int> kDailyRewardCoins = [5, 8, 10, 15, 20, 25, 50];

/// Day 7 grants a free random power-up in addition to coins
const int kDailyRewardSpecialDay = 7;

// ─────────────────────────────────────────────
//  ANIMATION DURATIONS
// ─────────────────────────────────────────────

/// Duration of the block-placement snap animation
const Duration kSnapAnimDuration = Duration(milliseconds: 120);

/// Duration of the clear-line flash animation
const Duration kClearAnimDuration = Duration(milliseconds: 300);

/// Duration of the bounce-back animation when a placement is invalid
const Duration kBounceAnimDuration = Duration(milliseconds: 250);

/// Duration of the game-over overlay entrance animation
const Duration kGameOverAnimDuration = Duration(milliseconds: 600);

// ─────────────────────────────────────────────
//  SHARED PREFERENCES KEYS
// ─────────────────────────────────────────────

const String kPrefHighScore = 'high_score';
const String kPrefTotalScore = 'total_score';
const String kPrefCurrentLevel = 'current_level';
const String kPrefCoins = 'coins';
const String kPrefUnlockedPowerups = 'unlocked_powerups';
const String kPrefLastDailyReward = 'last_daily_reward_date';
const String kPrefDailyStreak = 'daily_streak';
const String kPrefHasRemovedAds = 'has_removed_ads';
const String kPrefMusicEnabled = 'music_enabled';
const String kPrefSfxEnabled = 'sfx_enabled';

// ─────────────────────────────────────────────
//  AD UNIT IDs  (test IDs — replace before release)
// ─────────────────────────────────────────────

// TODO: Replace with your real AdMob App ID in AndroidManifest.xml before release
const String kAdMobAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';

// TODO: Replace testRewardedAdUnitId with your real unit ID before release
const String kRewardedAdUnitIdAndroid =
    'ca-app-pub-3940256099942544/5224354917';

// ─────────────────────────────────────────────
//  MISC
// ─────────────────────────────────────────────

/// Number of free "watch-ad-to-continue" continues allowed per session
const int kMaxContinuesPerSession = 1;

/// Duration key for background music audio asset
const String kAudioMusic = 'audio/bg_music.mp3';

/// SFX asset keys
const String kSfxPlaceBlock = 'audio/place_block.mp3';
const String kSfxClearLine = 'audio/clear_line.mp3';
const String kSfxGameOver = 'audio/game_over.mp3';
const String kSfxPowerup = 'audio/powerup.mp3';
const String kSfxCombo = 'audio/combo.mp3';

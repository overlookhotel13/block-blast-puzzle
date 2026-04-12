/// helpers.dart
/// Utility functions used throughout the codebase.
/// Includes math helpers, colour utilities, and formatting functions.

import 'package:flutter/material.dart';
import 'constants.dart';

// ─────────────────────────────────────────────
//  SCORE / LEVEL HELPERS
// ─────────────────────────────────────────────

/// Returns the current level (1-based) for a given total score.
int levelFromScore(int score) {
  final level = (score ~/ kPointsPerLevel) + 1;
  return level.clamp(1, kMaxLevel);
}

/// Returns the progress [0.0 – 1.0] within the current level.
double levelProgress(int score) {
  final pointsIntoLevel = score % kPointsPerLevel;
  return pointsIntoLevel / kPointsPerLevel;
}

/// Returns the combo multiplier for a given combo count (0-based).
double comboMultiplier(int combo) {
  if (combo >= kComboMultipliers.length) return kComboMultipliers.last;
  return kComboMultipliers[combo];
}

/// Formats an integer score with comma separators. e.g. 12345 → "12,345"
String formatScore(int score) {
  final str = score.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

// ─────────────────────────────────────────────
//  COLOUR HELPERS
// ─────────────────────────────────────────────

/// Returns the index (0-4) of [color] within [kBlockColors], or -1 if not found.
int colorIndex(Color color) => kBlockColors.indexOf(color);

/// Returns a darkened version of [color] by [amount] (0.0 – 1.0).
Color darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness(
    (hsl.lightness - amount).clamp(0.0, 1.0),
  );
  return darkened.toColor();
}

/// Returns a lightened version of [color] by [amount] (0.0 – 1.0).
Color lighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightened = hsl.withLightness(
    (hsl.lightness + amount).clamp(0.0, 1.0),
  );
  return lightened.toColor();
}

// ─────────────────────────────────────────────
//  DATE HELPERS
// ─────────────────────────────────────────────

/// Returns today's date as a formatted string "YYYY-MM-DD".
String todayDateString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Parses a date string "YYYY-MM-DD" back to a [DateTime] at midnight.
DateTime parseDateString(String dateStr) {
  final parts = dateStr.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Returns true if [dateStr] represents a date before today (i.e. yesterday or earlier).
bool isDateBeforeToday(String dateStr) {
  final date = parseDateString(dateStr);
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  return date.isBefore(todayMidnight);
}

/// Returns true if [dateStr] was exactly yesterday.
bool isYesterday(String dateStr) {
  final date = parseDateString(dateStr);
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;
}

/// Returns true if [dateStr] is today.
bool isToday(String dateStr) {
  final today = DateTime.now();
  final date = parseDateString(dateStr);
  return date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
}

// ─────────────────────────────────────────────
//  LAYOUT HELPERS
// ─────────────────────────────────────────────

/// Computes the cell pixel size so the 9×9 grid fits within [availableWidth]
/// while leaving room for [kGridPadding] on each side.
double computeCellSize(double availableWidth) {
  return (availableWidth - kGridPadding * 2) / kGridSize;
}

/// Clamps [value] between [min] and [max].
double clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

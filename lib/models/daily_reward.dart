/// daily_reward.dart
/// Data model and business logic for the 7-day daily reward streak system.
/// The StorageService persists the raw values; this model interprets them.

import '../utils/constants.dart';
import '../utils/helpers.dart';

// ─────────────────────────────────────────────
//  DAILY REWARD STATE
// ─────────────────────────────────────────────

/// Describes the current state of the daily reward system.
class DailyRewardState {
  /// How many consecutive days the player has claimed (1–7, wraps back to 1)
  final int currentStreak;

  /// The ISO date string (YYYY-MM-DD) of the last successful claim, or empty.
  final String lastClaimDate;

  const DailyRewardState({
    required this.currentStreak,
    required this.lastClaimDate,
  });

  // ── Derived properties ──────────────────────────────────────

  /// True if the player has not yet claimed today's reward.
  bool get canClaimToday {
    if (lastClaimDate.isEmpty) return true; // Never claimed
    if (isToday(lastClaimDate)) return false; // Already claimed today
    return true;
  }

  /// True if the current streak is still alive (player claimed yesterday or this is
  /// their first time).  If they missed a day the streak would have been reset to 0.
  bool get streakAlive {
    if (lastClaimDate.isEmpty) return true;
    return isToday(lastClaimDate) || isYesterday(lastClaimDate);
  }

  /// The 1-based day number to display to the user (1–7).
  /// If the streak is broken, shows day 1 (a fresh start).
  int get displayDay {
    if (!streakAlive) return 1;
    // After day 7 wrap back to day 1 for a new cycle
    return ((currentStreak - 1) % 7) + 1;
  }

  /// The coin reward for today's claimable day.
  int get todayCoins => kDailyRewardCoins[displayDay - 1];

  /// True if today is the 7th streak day (grants special power-up bonus).
  bool get isBonusDay => displayDay == kDailyRewardSpecialDay;

  /// Returns a copy with updated fields after a successful claim.
  DailyRewardState afterClaim() {
    final newStreak = streakAlive ? currentStreak + 1 : 1;
    return DailyRewardState(
      currentStreak: newStreak,
      lastClaimDate: todayDateString(),
    );
  }

  /// Returns a copy with the streak reset (called if the user missed a day
  /// and we detect the gap on the next app launch).
  DailyRewardState withBrokenStreak() {
    return const DailyRewardState(currentStreak: 0, lastClaimDate: '');
  }

  @override
  String toString() =>
      'DailyRewardState(streak: $currentStreak, lastClaim: $lastClaimDate)';
}

// ─────────────────────────────────────────────
//  REWARD ENTRY (for UI display)
// ─────────────────────────────────────────────

/// A single day entry used by the 7-day calendar UI widget.
class DailyRewardEntry {
  /// Day number within the 7-day cycle (1–7)
  final int day;

  /// Coins awarded on this day
  final int coins;

  /// Whether this day also grants a special power-up
  final bool isSpecial;

  /// Whether this day has already been claimed in the current cycle
  final bool claimed;

  /// Whether this is today's claimable day
  final bool isToday;

  const DailyRewardEntry({
    required this.day,
    required this.coins,
    required this.isSpecial,
    required this.claimed,
    required this.isToday,
  });
}

/// Builds the list of [DailyRewardEntry] items for the calendar UI
/// based on the current [DailyRewardState].
List<DailyRewardEntry> buildCalendarEntries(DailyRewardState state) {
  final todayDay = state.displayDay;
  // Number of days already claimed in the current cycle
  final claimedCount = state.lastClaimDate.isEmpty
      ? 0
      : (isToday(state.lastClaimDate) ? todayDay : todayDay - 1);

  return List.generate(7, (i) {
    final day = i + 1;
    return DailyRewardEntry(
      day: day,
      coins: kDailyRewardCoins[i],
      isSpecial: day == kDailyRewardSpecialDay,
      claimed: day < todayDay && state.streakAlive,
      isToday: day == todayDay && state.canClaimToday,
    );
  });
}

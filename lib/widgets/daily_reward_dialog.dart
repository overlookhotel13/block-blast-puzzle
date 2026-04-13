/// daily_reward_dialog.dart
/// Full-screen-style dialog presenting the 7-day streak calendar.
/// Shows which days have been claimed, today's reward, and the claim button.
/// Reads/writes via StorageService; grants coins via GameState (if present).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/daily_reward.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';

/// Dialog that shows the 7-day daily reward calendar.
/// Pass [onCoinsGranted] to be notified of the coin amount awarded.
class DailyRewardDialog extends StatefulWidget {
  final void Function(int coins, bool isSpecialDay)? onCoinsGranted;

  const DailyRewardDialog({super.key, this.onCoinsGranted});

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late DailyRewardState _rewardState;
  late List<DailyRewardEntry> _entries;
  bool _claimed = false;

  late AnimationController _claimController;
  late Animation<double> _claimScale;

  @override
  void initState() {
    super.initState();
    _loadState();

    // Scale-up animation for the claim button
    _claimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _claimScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _claimController, curve: Curves.easeOut),
    );
  }

  void _loadState() {
    final storage = StorageService.instance;
    _rewardState = DailyRewardState(
      currentStreak: storage.getDailyStreak(),
      lastClaimDate: storage.getLastDailyRewardDate(),
    );

    // If streak is broken (missed more than one day), reset it
    if (!_rewardState.streakAlive && _rewardState.lastClaimDate.isNotEmpty) {
      _rewardState = _rewardState.withBrokenStreak();
      storage.saveDailyStreak(0);
      storage.saveLastDailyRewardDate('');
    }

    _entries = buildCalendarEntries(_rewardState);
  }

  @override
  void dispose() {
    _claimController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (!_rewardState.canClaimToday || _claimed) return;

    // Animate the button
    await _claimController.forward();
    await _claimController.reverse();

    // Update state
    final newState = _rewardState.afterClaim();
    final coinsEarned = _rewardState.todayCoins;
    final isSpecial = _rewardState.isBonusDay;

    // Persist
    final storage = StorageService.instance;
    await storage.saveDailyStreak(newState.currentStreak);
    await storage.saveLastDailyRewardDate(newState.lastClaimDate);

    // Notify caller (grants coins to GameState / player data)
    widget.onCoinsGranted?.call(coinsEarned, isSpecial);

    // Analytics
    await AnalyticsService.instance.logDailyRewardClaimed(
      day: _rewardState.displayDay,
      coinsEarned: coinsEarned,
    );

    if (mounted) {
      setState(() {
        _rewardState = newState;
        _entries = buildCalendarEntries(newState);
        _claimed = true;
      });

      // Close after a short delay
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = _rewardState.canClaimToday && !_claimed;

    return Dialog(
      backgroundColor: kColorSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title ───────────────────────────────────────────
            Text(
              'Daily Reward',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kColorTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Day ${_rewardState.displayDay} of 7',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: kColorTextSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // ── 7-day calendar grid ──────────────────────────────
            _CalendarGrid(entries: _entries),
            const SizedBox(height: 20),

            // ── Claim button ─────────────────────────────────────
            if (_claimed)
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    '+${_rewardState.todayCoins} coins!',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                ],
              )
            else
              ScaleTransition(
                scale: _claimScale,
                child: ElevatedButton(
                  onPressed: canClaim ? _claimReward : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canClaim ? Colors.amber : kColorGridLine,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    canClaim
                        ? 'Claim ${_rewardState.todayCoins} Coins 🪙'
                        : 'Come back tomorrow!',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CALENDAR GRID
// ─────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final List<DailyRewardEntry> entries;

  const _CalendarGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: entries.map((e) => _DayTile(entry: e)).toList(),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DailyRewardEntry entry;

  const _DayTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Widget badge;

    if (entry.claimed) {
      bg = Colors.green.withValues(alpha: 0.2);
      textColor = Colors.green;
      badge = const Icon(Icons.check, color: Colors.green, size: 14);
    } else if (entry.isToday) {
      bg = Colors.amber.withValues(alpha: 0.25);
      textColor = Colors.amber;
      badge = const Icon(Icons.star, color: Colors.amber, size: 14);
    } else {
      bg = kColorAccent.withValues(alpha: 0.3);
      textColor = kColorTextSecondary;
      badge = const SizedBox.shrink();
    }

    return Container(
      width: 38,
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.isToday ? Colors.amber : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'D${entry.day}',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          badge,
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.coins}',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: textColor,
                ),
              ),
              const Text('🪙', style: TextStyle(fontSize: 8)),
            ],
          ),
          if (entry.isSpecial)
            const Text('✨', style: TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}

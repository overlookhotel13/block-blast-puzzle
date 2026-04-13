/// power_up_bar.dart
/// Horizontal row of power-up buttons shown above the piece tray.
/// Each button shows the power-up icon, coin cost, and lock status.
/// Tapping a button either activates the power-up (if coins available)
/// or shows the rewarded-ad dialog (if not enough coins).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../game/game_state.dart';
import '../models/player_data.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import 'ad_reward_dialog.dart';

/// Displays the three power-up buttons (Bomb, Row Clear, Color Clear).
class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: PowerUpType.values.map((type) {
              return _PowerUpButton(
                type: type,
                isUnlocked: state.isPowerUpUnlocked(type),
                isActive: state.activePowerUp == type,
                canAfford: state.canAffordPowerUp(type),
                coins: state.coins,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  SINGLE BUTTON
// ─────────────────────────────────────────────

class _PowerUpButton extends StatelessWidget {
  final PowerUpType type;
  final bool isUnlocked;
  final bool isActive;
  final bool canAfford;
  final int coins;

  const _PowerUpButton({
    required this.type,
    required this.isUnlocked,
    required this.isActive,
    required this.canAfford,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    // Colour the button ring when active
    final borderColor = isActive
        ? Colors.yellowAccent
        : (isUnlocked ? kColorAccent : kColorGridLine);

    return GestureDetector(
      onTap: isUnlocked ? () => _onTap(context) : null,
      child: AnimatedContainer(
        duration: kSnapAnimDuration,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.yellowAccent.withValues(alpha: 0.15)
              : kColorSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isActive ? 2.5 : 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon (emoji as placeholder; swap with Image.asset for real icons)
            Text(
              _iconEmoji,
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(height: 2),
            // Coin cost or lock indicator
            if (isUnlocked)
              _CostLabel(cost: type.coinCost, canAfford: canAfford)
            else
              _LockLabel(unlockLevel: type.unlockLevel),
          ],
        ),
      ),
    );
  }

  String get _iconEmoji {
    switch (type) {
      case PowerUpType.bomb:
        return '💣';
      case PowerUpType.rowClear:
        return '⚡';
      case PowerUpType.colorClear:
        return '🎨';
    }
  }

  void _onTap(BuildContext context) {
    final state = context.read<GameState>();

    if (state.activePowerUp == type) {
      // Toggle off if already selected
      state.selectPowerUp(null);
      return;
    }

    if (state.canAffordPowerUp(type)) {
      // Activate immediately with coins
      state.selectPowerUp(type);
    } else {
      // Not enough coins — offer to watch an ad
      _showAdDialog(context, type);
    }
  }

  void _showAdDialog(BuildContext context, PowerUpType type) {
    showDialog(
      context: context,
      builder: (_) => AdRewardDialog(
        title: 'Get ${type.displayName}',
        message: 'Watch a short ad to use the ${type.displayName} for free!',
        onRewardGranted: () {
          final state = context.read<GameState>();
          state.activatePowerUpFree(type);
          AnalyticsService.instance.logAdWatched(placement: 'powerup_${type.name}');
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER WIDGETS
// ─────────────────────────────────────────────

class _CostLabel extends StatelessWidget {
  final int cost;
  final bool canAfford;

  const _CostLabel({required this.cost, required this.canAfford});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🪙', style: TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(
          '$cost',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: canAfford ? Colors.amber : kColorTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _LockLabel extends StatelessWidget {
  final int unlockLevel;

  const _LockLabel({required this.unlockLevel});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Lv$unlockLevel 🔒',
      style: GoogleFonts.nunito(
        fontSize: 10,
        color: kColorTextSecondary,
      ),
    );
  }
}

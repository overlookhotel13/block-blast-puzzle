/// level_display.dart
/// Widget showing the player's current level and XP progress bar.
/// Displayed in the top-left of the game HUD.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Compact level indicator with animated XP bar.
class LevelDisplay extends StatelessWidget {
  /// Current level number (1–50)
  final int level;

  /// Current session score (used to compute progress within the level)
  final int score;

  const LevelDisplay({
    super.key,
    required this.level,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final progress = levelProgress(score);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level label
        Text(
          'LVL $level',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kColorTextPrimary,
          ),
        ),

        const SizedBox(height: 4),

        // XP progress bar
        SizedBox(
          width: 72,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: kColorGridLine,
              valueColor: AlwaysStoppedAnimation<Color>(
                kBlockColors[level % kBlockColors.length],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

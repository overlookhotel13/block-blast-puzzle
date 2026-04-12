/// home_screen.dart
/// Main menu screen.  Shows the game logo, high score, Play button,
/// settings icon, and a daily-reward button with a red-dot badge
/// when there is an unclaimed reward.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/daily_reward_dialog.dart';

/// Home / main-menu screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  bool _hasDailyReward = false;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();

    // Subtle pulse on the Play button
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _loadData();
    // Start background music when arriving at home screen
    AudioService.instance.playMusic();
  }

  void _loadData() {
    final storage = StorageService.instance;
    final lastClaim = storage.getLastDailyRewardDate();
    setState(() {
      _highScore = storage.getHighScore();
      // Badge is shown if: never claimed, or last claim was not today
      _hasDailyReward = lastClaim.isEmpty || !isToday(lastClaim);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).pushNamed('/settings').then((_) => _loadData());
  }

  void _openDailyReward() {
    showDialog(
      context: context,
      builder: (_) => DailyRewardDialog(
        onCoinsGranted: (coins, isSpecial) {
          // Add coins to storage directly (no active game session here)
          final storage = StorageService.instance;
          final current = storage.getCoins();
          storage.saveCoins(current + coins);
          _loadData(); // refresh badge
        },
      ),
    ).then((_) => _loadData());
  }

  void _startGame() {
    Navigator.of(context).pushNamed('/game').then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Settings icon (top-right) ───────────────────────
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings, color: kColorTextSecondary, size: 28),
                onPressed: _openSettings,
              ),
            ),

            // ── Daily reward button (top-left) ──────────────────
            Positioned(
              top: 12,
              left: 16,
              child: _DailyRewardButton(
                hasBadge: _hasDailyReward,
                onTap: _openDailyReward,
              ),
            ),

            // ── Main content ────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _LogoWidget(),

                  const SizedBox(height: 32),

                  // High score
                  Text(
                    'BEST SCORE',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kColorTextSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatScore(_highScore),
                    style: GoogleFonts.nunito(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Play button (pulsing)
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: _PlayButton(onTap: _startGame),
                  ),

                  const SizedBox(height: 24),

                  // Version tag
                  Text(
                    'v1.0.0',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: kColorTextSecondary.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: kBlockColors.take(3).toList(),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: kBlockColors[1].withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text('🧩', style: TextStyle(fontSize: 52)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          kAppName,
          style: GoogleFonts.nunito(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: kColorTextPrimary,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          'PUZZLE',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kColorTextSecondary,
            letterSpacing: 8,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBlockColors[1], kBlockColors[4]],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: kBlockColors[1].withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'PLAY',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyRewardButton extends StatelessWidget {
  final bool hasBadge;
  final VoidCallback onTap;

  const _DailyRewardButton({required this.hasBadge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Text('🎁', style: TextStyle(fontSize: 26)),
          onPressed: onTap,
          tooltip: 'Daily Reward',
        ),
        if (hasBadge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

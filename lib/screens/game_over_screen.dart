/// game_over_screen.dart
/// Animated game-over screen showing final score, best score,
/// a "Watch Ad to Continue" button (once per session), and a New Game button.
/// Receives its arguments from GameScreen via pushReplacementNamed.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/game_state.dart';
import '../game/block_puzzle_game.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/ad_reward_dialog.dart';

/// Game-over results and action screen.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _titleSlide;
  late Animation<double> _cardFade;
  late Animation<double> _buttonsFade;

  // Extracted from route arguments
  late int _score;
  late int _highScore;
  late int _level;
  late bool _canContinue;
  GameState? _gameState;
  BlockPuzzleGame? _game;

  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();

    // ── Entrance animation ─────────────────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: kGameOverAnimDuration,
    );

    _titleSlide = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _cardFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    );
    _buttonsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    // Delay slightly for drama
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract route arguments passed by GameScreen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _score = args['score'] as int? ?? 0;
      _highScore = args['highScore'] as int? ?? 0;
      _level = args['level'] as int? ?? 1;
      _canContinue = args['canContinue'] as bool? ?? false;
      _gameState = args['gameState'] as GameState?;
      _game = args['game'] as BlockPuzzleGame?;
      _isNewHighScore = _score >= _highScore && _score > 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────

  /// Watches a rewarded ad and continues the current game.
  void _watchAdToContinue() {
    if (_gameState == null || _game == null) return;

    showDialog(
      context: context,
      builder: (_) => AdRewardDialog(
        title: 'Continue Playing?',
        message: 'Watch a short ad to keep your score and continue!',
        onRewardGranted: () {
          // Restore the game
          _gameState!.continueAfterAd();
          AnalyticsService.instance
              .logAdWatched(placement: 'game_over_continue');
          // Navigate back to game screen with same state
          Navigator.of(context).pushReplacementNamed('/game');
        },
      ),
    );
  }

  /// Starts a completely new game.
  void _newGame() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/game', (route) => route.isFirst);
  }

  /// Returns to the home screen.
  void _goHome() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // TODO: Implement share functionality using the share_plus package
  // Add share_plus: ^7.x.x to pubspec.yaml and uncomment:
  // import 'package:share_plus/share_plus.dart';
  void _shareScore() {
    // Share.share('I scored ${formatScore(_score)} in $kAppName! Can you beat me?');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share coming soon!',
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: kColorAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── "Game Over" title ──────────────────────────────
                AnimatedBuilder(
                  animation: _titleSlide,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'GAME OVER',
                        style: GoogleFonts.nunito(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: kColorTextPrimary,
                          letterSpacing: 3,
                        ),
                      ),
                      if (_isNewHighScore) ...[
                        const SizedBox(height: 4),
                        Text(
                          '🏆 NEW HIGH SCORE! 🏆',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Score card ─────────────────────────────────────
                FadeTransition(
                  opacity: _cardFade,
                  child: _ScoreCard(
                    score: _score,
                    highScore: _highScore,
                    level: _level,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Action buttons ─────────────────────────────────
                FadeTransition(
                  opacity: _buttonsFade,
                  child: Column(
                    children: [
                      // Watch Ad to Continue (only shown once per session)
                      if (_canContinue && AdService.instance.isRewardedAdReady)
                        _ActionButton(
                          label: 'Watch Ad to Continue',
                          icon: Icons.videocam,
                          color: Colors.amber,
                          textColor: Colors.black,
                          onTap: _watchAdToContinue,
                        ),

                      const SizedBox(height: 12),

                      // New Game
                      _ActionButton(
                        label: 'New Game',
                        icon: Icons.refresh,
                        color: kBlockColors[1],
                        textColor: Colors.white,
                        onTap: _newGame,
                      ),

                      const SizedBox(height: 12),

                      // Share score
                      _ActionButton(
                        label: 'Share Score',
                        icon: Icons.share,
                        color: kColorSurface,
                        textColor: kColorTextPrimary,
                        onTap: _shareScore,
                      ),

                      const SizedBox(height: 12),

                      // Home
                      TextButton(
                        onPressed: _goHome,
                        child: Text(
                          'Main Menu',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: kColorTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  final int highScore;
  final int level;

  const _ScoreCard({
    required this.score,
    required this.highScore,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
      decoration: BoxDecoration(
        color: kColorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kColorGridLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _ScoreRow(label: 'SCORE', value: formatScore(score), large: true),
          const Divider(color: kColorGridLine, height: 24),
          _ScoreRow(label: 'BEST', value: formatScore(highScore)),
          const SizedBox(height: 8),
          _ScoreRow(label: 'LEVEL REACHED', value: '$level'),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool large;

  const _ScoreRow({
    required this.label,
    required this.value,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kColorTextSecondary,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: large ? 30 : 20,
            fontWeight: FontWeight.w800,
            color: large ? Colors.amber : kColorTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// game_screen.dart
/// Main gameplay screen.  Hosts the Flame GameWidget in the centre
/// with a Flutter HUD overlay on top (score, level, coins) and a
/// power-up bar below.  Navigates to GameOverScreen when game ends.

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../game/block_puzzle_game.dart';
import '../game/game_state.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/score_display.dart';
import '../widgets/level_display.dart';
import '../widgets/power_up_bar.dart';

/// Full-screen gameplay view.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameState _gameState;
  late BlockPuzzleGame _game;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Create a fresh game state and Flame game instance
    _gameState = GameState();
    _game = BlockPuzzleGame(gameState: _gameState);

    // Attach listener before startNewGame so we don't miss any synchronous
    // state change (startNewGame is async but triggers notifyListeners).
    _gameState.addListener(_onGameStateChanged);

    // Start a new session asynchronously
    _gameState.startNewGame();
  }

  void _onGameStateChanged() {
    if (_gameState.isGameOver && mounted) {
      // Navigate to game-over screen, passing the final state
      Navigator.of(context).pushReplacementNamed(
        '/game_over',
        arguments: {
          'score': _gameState.sessionScore,
          'highScore': _gameState.highScore,
          'level': _gameState.level,
          'canContinue': _gameState.canUseAdContinue,
          'gameState': _gameState,
          'game': _game,
        },
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _game.pauseEngine();
    } else if (state == AppLifecycleState.resumed) {
      if (!_paused) _game.resumeEngine();
    }
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
        AudioService.instance.pauseMusic();
      } else {
        _game.resumeEngine();
        AudioService.instance.resumeMusic();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameState.removeListener(_onGameStateChanged);
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameState,
      child: Scaffold(
        backgroundColor: kColorBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top HUD ─────────────────────────────────────────
              _TopHud(onPause: _togglePause, paused: _paused),

              // ── Flame game area ──────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // The Flame scene (grid + tray rendering)
                    GameWidget<BlockPuzzleGame>(game: _game),

                    // Pause overlay
                    if (_paused) _PauseOverlay(onResume: _togglePause),
                  ],
                ),
              ),

              // ── Power-up bar ─────────────────────────────────────
              const PowerUpBar(),

              // Small bottom padding for gesture area
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TOP HUD
// ─────────────────────────────────────────────

class _TopHud extends StatelessWidget {
  final VoidCallback onPause;
  final bool paused;

  const _TopHud({required this.onPause, required this.paused});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, __) {
        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: kColorSurface,
            border: Border(
              bottom: BorderSide(color: kColorGridLine, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level (left)
              LevelDisplay(level: state.level, score: state.sessionScore),

              // Score (centre)
              ScoreDisplay(
                score: state.sessionScore,
                highScore: state.highScore,
              ),

              // Coins + pause (right)
              Row(
                children: [
                  _CoinsDisplay(coins: state.coins),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      paused ? Icons.play_arrow : Icons.pause,
                      color: kColorTextSecondary,
                    ),
                    onPressed: onPause,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinsDisplay extends StatelessWidget {
  final int coins;

  const _CoinsDisplay({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🪙', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          formatScore(coins),
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PAUSE OVERLAY
// ─────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const _PauseOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlockColors[1],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              ),
              child: Text(
                'Quit to Menu',
                style: GoogleFonts.nunito(color: kColorTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

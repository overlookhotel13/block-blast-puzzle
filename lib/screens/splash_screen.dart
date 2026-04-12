/// splash_screen.dart
/// Animated splash screen shown on first app launch.
/// Initialises all services while the logo animates in, then navigates
/// to the home screen once everything is ready.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';

/// App entry-point screen that handles async initialisation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // ── Logo entrance animation ─────────────────────────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Initialise services in parallel with the animation
    _initialise();
  }

  Future<void> _initialise() async {
    try {
      // All initialisations run concurrently
      await Future.wait([
        StorageService.instance.init(),
        AudioService.instance.init(),
        AdService.instance.init(),
      ]);
    } catch (e) {
      print('[SplashScreen] Service init error: $e');
      // Non-fatal — proceed to home screen regardless
    }

    // Wait for animation to finish before navigating (min 1.2 s total)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      body: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo icon ─────────────────────────────────────
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: kBlockColors.take(3).toList(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: kBlockColors[1].withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🧩', style: TextStyle(fontSize: 56)),
                  ),
                ),

                const SizedBox(height: 24),

                // ── App name ──────────────────────────────────────
                Text(
                  kAppName,
                  style: GoogleFonts.nunito(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: kColorTextPrimary,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Puzzle',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kColorTextSecondary,
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Loading indicator ─────────────────────────────
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kBlockColors[1]),
                    strokeWidth: 3,
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

/// app.dart
/// Root MaterialApp configuration: theme, routes, and font setup.
/// All named routes are declared here so screens never import each other.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

/// The root [MaterialApp] for Block Blast Puzzle.
class BlockBlastApp extends StatelessWidget {
  const BlockBlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kColorBackground,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF8E24AA),
          surface: kColorSurface,
          onSurface: kColorTextPrimary,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          ThemeData.dark().textTheme,
        ),
        // Use Nunito globally via Google Fonts
        fontFamily: GoogleFonts.nunito().fontFamily,
        useMaterial3: true,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),

      // ── Named routes ─────────────────────────────────────────
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/game': (_) => const GameScreen(),
        '/game_over': (_) => const GameOverScreen(),
        '/settings': (_) => const SettingsScreen(),
      },

      // ── Page transitions ─────────────────────────────────────
      onGenerateRoute: (settings) {
        // Fallback for unknown routes — navigate to home
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      },
    );
  }
}

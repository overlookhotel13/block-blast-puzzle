/// main.dart
/// Application entry point.
/// Ensures Flutter bindings are initialised and launches the app.
/// Heavy initialisation (storage, audio, ads) is deferred to SplashScreen
/// so the first frame renders immediately.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

Future<void> main() async {
  // Required before any async work or plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the app to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make the status bar transparent so our dark background shows through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BlockBlastApp());
}
